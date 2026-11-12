-- Отпечаток схемы: по одной строке на вид объектов (колонки, ограничения, политики, права...).
-- Запустите на двух базах и сравните вывод: одинаковые хэши = одинаковая схема и права.

with r(rolname) as (values ('anon'), ('authenticated')),
items as (
  select 'col' as kind, c.relname || '.' || a.attnum || ' ' || a.attname || ' ' || format_type(a.atttypid, a.atttypmod) || ' ' || a.attnotnull::text || ' ' || coalesce(pg_get_expr(d.adbin, d.adrelid), '') || ' ' || a.attidentity::text as item
  from pg_attribute a join pg_class c on c.oid = a.attrelid join pg_namespace n on n.oid = c.relnamespace
  left join pg_attrdef d on d.adrelid = a.attrelid and d.adnum = a.attnum
  where n.nspname = 'public' and c.relkind = 'r' and a.attnum > 0 and not a.attisdropped
  union all
  select 'con', c.relname || '.' || con.conname || ' ' || pg_get_constraintdef(con.oid)
  from pg_constraint con join pg_class c on c.oid = con.conrelid join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public'
  union all
  select 'idx', indexdef from pg_indexes where schemaname = 'public'
  union all
  select 'pol', tablename || '.' || policyname || ' ' || cmd || ' ' || roles::text || ' ' || coalesce(qual, '') || ' / ' || coalesce(with_check, '') from pg_policies where schemaname = 'public'
  union all
  select 'trg', pg_get_triggerdef(t.oid) from pg_trigger t join pg_class c on c.oid = t.tgrelid join pg_namespace n on n.oid = c.relnamespace
  where not t.tgisinternal and (n.nspname = 'public' or t.tgname = 'on_auth_user_created')
  union all
  select 'fn', p.proname || ' ' || p.prosecdef::text || ' ' || p.provolatile::text || ' ' || coalesce(p.proconfig::text, '') || ' ' || p.prosrc
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public'
  union all
  select 'fnacl', p.proname || ' ' || r.rolname || ' ' || has_function_privilege(r.rolname, p.oid, 'execute')::text
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace cross join r where n.nspname = 'public'
  union all
  select 'fnpub', p.proname || ' ' || exists (select 1 from aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) x where x.grantee = 0)::text
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public'
  union all
  select 'tblpriv', table_name || ' ' || grantee || ' ' || privilege_type from information_schema.table_privileges where table_schema = 'public' and grantee in ('anon', 'authenticated', 'PUBLIC')
  union all
  select 'colpriv', table_name || '.' || column_name || ' ' || grantee || ' ' || privilege_type from information_schema.column_privileges where table_schema = 'public' and grantee in ('anon', 'authenticated', 'PUBLIC')
  union all
  select 'seqpriv', c.relname || ' ' || r.rolname || ' ' || has_sequence_privilege(r.rolname, c.oid, 'usage')::text || has_sequence_privilege(r.rolname, c.oid, 'update')::text || has_sequence_privilege(r.rolname, c.oid, 'select')::text
  from pg_class c join pg_namespace n on n.oid = c.relnamespace cross join r where n.nspname = 'public' and c.relkind = 'S'
  union all
  select 'rls', c.relname || ' ' || c.relrowsecurity::text || c.relforcerowsecurity::text from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relkind = 'r'
)
select kind, count(*) as n, md5(string_agg(item, E'\n' order by item collate "C")) as fp from items group by kind order by kind;
