begin;

alter table public.user_roles enable row level security;

do $$
declare p record;
begin
  for p in
    select policyname from pg_policies
    where schemaname='public' and tablename='user_roles'
  loop
    execute format('drop policy if exists %I on public.user_roles', p.policyname);
  end loop;
end $$;

drop function if exists public.admin_exists();
create or replace function public.admin_exists()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_roles
    where role = 'admin'
  );
$$;

revoke all on function public.admin_exists() from public;
grant execute on function public.admin_exists() to anon, authenticated;

create or replace function public.claim_first_admin()
returns boolean
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  user_email text;
begin
  perform pg_advisory_xact_lock(741239001);

  if uid is null then
    raise exception 'É necessário iniciar sessão para criar o administrador.';
  end if;

  if exists (select 1 from public.user_roles where role = 'admin') then
    raise exception 'A configuração inicial já foi concluída.';
  end if;

  select email into user_email from auth.users where id = uid;

  if user_email is null then
    raise exception 'Não foi possível obter o email da conta.';
  end if;

  insert into public.user_roles (user_id, email, role)
  values (uid, user_email, 'admin')
  on conflict (user_id, role) do nothing;

  return true;
end;
$$;

revoke all on function public.claim_first_admin() from public;
grant execute on function public.claim_first_admin() to authenticated;

revoke all on public.user_roles from anon;
grant select, update, delete on public.user_roles to authenticated;

create policy user_roles_select_own
on public.user_roles
for select
to authenticated
using (
  (select auth.uid()) = user_id
  or (select public.has_role((select auth.uid()), 'admin'))
);

create policy user_roles_update_admin
on public.user_roles
for update
to authenticated
using (
  (select public.has_role((select auth.uid()), 'admin'))
)
with check (
  (select public.has_role((select auth.uid()), 'admin'))
);

create policy user_roles_delete_admin
on public.user_roles
for delete
to authenticated
using (
  (select public.has_role((select auth.uid()), 'admin'))
);

commit;

-- A reparação única da conta existente foi deliberadamente deixada fora desta migration
-- porque o email real da conta não está disponível no repositório. Depois de fornecer o
-- email, será acrescentado um UPDATE/INSERT único e condicionado à inexistência de admin.
