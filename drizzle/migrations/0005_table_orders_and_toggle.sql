create table if not exists public.restaurant_tables (
  id uuid primary key default gen_random_uuid(),
  number text not null unique,
  label text,
  is_active boolean not null default true,
  sort_order integer not null default 0
);
create index if not exists restaurant_tables_active_sort_idx on public.restaurant_tables(is_active, sort_order, number);

create sequence if not exists public.orders_order_number_seq;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number integer not null default nextval('public.orders_order_number_seq') unique,
  table_id uuid not null references public.restaurant_tables(id),
  table_number text not null,
  customer_name text,
  customer_note text,
  status text not null default 'novo' check (status in ('novo','em_preparacao','pronto','entregue','cancelado')),
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

alter table public.settings add column if not exists is_public boolean not null default false;
alter table public.settings add column if not exists updated_by uuid references auth.users(id);
alter table public.settings add column if not exists updated_at timestamptz not null default now();

insert into public.settings(key,value,is_public) values
  ('ordering_enabled','true',true),
  ('max_items_per_order','30',false),
  ('order_cooldown_seconds','60',false)
on conflict (key) do nothing;
update public.settings set is_public = true where key = 'ordering_enabled';

grant select on public.restaurant_tables to anon, authenticated;
grant all on public.restaurant_tables to authenticated;
grant select, update, delete on public.orders to authenticated;
grant select on public.order_items to authenticated;
grant all on public.orders to service_role;
grant all on public.order_items to service_role;
grant all on public.restaurant_tables to service_role;

alter table public.restaurant_tables enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

create policy "public reads active restaurant tables" on public.restaurant_tables for select to anon, authenticated
using (is_active or public.has_role(auth.uid(),'admin') or public.has_role(auth.uid(),'editor'));
create policy "admin editor manage restaurant tables" on public.restaurant_tables for all to authenticated
using (public.has_role(auth.uid(),'admin') or public.has_role(auth.uid(),'editor'))
with check (public.has_role(auth.uid(),'admin') or public.has_role(auth.uid(),'editor'));

create policy "admin editor staff read orders" on public.orders for select to authenticated
using (public.has_role(auth.uid(),'admin') or public.has_role(auth.uid(),'editor') or public.has_role(auth.uid(),'staff'));
create policy "admin editor staff update orders" on public.orders for update to authenticated
using (public.has_role(auth.uid(),'admin') or public.has_role(auth.uid(),'editor') or public.has_role(auth.uid(),'staff'))
with check (public.has_role(auth.uid(),'admin') or public.has_role(auth.uid(),'editor') or public.has_role(auth.uid(),'staff'));
create policy "admins delete orders" on public.orders for delete to authenticated
using (public.has_role(auth.uid(),'admin'));
create policy "admin editor staff read order items" on public.order_items for select to authenticated
using (public.has_role(auth.uid(),'admin') or public.has_role(auth.uid(),'editor') or public.has_role(auth.uid(),'staff'));

create or replace function public.get_order_status(p_token uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('order_number', o.order_number, 'status', o.status, 'table_number', o.table_number,
    'items', coalesce(jsonb_agg(jsonb_build_object('name', oi.name_snapshot, 'quantity', oi.quantity) order by oi.id) filter (where oi.id is not null), '[]'::jsonb))
  from public.orders o left join public.order_items oi on oi.order_id = o.id
  where o.public_token = p_token
  group by o.id, o.order_number, o.status, o.table_number;
$$;
revoke all on function public.get_order_status(uuid) from public;
grant execute on function public.get_order_status(uuid) to anon, authenticated;

create or replace function public.touch_order_updated_at()
returns trigger language plpgsql security definer set search_path = '' as $$
begin new.updated_at = now(); return new; end; $$;
drop trigger if exists orders_touch_updated_at on public.orders;
create trigger orders_touch_updated_at before update on public.orders for each row execute function public.touch_order_updated_at();

create or replace function public.set_ordering_enabled(p_enabled boolean)
returns boolean language plpgsql security definer set search_path = '' as $$
declare uid uuid := auth.uid();
begin
  if uid is null or not (public.has_role(uid,'admin') or public.has_role(uid,'editor') or public.has_role(uid,'staff')) then
    raise exception 'permission denied';
  end if;
  insert into public.settings(key, value, is_public, updated_by, updated_at)
  values ('ordering_enabled', case when p_enabled then 'true' else 'false' end, true, uid, now())
  on conflict (key) do update set value = excluded.value, is_public = true, updated_by = excluded.updated_by, updated_at = excluded.updated_at;
  return p_enabled;
end; $$;

create or replace function public.get_ordering_status()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare uid uuid := auth.uid(); result jsonb;
begin
  if uid is null or not (public.has_role(uid,'admin') or public.has_role(uid,'editor') or public.has_role(uid,'staff')) then
    raise exception 'permission denied';
  end if;
  select jsonb_build_object('enabled', coalesce(s.value = 'true', true), 'updated_by_email', u.email, 'updated_at', s.updated_at)
  into result from public.settings s left join auth.users u on u.id = s.updated_by where s.key = 'ordering_enabled';
  return coalesce(result, jsonb_build_object('enabled', true, 'updated_by_email', null, 'updated_at', null));
end; $$;
revoke all on function public.set_ordering_enabled(boolean) from public, anon;
revoke all on function public.get_ordering_status() from public, anon;
grant execute on function public.set_ordering_enabled(boolean) to authenticated;
grant execute on function public.get_ordering_status() to authenticated;

do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='orders') then
    alter publication supabase_realtime add table public.orders;
  end if;
end $$;