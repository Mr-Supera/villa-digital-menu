CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE TABLE IF NOT EXISTS public.table_keys (
  table_id uuid PRIMARY KEY REFERENCES public.restaurant_tables(id) ON DELETE CASCADE,
  access_key text NOT NULL DEFAULT encode(extensions.gen_random_bytes(12),'hex') CHECK (length(access_key) >= 12),
  rotated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.table_keys TO authenticated;
GRANT ALL ON public.table_keys TO service_role;
ALTER TABLE public.table_keys ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin editor manage table keys" ON public.table_keys FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'editor'))
  WITH CHECK (public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'editor'));
INSERT INTO public.table_keys (table_id) SELECT id FROM public.restaurant_tables ON CONFLICT DO NOTHING;

CREATE OR REPLACE FUNCTION public.create_table_key() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
BEGIN INSERT INTO public.table_keys(table_id) VALUES (NEW.id) ON CONFLICT DO NOTHING; RETURN NEW; END; $$;
REVOKE EXECUTE ON FUNCTION public.create_table_key() FROM public, anon, authenticated;
DROP TRIGGER IF EXISTS restaurant_tables_create_key ON public.restaurant_tables;
CREATE TRIGGER restaurant_tables_create_key AFTER INSERT ON public.restaurant_tables FOR EACH ROW EXECUTE FUNCTION public.create_table_key();

CREATE TABLE IF NOT EXISTS public.table_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  table_id uuid NOT NULL REFERENCES public.restaurant_tables(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'aberta' CHECK (status IN ('aberta','encerrada')),
  opened_at timestamptz NOT NULL DEFAULT now(),
  last_activity_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz,
  closed_by text CHECK (closed_by IN ('cliente','staff','automatico')),
  failed_attempts integer NOT NULL DEFAULT 0,
  locked_until timestamptz,
  opened_device_hash text
);
CREATE UNIQUE INDEX IF NOT EXISTS table_sessions_one_open ON public.table_sessions(table_id) WHERE status = 'aberta';
GRANT SELECT ON public.table_sessions TO authenticated;
GRANT ALL ON public.table_sessions TO service_role;
ALTER TABLE public.table_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "staff read table sessions" ON public.table_sessions FOR SELECT TO authenticated
  USING (public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'editor') OR public.has_role(auth.uid(),'staff'));

CREATE TABLE IF NOT EXISTS public.table_session_secrets (
  session_id uuid PRIMARY KEY REFERENCES public.table_sessions(id) ON DELETE CASCADE,
  pin_hash text NOT NULL
);
GRANT ALL ON public.table_session_secrets TO service_role;
ALTER TABLE public.table_session_secrets ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.session_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES public.table_sessions(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  device_hash text,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT ALL ON public.session_tokens TO service_role;
ALTER TABLE public.session_tokens ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.pin_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_hash text NOT NULL,
  table_id uuid NOT NULL REFERENCES public.restaurant_tables(id) ON DELETE CASCADE,
  attempted_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS pin_attempts_dev_idx ON public.pin_attempts(device_hash, table_id, attempted_at);
GRANT ALL ON public.pin_attempts TO service_role;
ALTER TABLE public.pin_attempts ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS session_id uuid REFERENCES public.table_sessions(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS orders_session_idx ON public.orders(session_id);

REVOKE ALL ON public.orders FROM anon;
REVOKE ALL ON public.order_items FROM anon;

ALTER TABLE public.orders REPLICA IDENTITY FULL;
ALTER TABLE public.order_items REPLICA IDENTITY FULL;
ALTER TABLE public.table_sessions REPLICA IDENTITY FULL;
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['orders','order_items','table_sessions'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename=t) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
    END IF;
  END LOOP;
END $$;

-- helpers
CREATE OR REPLACE FUNCTION public._ts_norm(p text) RETURNS text LANGUAGE sql IMMUTABLE SET search_path = public AS $$ SELECT lower(regexp_replace(coalesce(p,''),'\s','','g')) $$;
CREATE OR REPLACE FUNCTION public._ts_setting(p_key text) RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$ SELECT value FROM public.settings WHERE key = p_key $$;
CREATE OR REPLACE FUNCTION public._ts_hash(p text) RETURNS text LANGUAGE sql IMMUTABLE SET search_path = public, extensions AS $$ SELECT encode(extensions.digest(coalesce(p,''),'sha256'),'hex') $$;
CREATE OR REPLACE FUNCTION public._ts_device(p_device_id text) RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, extensions AS $$
  SELECT public._ts_hash(coalesce(p_device_id,'') || coalesce(public._ts_setting('hash_salt'),'')) $$;
CREATE OR REPLACE FUNCTION public._ts_table(p_table text, p_key text) RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT t.id FROM public.restaurant_tables t JOIN public.table_keys k ON k.table_id = t.id
  WHERE t.is_active AND public._ts_norm(t.number) = public._ts_norm(p_table) AND k.access_key = coalesce(p_key,'') LIMIT 1 $$;
CREATE OR REPLACE FUNCTION public._ts_session(p_token text) RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, extensions AS $$
  SELECT s.id FROM public.session_tokens st JOIN public.table_sessions s ON s.id = st.session_id
  WHERE p_token IS NOT NULL AND st.token_hash = public._ts_hash(p_token) AND s.status = 'aberta' LIMIT 1 $$;
CREATE OR REPLACE FUNCTION public._ts_new_token(p_session uuid, p_device_hash text) RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_tok text := encode(extensions.gen_random_bytes(32),'hex');
BEGIN INSERT INTO public.session_tokens(session_id, token_hash, device_hash) VALUES (p_session, public._ts_hash(v_tok), p_device_hash); RETURN v_tok; END $$;
CREATE OR REPLACE FUNCTION public._ts_pin_weak(p_pin text) RETURNS boolean LANGUAGE sql IMMUTABLE SET search_path = public AS $$
  SELECT p_pin ~ '^(\d)\1{3}$' OR p_pin IN ('1234','4321','0123','3210','1212','2580') $$;
CREATE OR REPLACE FUNCTION public._ts_is_crew() RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT auth.uid() IS NOT NULL AND (public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'editor') OR public.has_role(auth.uid(),'staff')) $$;

-- l) expire_sessions
CREATE OR REPLACE FUNCTION public.expire_sessions() RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_empty int := coalesce(nullif(public._ts_setting('empty_session_minutes'),'')::int, 30);
        v_hours int := coalesce(nullif(public._ts_setting('session_timeout_hours'),'')::int, 4);
        v_n int;
BEGIN
  WITH c AS (
    UPDATE public.table_sessions s SET status='encerrada', closed_at=now(), closed_by='automatico'
    WHERE s.status='aberta' AND (
      (s.last_activity_at < now() - make_interval(mins => v_empty) AND NOT EXISTS (SELECT 1 FROM public.orders o WHERE o.session_id = s.id))
      OR s.last_activity_at < now() - make_interval(hours => v_hours))
    RETURNING s.id)
  DELETE FROM public.session_tokens WHERE session_id IN (SELECT id FROM c);
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN json_build_object('ok', true);
EXCEPTION WHEN others THEN RETURN json_build_object('ok', false, 'code', 'E_SERVIDOR');
END $$;

-- a)
CREATE OR REPLACE FUNCTION public.get_table_state(p_table text, p_key text, p_token text DEFAULT NULL) RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_tid uuid; v_s public.table_sessions; v_tok uuid;
BEGIN
  PERFORM public.expire_sessions();
  v_tid := public._ts_table(p_table, p_key);
  IF v_tid IS NULL THEN RETURN json_build_object('ok', true, 'state', 'invalida', 'joined', false, 'opened_at', null); END IF;
  SELECT * INTO v_s FROM public.table_sessions WHERE table_id = v_tid AND status='aberta';
  IF v_s.id IS NULL THEN RETURN json_build_object('ok', true, 'state', 'livre', 'joined', false, 'opened_at', null); END IF;
  v_tok := public._ts_session(p_token);
  RETURN json_build_object('ok', true, 'state', 'ocupada', 'joined', coalesce(v_tok = v_s.id, false), 'opened_at', v_s.opened_at);
EXCEPTION WHEN others THEN RETURN json_build_object('ok', false, 'code', 'E_SERVIDOR');
END $$;

-- b)
CREATE OR REPLACE FUNCTION public.open_table(p_table text, p_key text, p_pin text, p_device_id text) RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_tid uuid; v_dev text; v_sid uuid;
BEGIN
  v_tid := public._ts_table(p_table, p_key);
  IF v_tid IS NULL THEN RETURN json_build_object('ok', false, 'code', 'E_CHAVE'); END IF;
  IF p_pin IS NULL OR p_pin !~ '^\d{4}$' THEN RETURN json_build_object('ok', false, 'code', 'E_DADOS'); END IF;
  IF public._ts_pin_weak(p_pin) THEN RETURN json_build_object('ok', false, 'code', 'E_PIN_FRACO'); END IF;
  PERFORM public.expire_sessions();
  IF EXISTS (SELECT 1 FROM public.table_sessions WHERE table_id = v_tid AND status='aberta') THEN RETURN json_build_object('ok', false, 'code', 'E_OCUPADA'); END IF;
  v_dev := public._ts_device(p_device_id);
  IF (SELECT count(*) FROM public.table_sessions WHERE opened_device_hash = v_dev AND opened_at > now() - interval '60 minutes') >= 2 THEN
    RETURN json_build_object('ok', false, 'code', 'E_LIMITE'); END IF;
  BEGIN
    INSERT INTO public.table_sessions(table_id, opened_device_hash) VALUES (v_tid, v_dev) RETURNING id INTO v_sid;
  EXCEPTION WHEN unique_violation THEN RETURN json_build_object('ok', false, 'code', 'E_OCUPADA'); END;
  INSERT INTO public.table_session_secrets(session_id, pin_hash) VALUES (v_sid, extensions.crypt(p_pin, extensions.gen_salt('bf')));
  RETURN json_build_object('ok', true, 'token', public._ts_new_token(v_sid, v_dev));
EXCEPTION WHEN others THEN RETURN json_build_object('ok', false, 'code', 'E_SERVIDOR');
END $$;

-- c)
CREATE OR REPLACE FUNCTION public.join_table(p_table text, p_key text, p_pin text, p_device_id text) RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_tid uuid; v_dev text; v_s public.table_sessions; v_hash text; v_cnt int;
BEGIN
  v_tid := public._ts_table(p_table, p_key);
  IF v_tid IS NULL THEN RETURN json_build_object('ok', false, 'code', 'E_CHAVE'); END IF;
  PERFORM public.expire_sessions();
  SELECT * INTO v_s FROM public.table_sessions WHERE table_id = v_tid AND status='aberta' FOR UPDATE;
  IF v_s.id IS NULL THEN RETURN json_build_object('ok', false, 'code', 'E_LIVRE'); END IF;
  IF v_s.locked_until IS NOT NULL AND v_s.locked_until > now() THEN RETURN json_build_object('ok', false, 'code', 'E_BLOQUEADA'); END IF;
  v_dev := public._ts_device(p_device_id);
  SELECT count(*) INTO v_cnt FROM public.pin_attempts WHERE device_hash = v_dev AND table_id = v_tid AND attempted_at > now() - interval '1 hour';
  IF v_cnt >= 5 THEN RETURN json_build_object('ok', false, 'code', 'E_LIMITE', 'attempts_left', 0); END IF;
  SELECT pin_hash INTO v_hash FROM public.table_session_secrets WHERE session_id = v_s.id;
  IF p_pin IS NOT NULL AND p_pin ~ '^\d{4}$' AND v_hash IS NOT NULL AND extensions.crypt(p_pin, v_hash) = v_hash THEN
    UPDATE public.table_sessions SET failed_attempts = 0, last_activity_at = now() WHERE id = v_s.id;
    RETURN json_build_object('ok', true, 'token', public._ts_new_token(v_s.id, v_dev));
  END IF;
  INSERT INTO public.pin_attempts(device_hash, table_id) VALUES (v_dev, v_tid);
  IF v_s.failed_attempts + 1 >= 10 THEN
    UPDATE public.table_sessions SET failed_attempts = 0, locked_until = now() + interval '15 minutes' WHERE id = v_s.id;
    RETURN json_build_object('ok', false, 'code', 'E_BLOQUEADA');
  END IF;
  UPDATE public.table_sessions SET failed_attempts = failed_attempts + 1 WHERE id = v_s.id;
  RETURN json_build_object('ok', false, 'code', 'E_PIN', 'attempts_left', greatest(0, 5 - (v_cnt + 1)));
EXCEPTION WHEN others THEN RETURN json_build_object('ok', false, 'code', 'E_SERVIDOR');
END $$;

-- d)
CREATE OR REPLACE FUNCTION public.end_table_by_client(p_token text) RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_sid uuid := public._ts_session(p_token);
BEGIN
  IF v_sid IS NULL THEN RETURN json_build_object('ok', false, 'code', 'E_SESSAO'); END IF;
  UPDATE public.table_sessions SET status='encerrada', closed_at=now(), closed_by='cliente' WHERE id = v_sid;
  DELETE FROM public.session_tokens WHERE session_id = v_sid;
  RETURN json_build_object('ok', true);
EXCEPTION WHEN others THEN RETURN json_build_object('ok', false, 'code', 'E_SERVIDOR');
END $$;

-- e)
CREATE OR REPLACE FUNCTION public.create_order(p_token text, p_items jsonb, p_customer_name text, p_customer_note text, p_honeypot text, p_device_id text) RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_sid uuid; v_s public.table_sessions; v_tnum text; v_max int; v_cool int; v_el jsonb; v_item public.items;
        v_qty int; v_note text; v_bad uuid[] := '{}'; v_total numeric := 0; v_oid uuid; v_onum int; v_ptok uuid; v_iid uuid;
BEGIN
  IF coalesce(btrim(p_honeypot),'') <> '' THEN RETURN json_build_object('ok', true, 'order_number', null, 'public_token', null); END IF;
  PERFORM public.expire_sessions();
  v_sid := public._ts_session(p_token);
  IF v_sid IS NULL THEN RETURN json_build_object('ok', false, 'code', 'E_SESSAO'); END IF;
  IF public._ts_setting('ordering_enabled') = 'false' THEN RETURN json_build_object('ok', false, 'code', 'E_OFF'); END IF;
  v_max := coalesce(nullif(public._ts_setting('max_items_per_order'),'')::int, 30);
  v_cool := coalesce(nullif(public._ts_setting('order_cooldown_seconds'),'')::int, 60);
  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) < 1 OR jsonb_array_length(p_items) > v_max
     OR length(coalesce(p_customer_name,'')) > 40 OR length(coalesce(p_customer_note,'')) > 200 THEN
    RETURN json_build_object('ok', false, 'code', 'E_DADOS'); END IF;
  FOR v_el IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    BEGIN
      v_iid := (v_el->>'item_id')::uuid; v_qty := (v_el->>'quantity')::int;
    EXCEPTION WHEN others THEN RETURN json_build_object('ok', false, 'code', 'E_DADOS'); END;
    IF v_iid IS NULL OR v_qty IS NULL OR v_qty < 1 OR v_qty > 20 OR length(coalesce(v_el->>'note','')) > 120 THEN
      RETURN json_build_object('ok', false, 'code', 'E_DADOS'); END IF;
    SELECT * INTO v_item FROM public.items WHERE id = v_iid AND is_active AND coalesce(is_available, true);
    IF v_item.id IS NULL THEN v_bad := v_bad || v_iid; ELSE v_total := v_total + v_item.price * v_qty; END IF;
  END LOOP;
  IF array_length(v_bad,1) > 0 THEN RETURN json_build_object('ok', false, 'code', 'E_ITEM', 'item_ids', to_json(v_bad)); END IF;
  SELECT * INTO v_s FROM public.table_sessions WHERE id = v_sid FOR UPDATE;
  IF EXISTS (SELECT 1 FROM public.orders WHERE table_id = v_s.table_id AND created_at > now() - make_interval(secs => v_cool)) THEN
    RETURN json_build_object('ok', false, 'code', 'E_LIMITE'); END IF;
  SELECT number INTO v_tnum FROM public.restaurant_tables WHERE id = v_s.table_id;
  INSERT INTO public.orders(table_id, table_number, session_id, customer_name, customer_note, total, ip_hash, status)
  VALUES (v_s.table_id, v_tnum, v_sid, nullif(btrim(p_customer_name),''), nullif(btrim(p_customer_note),''), round(v_total,2), public._ts_device(p_device_id), 'novo')
  RETURNING id, order_number, public_token INTO v_oid, v_onum, v_ptok;
  INSERT INTO public.order_items(order_id, item_id, name_snapshot, price_snapshot, quantity, note)
  SELECT v_oid, i.id, i.name_pt, i.price, (e->>'quantity')::int, nullif(btrim(e->>'note'),'')
  FROM jsonb_array_elements(p_items) e JOIN public.items i ON i.id = (e->>'item_id')::uuid;
  UPDATE public.table_sessions SET last_activity_at = now() WHERE id = v_sid;
  RETURN json_build_object('ok', true, 'order_number', v_onum, 'public_token', v_ptok);
EXCEPTION WHEN others THEN RETURN json_build_object('ok', false, 'code', 'E_SERVIDOR');
END $$;

-- f)
CREATE OR REPLACE FUNCTION public.get_session_orders(p_token text) RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_sid uuid := public._ts_session(p_token); v_orders json; v_total numeric;
BEGIN
  IF v_sid IS NULL THEN RETURN json_build_object('ok', false, 'code', 'E_SESSAO'); END IF;
  SELECT coalesce(json_agg(json_build_object('order_number', o.order_number, 'status', o.status, 'created_at', o.created_at, 'total', o.total,
    'items', (SELECT coalesce(json_agg(json_build_object('name', oi.name_snapshot, 'quantity', oi.quantity, 'note', oi.note) ORDER BY oi.id), '[]'::json) FROM public.order_items oi WHERE oi.order_id = o.id))
    ORDER BY o.created_at), '[]'::json) INTO v_orders FROM public.orders o WHERE o.session_id = v_sid;
  SELECT coalesce(sum(total),0) INTO v_total FROM public.orders WHERE session_id = v_sid AND status <> 'cancelado';
  RETURN json_build_object('ok', true, 'orders', v_orders, 'total', v_total);
EXCEPTION WHEN others THEN RETURN json_build_object('ok', false, 'code', 'E_SERVIDOR');
END $$;

-- h)
CREATE OR REPLACE FUNCTION public.end_table_by_staff(p_table_id uuid) RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_sid uuid; v_p int;
BEGIN
  IF NOT public._ts_is_crew() THEN RETURN json_build_object('ok', false, 'code', 'E_PERMISSAO'); END IF;
  SELECT id INTO v_sid FROM public.table_sessions WHERE table_id = p_table_id AND status='aberta';
  IF v_sid IS NULL THEN RETURN json_build_object('ok', false, 'code', 'E_LIVRE'); END IF;
  SELECT count(*) INTO v_p FROM public.orders WHERE session_id = v_sid AND status IN ('novo','em_preparacao','pronto');
  UPDATE public.table_sessions SET status='encerrada', closed_at=now(), closed_by='staff' WHERE id = v_sid;
  DELETE FROM public.session_tokens WHERE session_id = v_sid;
  RETURN json_build_object('ok', true, 'pending_orders', v_p);
EXCEPTION WHEN others THEN RETURN json_build_object('ok', false, 'code', 'E_SERVIDOR');
END $$;

-- i)
CREATE OR REPLACE FUNCTION public.open_table_by_staff(p_table_id uuid, p_pin text) RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_sid uuid;
BEGIN
  IF NOT public._ts_is_crew() THEN RETURN json_build_object('ok', false, 'code', 'E_PERMISSAO'); END IF;
  IF p_pin IS NULL OR p_pin !~ '^\d{4}$' THEN RETURN json_build_object('ok', false, 'code', 'E_DADOS'); END IF;
  IF public._ts_pin_weak(p_pin) THEN RETURN json_build_object('ok', false, 'code', 'E_PIN_FRACO'); END IF;
  IF NOT EXISTS (SELECT 1 FROM public.restaurant_tables WHERE id = p_table_id) THEN RETURN json_build_object('ok', false, 'code', 'E_MESA'); END IF;
  PERFORM public.expire_sessions();
  BEGIN
    INSERT INTO public.table_sessions(table_id) VALUES (p_table_id) RETURNING id INTO v_sid;
  EXCEPTION WHEN unique_violation THEN RETURN json_build_object('ok', false, 'code', 'E_OCUPADA'); END;
  INSERT INTO public.table_session_secrets(session_id, pin_hash) VALUES (v_sid, extensions.crypt(p_pin, extensions.gen_salt('bf')));
  RETURN json_build_object('ok', true);
EXCEPTION WHEN others THEN RETURN json_build_object('ok', false, 'code', 'E_SERVIDOR');
END $$;

-- j)
CREATE OR REPLACE FUNCTION public.list_tables_status() RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v json;
BEGIN
  IF NOT public._ts_is_crew() THEN RETURN json_build_object('ok', false, 'code', 'E_PERMISSAO'); END IF;
  PERFORM public.expire_sessions();
  SELECT coalesce(json_agg(json_build_object(
    'table_id', t.id, 'number', t.number, 'label', t.label,
    'state', CASE WHEN s.id IS NULL THEN 'livre' ELSE 'ocupada' END,
    'session_id', s.id, 'opened_at', s.opened_at,
    'minutes_open', CASE WHEN s.id IS NULL THEN null ELSE floor(extract(epoch FROM now() - s.opened_at)/60)::int END,
    'orders_count', coalesce(oc.n,0), 'total', coalesce(oc.total,0),
    'locked', coalesce(s.locked_until > now(), false),
    'empty_minutes', CASE WHEN s.id IS NOT NULL AND coalesce(oc.n,0) = 0 THEN floor(extract(epoch FROM now() - s.last_activity_at)/60)::int END
  ) ORDER BY t.sort_order, t.number), '[]'::json) INTO v
  FROM public.restaurant_tables t
  LEFT JOIN public.table_sessions s ON s.table_id = t.id AND s.status = 'aberta'
  LEFT JOIN LATERAL (SELECT count(*) n, sum(total) FILTER (WHERE status <> 'cancelado') total FROM public.orders o WHERE o.session_id = s.id) oc ON true
  WHERE t.is_active;
  RETURN json_build_object('ok', true, 'tables', v);
EXCEPTION WHEN others THEN RETURN json_build_object('ok', false, 'code', 'E_SERVIDOR');
END $$;

-- k)
CREATE OR REPLACE FUNCTION public.rotate_table_key(p_table_id uuid) RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT (public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'editor')) THEN RETURN json_build_object('ok', false, 'code', 'E_PERMISSAO'); END IF;
  INSERT INTO public.table_keys(table_id, access_key, rotated_at) VALUES (p_table_id, encode(extensions.gen_random_bytes(12),'hex'), now())
  ON CONFLICT (table_id) DO UPDATE SET access_key = excluded.access_key, rotated_at = now();
  RETURN json_build_object('ok', true);
EXCEPTION WHEN others THEN RETURN json_build_object('ok', false, 'code', 'E_SERVIDOR');
END $$;
CREATE OR REPLACE FUNCTION public.rotate_all_table_keys() RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_n int;
BEGIN
  IF auth.uid() IS NULL OR NOT (public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'editor')) THEN RETURN json_build_object('ok', false, 'code', 'E_PERMISSAO'); END IF;
  INSERT INTO public.table_keys(table_id, access_key, rotated_at) SELECT id, encode(extensions.gen_random_bytes(12),'hex'), now() FROM public.restaurant_tables
  ON CONFLICT (table_id) DO UPDATE SET access_key = excluded.access_key, rotated_at = now();
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN json_build_object('ok', true, 'rotated', v_n);
EXCEPTION WHEN others THEN RETURN json_build_object('ok', false, 'code', 'E_SERVIDOR');
END $$;

-- grants
REVOKE EXECUTE ON FUNCTION public._ts_norm(text), public._ts_setting(text), public._ts_hash(text), public._ts_device(text), public._ts_table(text,text),
  public._ts_session(text), public._ts_new_token(uuid,text), public._ts_pin_weak(text), public._ts_is_crew(), public.expire_sessions(),
  public.get_table_state(text,text,text), public.open_table(text,text,text,text), public.join_table(text,text,text,text), public.end_table_by_client(text),
  public.create_order(text,jsonb,text,text,text,text), public.get_session_orders(text), public.end_table_by_staff(uuid), public.open_table_by_staff(uuid,text),
  public.list_tables_status(), public.rotate_table_key(uuid), public.rotate_all_table_keys() FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_table_state(text,text,text), public.open_table(text,text,text,text), public.join_table(text,text,text,text),
  public.end_table_by_client(text), public.create_order(text,jsonb,text,text,text,text), public.get_session_orders(text), public.get_order_status(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.end_table_by_staff(uuid), public.open_table_by_staff(uuid,text), public.list_tables_status(),
  public.rotate_table_key(uuid), public.rotate_all_table_keys() TO authenticated;

NOTIFY pgrst, 'reload schema';