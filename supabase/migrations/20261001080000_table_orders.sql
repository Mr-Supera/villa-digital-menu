begin;

-- Table ordering schema. Reuse the existing menu/auth model and do not touch existing menu rows.
do $$ begin
  alter type public.app_role add value if not exists 'staff';
exception when duplicate_object then null; end $$;

create table if not exists public.restaurant_tables (
  id uuid primary key default gen_random_uuid(),
  number text not null unique,
  label text,
  is_active boolean not null default true,
  sort_order integer not null default 0
);
create index if not exists restaurant_tables_active_sort_idx
  on public.restaurant_tables(is_active, sort_order, number);

create sequence if not exists public.orders_order_number_seq;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number integer not null default nextval('public.orders_order_number_seq') unique,
  table_id uuid not null references public.restaurant_tables(id),
  table_number text not null,
  customer_name text,
  customer_note text,
  status text not null default 'novo'
    check (status in ('novo','em_preparacao','pronto','entregue','cancelado')),
  total numeric(10,2) not null default 0,
  public_token uuid not null default gen_random_uuid() unique,
  ip_hash text,
  seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists orders_status_created_idx on public.orders(status, created_at desc);
create index if not exists orders_table_created_idx on public.orders(table_number, created_at desc);
create index if not exists orders_ip_created_idx on public.orders(ip_hash, created_at desc);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  item_id uuid references public.items(id) on delete set null,
  name_snapshot text not null,
  price_snapshot numeric(10,2) not null,
  quantity integer not null check (quantity between 1 and 20),
  note text
);
create index if not exists order_items_order_idx on public.order_items(order_id);

alter table public.orders
  add column if not exists updated_at timestamptz not null default now();

alter table public.settings add column if not exists is_public boolean not null default false;

insert into public.settings(key,value,is_public)
values
  ('ordering_enabled','true',true),
  ('max_items_per_order','30',false),
  ('order_cooldown_seconds','60',false)
on conflict (key) do nothing;

-- Keep the public ordering switch readable without exposing private admin settings.
update public.settings
set is_public = true
where key = 'ordering_enabled';

create or replace function public.is_staff(_user_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = _user_id and role in ('admin','editor','staff')
  )
$$;

alter table public.restaurant_tables enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

revoke all on public.orders from anon;
revoke all on public.order_items from anon;
revoke all on public.restaurant_tables from anon;
grant select on public.restaurant_tables to anon, authenticated;
grant select, update on public.orders to authenticated;
grant select on public.order_items to authenticated;
grant all on public.restaurant_tables to authenticated;
grant delete on public.orders to authenticated;
grant all on public.orders to service_role;
grant all on public.order_items to service_role;
grant all on public.restaurant_tables to service_role;

drop policy if exists "public reads active restaurant tables" on public.restaurant_tables;
drop policy if exists "staff manages restaurant tables" on public.restaurant_tables;
create policy "public reads active restaurant tables"
on public.restaurant_tables for select
to anon, authenticated
using (is_active or public.has_role(auth.uid(),'admin') or public.has_role(auth.uid(),'editor'));

create policy "admin editor manage restaurant tables"
on public.restaurant_tables for all
to authenticated
using (public.has_role(auth.uid(),'admin') or public.has_role(auth.uid(),'editor'))
with check (public.has_role(auth.uid(),'admin') or public.has_role(auth.uid(),'editor'));

drop policy if exists "staff reads orders" on public.orders;
drop policy if exists "staff updates orders" on public.orders;
drop policy if exists "admins delete orders" on public.orders;
create policy "admin editor staff read orders"
on public.orders for select to authenticated
using (
  public.has_role(auth.uid(),'admin')
  or public.has_role(auth.uid(),'editor')
  or public.has_role(auth.uid(),'staff')
);
create policy "admin editor staff update orders"
on public.orders for update to authenticated
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
create policy "admins delete orders"
on public.orders for delete to authenticated
using (public.has_role(auth.uid(),'admin'));

create policy "admin editor staff read order items"
on public.order_items for select to authenticated
using (
  public.has_role(auth.uid(),'admin')
  or public.has_role(auth.uid(),'editor')
  or public.has_role(auth.uid(),'staff')
);

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
    'items', coalesce(
      jsonb_agg(
        jsonb_build_object(
          'name', oi.name_snapshot,
          'quantity', oi.quantity
        ) order by oi.id
      ) filter (where oi.id is not null),
      '[]'::jsonb
    )
  )
  from public.orders o
  left join public.order_items oi on oi.order_id = o.id
  where o.public_token = p_token
  group by o.id, o.order_number, o.status, o.table_number;
$$;

revoke all on function public.get_order_status(uuid) from public;
grant execute on function public.get_order_status(uuid) to anon, authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'orders'
  ) then
    alter publication supabase_realtime add table public.orders;
  end if;
end $$;

commit;