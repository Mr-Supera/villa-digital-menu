begin;

-- Order item updates are restricted to staff/admin/editor, matching orders.
drop policy if exists "admin editor staff update order items" on public.order_items;
create policy "admin editor staff update order items"
on public.order_items
for update to authenticated
using (
  public.has_role(auth.uid(),'admin')
  or public.has_role(auth.uid(),'editor')
  or public.has_role(auth.uid(),'staff')
)
with check (
  public.has_role(auth.uid(),'admin')
  or public.has_role(auth.uid(),'editor')
  or public.has_role(auth.uid(),'staff')
);

-- Realtime must cover both the order header and its line items.
alter table public.orders replica identity full;
alter table public.order_items replica identity full;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='orders'
  ) then
    alter publication supabase_realtime add table public.orders;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='order_items'
  ) then
    alter publication supabase_realtime add table public.order_items;
  end if;
end $$;

-- Public status lookup exposes only the token-matched order and adds its creation time.
create or replace function public.get_order_status(p_token uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'order_number', o.order_number,
    'status', o.status,
    'table_number', o.table_number,
    'created_at', o.created_at,
    'items',
      coalesce(
        jsonb_agg(
          jsonb_build_object(
            'name', oi.name_snapshot,
            'quantity', oi.quantity
          )
          order by oi.id
        ) filter (where oi.id is not null),
        '[]'::jsonb
      )
  )
  from public.orders o
  left join public.order_items oi on oi.order_id = o.id
  where o.public_token = p_token
  group by o.id, o.order_number, o.status, o.table_number, o.created_at;
$$;

revoke all on function public.get_order_status(uuid) from public;
grant execute on function public.get_order_status(uuid) to anon, authenticated;

commit;
