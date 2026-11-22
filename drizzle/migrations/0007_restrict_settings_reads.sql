DROP POLICY IF EXISTS "public reads settings" ON public.settings;
CREATE POLICY "public reads settings" ON public.settings FOR SELECT TO anon USING (is_public);
DROP POLICY IF EXISTS "auth reads settings" ON public.settings;
CREATE POLICY "auth reads settings" ON public.settings FOR SELECT TO authenticated USING (is_public OR has_role(auth.uid(), 'admin'::app_role));