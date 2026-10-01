begin;

alter table public.settings
  add column if not exists updated_by uuid references auth.users(id);

alter table public.settings
  add column if not exists updated_at timestamptz not null default now();

update public.settings
set is_public = true
where key = 'ordering_enabled';

create or replace function public.set_ordering_enabled(p_enabled boolean)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null
     or not (
       public.has_role(uid, 'admin')
       or public.has_role(uid, 'editor')
       or public.has_role(uid, 'staff')
     ) then
    raise exception 'permission denied';
  end if;

  insert into public.settings(key, value, is_public, updated_by, updated_at)
  values ('ordering_enabled', case when p_enabled then 'true' else 'false' end, true, uid, now())
  on conflict (key) do update
    set value = excluded.value,
        is_public = true,
        updated_by = excluded.updated_by,
        updated_at = excluded.updated_at;

  return p_enabled;
end;
$$;

create or replace function public.get_ordering_status()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  result jsonb;
begin
  if uid is null
     or not (
       public.has_role(uid, 'admin')
       or public.has_role(uid, 'editor')
       or public.has_role(uid, 'staff')
     ) then
    raise exception 'permission denied';
  end if;

  select jsonb_build_object(
    'enabled', coalesce(s.value = 'true', true),
    'updated_by_email', u.email,
    'updated_at', s.updated_at
  )
  into result
  from public.settings s
  left join auth.users u on u.id = s.updated_by
  where s.key = 'ordering_enabled';

  return coalesce(result, jsonb_build_object(
    'enabled', true,
    'updated_by_email', null,
    'updated_at', null
  ));
end;
$$;

revoke all on function public.set_ordering_enabled(boolean) from public;
revoke all on function public.get_ordering_status() from public;
revoke execute on function public.set_ordering_enabled(boolean) from anon;
revoke execute on function public.get_ordering_status() from anon;
grant execute on function public.set_ordering_enabled(boolean) to authenticated;
grant execute on function public.get_ordering_status() to authenticated;

commit;
