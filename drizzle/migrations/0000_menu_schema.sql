-- Roles
CREATE TYPE public.app_role AS ENUM ('admin', 'editor');

CREATE TABLE public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role public.app_role NOT NULL,
  email text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

CREATE OR REPLACE FUNCTION public.is_staff(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role IN ('admin','editor'))
$$;

CREATE POLICY "read own roles" ON public.user_roles FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.has_role(auth.uid(), 'admin'));
CREATE POLICY "admins manage roles" ON public.user_roles FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

-- Categories
CREATE TABLE public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section text NOT NULL CHECK (section IN ('restaurante','bebidas')),
  parent_id uuid REFERENCES public.categories(id) ON DELETE CASCADE,
  name_pt text NOT NULL,
  name_en text,
  icon text,
  sort_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.categories TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.categories TO authenticated;
GRANT ALL ON public.categories TO service_role;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads active categories" ON public.categories FOR SELECT TO anon USING (is_active);
CREATE POLICY "staff reads all categories" ON public.categories FOR SELECT TO authenticated
  USING (is_active OR public.is_staff(auth.uid()));
CREATE POLICY "staff writes categories" ON public.categories FOR INSERT TO authenticated
  WITH CHECK (public.is_staff(auth.uid()));
CREATE POLICY "staff updates categories" ON public.categories FOR UPDATE TO authenticated
  USING (public.is_staff(auth.uid())) WITH CHECK (public.is_staff(auth.uid()));
CREATE POLICY "staff deletes categories" ON public.categories FOR DELETE TO authenticated
  USING (public.is_staff(auth.uid()));

-- Items
CREATE TABLE public.items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  name_pt text NOT NULL,
  name_en text,
  description_pt text,
  description_en text,
  price numeric(10,2) NOT NULL DEFAULT 0,
  image_url text,
  is_available boolean NOT NULL DEFAULT true,
  is_active boolean NOT NULL DEFAULT true,
  is_featured boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX items_category_idx ON public.items(category_id);
GRANT SELECT ON public.items TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.items TO authenticated;
GRANT ALL ON public.items TO service_role;
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads active items" ON public.items FOR SELECT TO anon USING (is_active);
CREATE POLICY "staff reads all items" ON public.items FOR SELECT TO authenticated
  USING (is_active OR public.is_staff(auth.uid()));
CREATE POLICY "staff inserts items" ON public.items FOR INSERT TO authenticated
  WITH CHECK (public.is_staff(auth.uid()));
CREATE POLICY "staff updates items" ON public.items FOR UPDATE TO authenticated
  USING (public.is_staff(auth.uid())) WITH CHECK (public.is_staff(auth.uid()));
CREATE POLICY "staff deletes items" ON public.items FOR DELETE TO authenticated
  USING (public.is_staff(auth.uid()));

-- Price history
CREATE TABLE public.price_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id uuid REFERENCES public.items(id) ON DELETE SET NULL,
  item_name text,
  old_price numeric(10,2),
  new_price numeric(10,2),
  changed_by uuid,
  changed_by_email text,
  changed_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT ON public.price_history TO authenticated;
GRANT ALL ON public.price_history TO service_role;
ALTER TABLE public.price_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "staff reads price history" ON public.price_history FOR SELECT TO authenticated
  USING (public.is_staff(auth.uid()));
CREATE POLICY "staff inserts price history" ON public.price_history FOR INSERT TO authenticated
  WITH CHECK (public.is_staff(auth.uid()));

-- Settings
CREATE TABLE public.settings (
  key text PRIMARY KEY,
  value text,
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.settings TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.settings TO authenticated;
GRANT ALL ON public.settings TO service_role;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads settings" ON public.settings FOR SELECT TO anon USING (true);
CREATE POLICY "auth reads settings" ON public.settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "admins write settings" ON public.settings FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

-- Price change logging trigger
CREATE OR REPLACE FUNCTION public.log_price_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  NEW.updated_at = now();
  IF TG_OP = 'UPDATE' AND NEW.price IS DISTINCT FROM OLD.price THEN
    INSERT INTO public.price_history (item_id, item_name, old_price, new_price, changed_by, changed_by_email)
    VALUES (NEW.id, NEW.name_pt, OLD.price, NEW.price, auth.uid(),
            (SELECT email FROM auth.users WHERE id = auth.uid()));
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER items_price_change BEFORE UPDATE ON public.items
FOR EACH ROW EXECUTE FUNCTION public.log_price_change();

-- First-admin bootstrap
CREATE OR REPLACE FUNCTION public.admin_exists()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE role = 'admin')
$$;
GRANT EXECUTE ON FUNCTION public.admin_exists() TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.claim_first_admin()
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN RETURN false; END IF;
  IF EXISTS (SELECT 1 FROM public.user_roles WHERE role = 'admin') THEN RETURN false; END IF;
  INSERT INTO public.user_roles (user_id, role, email)
  VALUES (uid, 'admin', (SELECT email FROM auth.users WHERE id = uid))
  ON CONFLICT DO NOTHING;
  RETURN true;
END;
$$;
GRANT EXECUTE ON FUNCTION public.claim_first_admin() TO authenticated;

INSERT INTO public.settings (key, value) VALUES
  ('restaurant_name', 'Villa das Palmeiras'),
  ('logo_url', ''),
  ('phone', '+258 85 202 1633'),
  ('whatsapp', '258852021633'),
  ('instagram', 'grupovilladaspalmeiras'),
  ('address', 'Katembe-Khaelisa, Maputo'),
  ('footer_text', 'Preços em Meticais (MT)');
