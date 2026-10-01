begin;

create or replace function public.create_order(
  p_table_number text,
  p_items jsonb,
  p_customer_name text default null,
  p_customer_note text default null,
  p_honeypot text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_table public.restaurant_tables%rowtype;
  v_item jsonb;
  v_item_row public.items%rowtype;
  v_order_id uuid;
  v_order_number integer;
  v_token uuid;
  v_total numeric(10,2) := 0;
  v_qty integer;
  v_note text;
  v_name text;
  v_max integer := 30;
  v_cooldown integer := 60;
  v_count integer;
  v_ip_hash text;
  v_ip text;
begin
  if coalesce(p_honeypot,'') <> '' then
    return jsonb_build_object('ok',true);
  end if;

  if coalesce(length(trim(p_table_number)),0) = 0 then
    return jsonb_build_object('code','E_MESA');
  end if;

  if exists (select 1 from public.settings s where s.key='ordering_enabled' and lower(coalesce(s.value,''))='false') then
    return jsonb_build_object('code','E_OFF');
  end if;

  select * into v_table from public.restaurant_tables t
  where t.is_active=true
    and lower(trim(t.number))=lower(trim(p_table_number))
  limit 1;
  if not found then return jsonb_build_object('code','E_MESA'); end if;

  select greatest(1,least(30,coalesce(nullif(value,'')::integer,30))) into v_max
  from public.settings where key='max_items_per_order';
  select greatest(0,coalesce(nullif(value,'')::integer,60)) into v_cooldown
  from public.settings where key='order_cooldown_seconds';

  if jsonb_array_length(coalesce(p_items,'[]'::jsonb)) < 1
     or jsonb_array_length(p_items) > v_max then
    return jsonb_build_object('code','E_LIMITE');
  end if;

  for v_item in select * from jsonb_array_elements(p_items) loop
    if not (v_item ? 'item_id') or not (v_item ? 'quantity') then
      return jsonb_build_object('code','E_ITEM');
    end if;
    v_qty := (v_item->>'quantity')::integer;
    if v_qty < 1 or v_qty > 20 then return jsonb_build_object('code','E_ITEM'); end if;

    select * into v_item_row from public.items i
    where i.id=(v_item->>'item_id')::uuid
      and i.is_active=true
      and coalesce(i.is_available,true)=true
    limit 1;
    if not found then return jsonb_build_object('code','E_ITEM'); end if;

    v_note := left(regexp_replace(coalesce(v_item->>'note',''),'<[^>]*>','','g'),120);
    v_name := left(regexp_replace(coalesce(v_item_row.name_pt,''),'<[^>]*>','','g'),200);
    v_total := v_total + (v_item_row.price::numeric * v_qty);
  end loop;

  v_total := round(v_total,2);

  insert into public.orders(table_id,table_number,customer_name,customer_note,total,status,public_token)
  values(v_table.id,v_table.number,left(regexp_replace(coalesce(p_customer_name,''),'<[^>]*>','','g'),40),
    left(regexp_replace(coalesce(p_customer_note,''),'<[^>]*>','','g'),200),v_total,'novo',gen_random_uuid())
  returning id,order_number,public_token into v_order_id,v_order_number,v_token;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_item_row from public.items where id=(v_item->>'item_id')::uuid;
    v_qty := (v_item->>'quantity')::integer;
    v_note := left(regexp_replace(coalesce(v_item->>'note',''),'<[^>]*>','','g'),120);
    insert into public.order_items(order_id,item_id,name_snapshot,price_snapshot,quantity,note)
    values(v_order_id,v_item_row.id,v_item_row.name_pt,v_item_row.price,v_qty,nullif(v_note,''));
  end loop;

  return jsonb_build_object('order_number',v_order_number,'public_token',v_token);
exception when others then
  if v_order_id is not null then delete from public.orders where id=v_order_id; end if;
  raise;
end $$;

revoke all on function public.create_order(text,jsonb,text,text,text) from public;
grant execute on function public.create_order(text,jsonb,text,text,text) to anon, authenticated;

commit;
