import { queryOptions } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";

export type Section = "restaurante" | "bebidas";

export type Category = {
  id: string;
  section: Section;
  parent_id: string | null;
  name_pt: string;
  name_en: string | null;
  icon: string | null;
  sort_order: number;
  is_active: boolean;
};

export type Item = {
  id: string;
  category_id: string;
  name_pt: string;
  name_en: string | null;
  description_pt: string | null;
  description_en: string | null;
  price: number;
  image_url: string | null;
  is_available: boolean;
  is_active: boolean;
  is_featured: boolean;
  sort_order: number;
};

export type Settings = Record<string, string>;

export const categoriesQuery = (all = false) =>
  queryOptions({
    queryKey: ["categories", all],
    staleTime: 5 * 60 * 1000,
    queryFn: async (): Promise<Category[]> => {
      let q = supabase.from("categories").select("*").order("sort_order");
      if (!all) q = q.eq("is_active", true);
      const { data, error } = await q;
      if (error) throw error;
      return (data ?? []) as Category[];
    },
  });

export const itemsQuery = (all = false) =>
  queryOptions({
    queryKey: ["items", all],
    staleTime: 5 * 60 * 1000,
    queryFn: async (): Promise<Item[]> => {
      let q = supabase.from("items").select("*").order("sort_order");
      if (!all) q = q.eq("is_active", true);
      const { data, error } = await q;
      if (error) throw error;
      return (data ?? []).map((i) => ({ ...i, price: Number(i.price) })) as Item[];
    },
  });

export const settingsQuery = (all = false) =>
  queryOptions({
    queryKey: ["settings", all],
    staleTime: 5 * 60 * 1000,
    queryFn: async (): Promise<Settings> => {
      const { data, error } = await supabase.from("settings").select("key, value");
      if (error) throw error;
      const out: Settings = {};
      for (const row of data ?? []) out[row.key] = row.value ?? "";
      return out;
    },
  });

/** Constrói o URL de leitura de uma imagem do bucket privado "menu-images". */
export async function signedImageUrl(path: string): Promise<string | null> {
  const { getSignedImageUrl } = await import("@/lib/images.functions");
  const { url } = await getSignedImageUrl({ data: { path } });
  return url;
}
