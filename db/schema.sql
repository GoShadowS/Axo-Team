-- Axo-Team: схема базы в Supabase (PostgreSQL).
--
-- Этот файл уже выполнен в проекте Supabase «Axo-Team». Это не миграция:
-- он нужен, чтобы поднять такую же базу с нуля (новый проект, локальная копия).
-- На базе, где таблицы уже есть, запускать его повторно нельзя.
--
-- Правила доступа:
--   * RLS включён на каждой таблице, политика описана рядом с таблицей.
--   * Права выдаются явно: Supabase по умолчанию даёт anon и authenticated всё,
--     поэтому сначала идёт revoke, потом точечные grant.
--   * Гость (anon) может только читать.
--   * Пользователь пишет комментарии и баг-репорты только от своего имени;
--     author_id подставляет база, клиент его прислать не может.
--   * Роль admin меняется только напрямую в базе. Через API её изменить нельзя.

-- ---------------------------------------------------------------------------
-- Общие функции
-- ---------------------------------------------------------------------------

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function public.set_updated_at() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- users: профиль аккаунта. Сам аккаунт (почта, пароль) хранит Supabase Auth.
-- ---------------------------------------------------------------------------

create table public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null
    check (char_length(display_name) between 2 and 40 and display_name = btrim(display_name)),
  role text not null default 'user' check (role in ('user', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger users_set_updated_at
  before update on public.users
  for each row execute function public.set_updated_at();

-- Владелец сайта? Выполняется с правами владельца функции, чтобы политики
-- других таблиц могли спросить роль, не открывая лишнего доступа к users.
create function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.users
    where id = (select auth.uid()) and role = 'admin'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- Профиль создаётся вместе с аккаунтом. Имя берётся из данных регистрации,
-- роль всегда user.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text;
begin
  v_name := btrim(regexp_replace(coalesce(new.raw_user_meta_data ->> 'display_name', ''), '\s+', ' ', 'g'));
  v_name := btrim(left(v_name, 40));
  if char_length(v_name) < 2 then
    v_name := 'Пользователь';
  end if;

  insert into public.users (id, display_name) values (new.id, v_name);
  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

alter table public.users enable row level security;

revoke all on public.users from anon, authenticated;
grant select on public.users to anon, authenticated;
-- Менять можно только имя. Колонка role клиенту недоступна.
grant update (display_name) on public.users to authenticated;

create policy users_select_all on public.users
  for select to anon, authenticated
  using (true);

create policy users_update_own on public.users
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- projects: каталог проектов
-- ---------------------------------------------------------------------------

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique
    check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 64),
  title text not null check (char_length(btrim(title)) between 1 and 120),
  summary text not null check (char_length(summary) <= 500),
  kind text not null check (char_length(kind) <= 80),
  status text not null default 'active' check (status in ('active', 'experimental')),
  stack text[] not null default '{}',
  license text check (license is null or char_length(license) <= 40),
  sort_order integer not null default 100,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger projects_set_updated_at
  before update on public.projects
  for each row execute function public.set_updated_at();

alter table public.projects enable row level security;

revoke all on public.projects from anon, authenticated;
grant select on public.projects to anon, authenticated;
grant insert, update, delete on public.projects to authenticated;

create policy projects_select_published on public.projects
  for select to anon, authenticated
  using (is_published or (select public.is_admin()));

create policy projects_insert_admin on public.projects
  for insert to authenticated
  with check ((select public.is_admin()));

create policy projects_update_admin on public.projects
  for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy projects_delete_admin on public.projects
  for delete to authenticated
  using ((select public.is_admin()));

-- ---------------------------------------------------------------------------
-- docs: страницы документации проекта в Markdown
-- ---------------------------------------------------------------------------

create table public.docs (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete cascade,
  slug text not null
    check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 64),
  title text not null check (char_length(btrim(title)) between 1 and 120),
  body_md text not null default '' check (char_length(body_md) <= 100000),
  sort_order integer not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (project_id, slug)
);

create index docs_project_idx on public.docs (project_id, sort_order);

create trigger docs_set_updated_at
  before update on public.docs
  for each row execute function public.set_updated_at();

alter table public.docs enable row level security;

revoke all on public.docs from anon, authenticated;
grant select on public.docs to anon, authenticated;
grant insert, update, delete on public.docs to authenticated;

-- Документ виден тогда, когда виден его проект: подзапрос к projects
-- сам проходит через политику projects.
create policy docs_select_visible_project on public.docs
  for select to anon, authenticated
  using (exists (select 1 from public.projects p where p.id = project_id));

create policy docs_insert_admin on public.docs
  for insert to authenticated
  with check ((select public.is_admin()));

create policy docs_update_admin on public.docs
  for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy docs_delete_admin on public.docs
  for delete to authenticated
  using ((select public.is_admin()));

-- ---------------------------------------------------------------------------
-- links: внешние ссылки проекта
-- ---------------------------------------------------------------------------

create table public.links (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete cascade,
  label text not null check (char_length(btrim(label)) between 1 and 80),
  url text not null check (url ~ '^https?://' and char_length(url) <= 2000),
  sort_order integer not null default 100,
  created_at timestamptz not null default now()
);

create index links_project_idx on public.links (project_id, sort_order);

alter table public.links enable row level security;

revoke all on public.links from anon, authenticated;
grant select on public.links to anon, authenticated;
grant insert, update, delete on public.links to authenticated;

create policy links_select_visible_project on public.links
  for select to anon, authenticated
  using (exists (select 1 from public.projects p where p.id = project_id));

create policy links_insert_admin on public.links
  for insert to authenticated
  with check ((select public.is_admin()));

create policy links_update_admin on public.links
  for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy links_delete_admin on public.links
  for delete to authenticated
  using ((select public.is_admin()));

-- ---------------------------------------------------------------------------
-- Защита от флуда: не больше N записей автора за интервал.
-- Аргументы триггера: лимит и интервал. Владелец под лимит не попадает.
-- ---------------------------------------------------------------------------

create function public.enforce_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_limit integer := tg_argv[0]::integer;
  v_window interval := tg_argv[1]::interval;
  v_count integer;
begin
  if (select public.is_admin()) then
    return new;
  end if;

  execute format(
    'select count(*) from public.%I where author_id = $1 and created_at > now() - $2',
    tg_table_name
  )
  into v_count
  using new.author_id, v_window;

  if v_count >= v_limit then
    raise exception 'rate_limit_exceeded'
      using hint = 'Слишком много записей за короткое время. Подождите немного.';
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_rate_limit() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- comments: комментарии к проекту
-- ---------------------------------------------------------------------------

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete cascade,
  author_id uuid not null default auth.uid() references public.users (id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 2000),
  is_hidden boolean not null default false,
  created_at timestamptz not null default now()
);

create index comments_project_idx on public.comments (project_id, created_at desc);
create index comments_author_idx on public.comments (author_id, created_at desc);

create trigger comments_rate_limit
  before insert on public.comments
  for each row execute function public.enforce_rate_limit('5', '1 minute');

alter table public.comments enable row level security;

revoke all on public.comments from anon, authenticated;
grant select on public.comments to anon, authenticated;
-- Клиент присылает только проект и текст. Скрывать может только владелец.
grant insert (project_id, body) on public.comments to authenticated;
grant update (is_hidden) on public.comments to authenticated;
grant delete on public.comments to authenticated;

-- Скрытый комментарий видят автор и владелец.
create policy comments_select_visible on public.comments
  for select to anon, authenticated
  using (
    (not is_hidden or author_id = (select auth.uid()) or (select public.is_admin()))
    and exists (select 1 from public.projects p where p.id = project_id)
  );

create policy comments_insert_own on public.comments
  for insert to authenticated
  with check (
    author_id = (select auth.uid())
    and not is_hidden
    and exists (select 1 from public.projects p where p.id = project_id)
  );

create policy comments_update_admin on public.comments
  for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy comments_delete_own_or_admin on public.comments
  for delete to authenticated
  using (author_id = (select auth.uid()) or (select public.is_admin()));

-- ---------------------------------------------------------------------------
-- bugs: баг-репорты. Проект можно не указывать (ошибка самого сайта).
-- ---------------------------------------------------------------------------

create table public.bugs (
  id uuid primary key default gen_random_uuid(),
  number bigint generated always as identity unique,
  project_id uuid references public.projects (id) on delete set null,
  author_id uuid not null default auth.uid() references public.users (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 5 and 120),
  body text not null check (char_length(btrim(body)) between 10 and 5000),
  status text not null default 'new'
    check (status in ('new', 'confirmed', 'in_progress', 'fixed', 'rejected')),
  is_hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index bugs_created_idx on public.bugs (created_at desc);
create index bugs_project_idx on public.bugs (project_id);
create index bugs_author_idx on public.bugs (author_id, created_at desc);

create trigger bugs_set_updated_at
  before update on public.bugs
  for each row execute function public.set_updated_at();

create trigger bugs_rate_limit
  before insert on public.bugs
  for each row execute function public.enforce_rate_limit('3', '10 minutes');

alter table public.bugs enable row level security;

revoke all on public.bugs from anon, authenticated;
-- Номер выдаёт база; клиенту счётчик не нужен.
revoke all on sequence public.bugs_number_seq from anon, authenticated;
grant select on public.bugs to anon, authenticated;
grant insert (project_id, title, body) on public.bugs to authenticated;
-- Статус и скрытие меняет только владелец (см. политику).
grant update (status, is_hidden) on public.bugs to authenticated;
grant delete on public.bugs to authenticated;

create policy bugs_select_visible on public.bugs
  for select to anon, authenticated
  using (not is_hidden or author_id = (select auth.uid()) or (select public.is_admin()));

create policy bugs_insert_own on public.bugs
  for insert to authenticated
  with check (
    author_id = (select auth.uid())
    and status = 'new'
    and not is_hidden
    and (project_id is null or exists (select 1 from public.projects p where p.id = project_id))
  );

create policy bugs_update_admin on public.bugs
  for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

-- Автор может отозвать репорт, пока его не взяли в работу.
create policy bugs_delete_own_new_or_admin on public.bugs
  for delete to authenticated
  using ((author_id = (select auth.uid()) and status = 'new') or (select public.is_admin()));
