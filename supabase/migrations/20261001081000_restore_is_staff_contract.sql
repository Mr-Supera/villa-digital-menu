begin;

-- Keep the pre-existing is_staff contract intact: it is used by menu RLS for admin/editor.
-- Staff accounts are intentionally limited to the orders area via direct role checks.
create or replace function public.is_staff(_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = _user_id and role in ('admin','editor')
  )
$$;

commit;