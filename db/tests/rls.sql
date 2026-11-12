-- RLS and privilege checks for the Axo-Team schema.
-- Run the whole file as one query (Supabase SQL editor or the connector).
-- All test data is created inside a nested block and rolled back; only the result rows are returned.

create temp table axo_rls_results (name text, expected text, actual text) on commit drop;

create function pg_temp.axo_claims(p_uid uuid) returns void language plpgsql as $fn$
begin
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config(
    'request.jwt.claims',
    case
      when p_uid is null then '{"role":"anon"}'
      else json_build_object('sub', p_uid, 'role', 'authenticated')::text
    end,
    true
  );
end;
$fn$;

-- Number of rows the role can see, or 'error <sqlstate>'.
create function pg_temp.axo_count(p_role text, p_uid uuid, p_sql text) returns text language plpgsql as $fn$
declare
  v bigint;
begin
  perform pg_temp.axo_claims(p_uid);
  execute format('set local role %I', p_role);
  begin
    execute format('select count(*) from (%s) q', p_sql) into v;
    execute 'reset role';
    return v::text;
  exception when others then
    execute 'reset role';
    return 'error ' || sqlstate;
  end;
end;
$fn$;

-- 'ok <affected rows>' or 'error <sqlstate>'.
create function pg_temp.axo_exec(p_role text, p_uid uuid, p_sql text) returns text language plpgsql as $fn$
declare
  v bigint;
begin
  perform pg_temp.axo_claims(p_uid);
  execute format('set local role %I', p_role);
  begin
    execute p_sql;
    get diagnostics v = row_count;
    execute 'reset role';
    return 'ok ' || v;
  exception when others then
    execute 'reset role';
    return 'error ' || sqlstate;
  end;
end;
$fn$;

create function pg_temp.axo_add(r jsonb, p_name text, p_expected text, p_actual text) returns jsonb language sql as $fn$
  select r || jsonb_build_array(jsonb_build_object('name', p_name, 'expected', p_expected, 'actual', p_actual));
$fn$;

do $test$
declare
  a uuid := gen_random_uuid();  -- regular user
  b uuid := gen_random_uuid();  -- another regular user
  c uuid := gen_random_uuid();  -- admin
  p_pub uuid;
  p_hid uuid;
  cm uuid;
  bg uuid;
  n_pub bigint;
  i integer;
  r jsonb := '[]';
begin
  begin
    -- ---------- setup (as postgres) ----------
    insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
    values
      (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'rls-a@test.invalid', '{"display_name":"  Test   A  "}', now(), now()),
      (b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'rls-b@test.invalid', '{}', now(), now()),
      (c, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'rls-c@test.invalid', '{"display_name":"Admin C"}', now(), now());
    update public.users set role = 'admin' where id = c;

    insert into public.projects (slug, title, summary, kind) values ('rls-public', 'Public', '', 'test') returning id into p_pub;
    insert into public.projects (slug, title, summary, kind, is_published) values ('rls-hidden', 'Hidden', '', 'test', false) returning id into p_hid;
    insert into public.docs (project_id, slug, title, body_md) values (p_hid, 'overview', 'x', 'x');
    select count(*) into n_pub from public.projects where is_published;

    -- ---------- users: signup trigger ----------
    r := pg_temp.axo_add(r, 'trigger: profile row per new account', '3', (select count(*)::text from public.users where id in (a, b, c)));
    r := pg_temp.axo_add(r, 'trigger: display name is trimmed and collapsed', 'Test A', (select display_name from public.users where id = a));
    r := pg_temp.axo_add(r, 'trigger: empty name gets a 12-char default', '12', (select char_length(display_name)::text from public.users where id = b));
    r := pg_temp.axo_add(r, 'trigger: role is always user', 'user', (select role from public.users where id = a));

    -- ---------- is_admin ----------
    r := pg_temp.axo_add(r, 'is_admin: anon', '0', pg_temp.axo_count('anon', null, 'select 1 where public.is_admin()'));
    r := pg_temp.axo_add(r, 'is_admin: user', '0', pg_temp.axo_count('authenticated', a, 'select 1 where public.is_admin()'));
    r := pg_temp.axo_add(r, 'is_admin: admin', '1', pg_temp.axo_count('authenticated', c, 'select 1 where public.is_admin()'));

    -- ---------- projects / docs ----------
    r := pg_temp.axo_add(r, 'projects: anon sees published only', n_pub::text, pg_temp.axo_count('anon', null, 'select 1 from public.projects'));
    r := pg_temp.axo_add(r, 'projects: user sees published only', n_pub::text, pg_temp.axo_count('authenticated', a, 'select 1 from public.projects'));
    r := pg_temp.axo_add(r, 'projects: admin sees unpublished too', (n_pub + 1)::text, pg_temp.axo_count('authenticated', c, 'select 1 from public.projects'));
    r := pg_temp.axo_add(r, 'docs: anon cannot read docs of unpublished project', '0', pg_temp.axo_count('anon', null, format('select 1 from public.docs where project_id = %L', p_hid)));
    r := pg_temp.axo_add(r, 'docs: admin reads docs of unpublished project', '1', pg_temp.axo_count('authenticated', c, format('select 1 from public.docs where project_id = %L', p_hid)));
    r := pg_temp.axo_add(r, 'projects: anon cannot insert', 'error 42501', pg_temp.axo_exec('anon', null, $q$insert into public.projects (slug, title, summary, kind) values ('rls-x1', 'x', '', 'x')$q$));
    r := pg_temp.axo_add(r, 'projects: user cannot insert', 'error 42501', pg_temp.axo_exec('authenticated', a, $q$insert into public.projects (slug, title, summary, kind) values ('rls-x2', 'x', '', 'x')$q$));
    r := pg_temp.axo_add(r, 'projects: admin can insert', 'ok 1', pg_temp.axo_exec('authenticated', c, $q$insert into public.projects (slug, title, summary, kind) values ('rls-x3', 'x', '', 'x')$q$));
    r := pg_temp.axo_add(r, 'projects: user update affects nothing', 'ok 0', pg_temp.axo_exec('authenticated', a, format('update public.projects set title = %L where id = %L', 'hacked', p_pub)));
    r := pg_temp.axo_add(r, 'projects: user delete affects nothing', 'ok 0', pg_temp.axo_exec('authenticated', a, format('delete from public.projects where id = %L', p_pub)));
    r := pg_temp.axo_add(r, 'links: user cannot insert', 'error 42501', pg_temp.axo_exec('authenticated', a, format('insert into public.links (project_id, label, url) values (%L, %L, %L)', p_pub, 'x', 'https://example.com')));

    -- ---------- comments ----------
    r := pg_temp.axo_add(r, 'comments: anon cannot insert', 'error 42501', pg_temp.axo_exec('anon', null, format('insert into public.comments (project_id, body) values (%L, %L)', p_pub, 'anon')));
    r := pg_temp.axo_add(r, 'comments: user can insert', 'ok 1', pg_temp.axo_exec('authenticated', a, format('insert into public.comments (project_id, body) values (%L, %L)', p_pub, 'rls test 1')));
    select id into cm from public.comments where project_id = p_pub and body = 'rls test 1';
    r := pg_temp.axo_add(r, 'comments: author is taken from the session', a::text, (select author_id::text from public.comments where id = cm));
    r := pg_temp.axo_add(r, 'comments: cannot forge author_id', 'error 42501', pg_temp.axo_exec('authenticated', a, format('insert into public.comments (project_id, body, author_id) values (%L, %L, %L)', p_pub, 'forged', b)));
    r := pg_temp.axo_add(r, 'comments: cannot set is_hidden on insert', 'error 42501', pg_temp.axo_exec('authenticated', a, format('insert into public.comments (project_id, body, is_hidden) values (%L, %L, true)', p_pub, 'hidden')));
    r := pg_temp.axo_add(r, 'comments: cannot comment on unpublished project', 'error 42501', pg_temp.axo_exec('authenticated', a, format('insert into public.comments (project_id, body) values (%L, %L)', p_hid, 'x')));
    r := pg_temp.axo_add(r, 'comments: empty body rejected', 'error 23514', pg_temp.axo_exec('authenticated', a, format('insert into public.comments (project_id, body) values (%L, %L)', p_pub, '   ')));
    r := pg_temp.axo_add(r, 'comments: other user cannot hide', 'ok 0', pg_temp.axo_exec('authenticated', b, format('update public.comments set is_hidden = true where id = %L', cm)));
    r := pg_temp.axo_add(r, 'comments: nobody can edit body', 'error 42501', pg_temp.axo_exec('authenticated', a, format('update public.comments set body = %L where id = %L', 'edited', cm)));
    r := pg_temp.axo_add(r, 'comments: admin can hide', 'ok 1', pg_temp.axo_exec('authenticated', c, format('update public.comments set is_hidden = true where id = %L', cm)));
    r := pg_temp.axo_add(r, 'comments: hidden is invisible to anon', '0', pg_temp.axo_count('anon', null, format('select 1 from public.comments where id = %L', cm)));
    r := pg_temp.axo_add(r, 'comments: hidden is invisible to other user', '0', pg_temp.axo_count('authenticated', b, format('select 1 from public.comments where id = %L', cm)));
    r := pg_temp.axo_add(r, 'comments: hidden is visible to its author', '1', pg_temp.axo_count('authenticated', a, format('select 1 from public.comments where id = %L', cm)));
    r := pg_temp.axo_add(r, 'comments: hidden is visible to admin', '1', pg_temp.axo_count('authenticated', c, format('select 1 from public.comments where id = %L', cm)));
    r := pg_temp.axo_add(r, 'comments: other user cannot delete', 'ok 0', pg_temp.axo_exec('authenticated', b, format('delete from public.comments where id = %L', cm)));
    r := pg_temp.axo_add(r, 'comments: author can delete own', 'ok 1', pg_temp.axo_exec('authenticated', a, format('delete from public.comments where id = %L', cm)));
    for i in 1..5 loop
      r := pg_temp.axo_add(r, 'comments: rate limit allows comment ' || i || ' of 5', 'ok 1', pg_temp.axo_exec('authenticated', a, format('insert into public.comments (project_id, body) values (%L, %L)', p_pub, 'flood ' || i)));
    end loop;
    r := pg_temp.axo_add(r, 'comments: rate limit blocks the 6th within a minute', 'error P0001', pg_temp.axo_exec('authenticated', a, format('insert into public.comments (project_id, body) values (%L, %L)', p_pub, 'flood 6')));

    -- ---------- users ----------
    r := pg_temp.axo_add(r, 'users: anon can read profiles', '3', pg_temp.axo_count('anon', null, format('select 1 from public.users where id in (%L, %L, %L)', a, b, c)));
    r := pg_temp.axo_add(r, 'users: can rename self', 'ok 1', pg_temp.axo_exec('authenticated', a, format('update public.users set display_name = %L where id = %L', 'Renamed', a)));
    r := pg_temp.axo_add(r, 'users: cannot rename others', 'ok 0', pg_temp.axo_exec('authenticated', a, format('update public.users set display_name = %L where id = %L', 'Hacked', b)));
    r := pg_temp.axo_add(r, 'users: cannot change own role', 'error 42501', pg_temp.axo_exec('authenticated', a, format('update public.users set role = %L where id = %L', 'admin', a)));
    r := pg_temp.axo_add(r, 'users: cannot insert a profile', 'error 42501', pg_temp.axo_exec('authenticated', a, format('insert into public.users (id, display_name) values (%L, %L)', gen_random_uuid(), 'Ghost')));
    r := pg_temp.axo_add(r, 'users: cannot delete a profile', 'error 42501', pg_temp.axo_exec('authenticated', a, format('delete from public.users where id = %L', a)));

    -- ---------- bugs ----------
    r := pg_temp.axo_add(r, 'bugs: anon cannot insert', 'error 42501', pg_temp.axo_exec('anon', null, $q$insert into public.bugs (title, body) values ('anon bug title', 'anon bug body text')$q$));
    r := pg_temp.axo_add(r, 'bugs: user can insert without project', 'ok 1', pg_temp.axo_exec('authenticated', a, $q$insert into public.bugs (title, body) values ('rls bug one', 'rls bug body text')$q$));
    select id into bg from public.bugs where title = 'rls bug one';
    r := pg_temp.axo_add(r, 'bugs: new report starts as new', 'new', (select status from public.bugs where id = bg));
    r := pg_temp.axo_add(r, 'bugs: cannot set status on insert', 'error 42501', pg_temp.axo_exec('authenticated', a, $q$insert into public.bugs (title, body, status) values ('rls bug two', 'rls bug body text', 'fixed')$q$));
    r := pg_temp.axo_add(r, 'bugs: cannot report against unpublished project', 'error 42501', pg_temp.axo_exec('authenticated', a, format('insert into public.bugs (project_id, title, body) values (%L, %L, %L)', p_hid, 'rls bug hidden', 'rls bug body text')));
    r := pg_temp.axo_add(r, 'bugs: user cannot change status', 'ok 0', pg_temp.axo_exec('authenticated', b, format('update public.bugs set status = %L where id = %L', 'fixed', bg)));
    r := pg_temp.axo_add(r, 'bugs: author cannot change status', 'ok 0', pg_temp.axo_exec('authenticated', a, format('update public.bugs set status = %L where id = %L', 'fixed', bg)));
    r := pg_temp.axo_add(r, 'bugs: admin can change status', 'ok 1', pg_temp.axo_exec('authenticated', c, format('update public.bugs set status = %L where id = %L', 'confirmed', bg)));
    r := pg_temp.axo_add(r, 'bugs: author cannot delete once taken into work', 'ok 0', pg_temp.axo_exec('authenticated', a, format('delete from public.bugs where id = %L', bg)));
    r := pg_temp.axo_add(r, 'bugs: admin can hide', 'ok 1', pg_temp.axo_exec('authenticated', c, format('update public.bugs set is_hidden = true where id = %L', bg)));
    r := pg_temp.axo_add(r, 'bugs: hidden is invisible to anon', '0', pg_temp.axo_count('anon', null, format('select 1 from public.bugs where id = %L', bg)));
    r := pg_temp.axo_add(r, 'bugs: hidden is visible to its author', '1', pg_temp.axo_count('authenticated', a, format('select 1 from public.bugs where id = %L', bg)));
    r := pg_temp.axo_add(r, 'bugs: user can insert for a project', 'ok 1', pg_temp.axo_exec('authenticated', a, format('insert into public.bugs (project_id, title, body) values (%L, %L, %L)', p_pub, 'rls bug three', 'rls bug body text')));
    r := pg_temp.axo_add(r, 'bugs: other user cannot delete', 'ok 0', pg_temp.axo_exec('authenticated', b, $q$delete from public.bugs where title = 'rls bug three'$q$));
    r := pg_temp.axo_add(r, 'bugs: author can withdraw a new report', 'ok 1', pg_temp.axo_exec('authenticated', a, $q$delete from public.bugs where title = 'rls bug three'$q$));
    r := pg_temp.axo_add(r, 'bugs: rate limit allows report 2 of 3', 'ok 1', pg_temp.axo_exec('authenticated', a, $q$insert into public.bugs (title, body) values ('rls bug four', 'rls bug body text')$q$));
    r := pg_temp.axo_add(r, 'bugs: rate limit allows report 3 of 3', 'ok 1', pg_temp.axo_exec('authenticated', a, $q$insert into public.bugs (title, body) values ('rls bug five', 'rls bug body text')$q$));
    r := pg_temp.axo_add(r, 'bugs: rate limit blocks the 4th within 10 minutes', 'error P0001', pg_temp.axo_exec('authenticated', a, $q$insert into public.bugs (title, body) values ('rls bug six', 'rls bug body text')$q$));

    -- ---------- cascade ----------
    delete from auth.users where id = a;
    r := pg_temp.axo_add(r, 'cascade: deleting the account removes profile, comments and bugs', '0/0/0',
      (select count(*) from public.users where id = a) || '/' ||
      (select count(*) from public.comments where author_id = a) || '/' ||
      (select count(*) from public.bugs where author_id = a));

    -- Carry the results out through the exception; everything above is rolled back.
    raise exception using errcode = 'AX001', message = r::text;
  exception when sqlstate 'AX001' then
    insert into axo_rls_results (name, expected, actual)
    select x ->> 'name', x ->> 'expected', x ->> 'actual'
    from jsonb_array_elements(sqlerrm::jsonb) x;
  end;
end;
$test$;

select
  count(*) filter (where expected = actual) as passed,
  count(*) filter (where expected is distinct from actual) as failed,
  coalesce(
    jsonb_agg(jsonb_build_object('name', name, 'expected', expected, 'actual', actual))
      filter (where expected is distinct from actual),
    '[]'::jsonb
  ) as failures
from axo_rls_results;
