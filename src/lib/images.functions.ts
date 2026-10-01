import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";

// Gera URLs assinados para imagens do bucket privado "menu-images".
// Corre no servidor com o cliente admin, pelo que o bucket pode permanecer
// privado sem qualquer política de leitura anónima em storage.objects.
export const getSignedImageUrl = createServerFn({ method: "POST" })
  .inputValidator((data) => z.object({ path: z.string().min(1).max(500) }).parse(data))
  .handler(async ({ data }) => {
    if (data.path.includes("..")) return { url: null };
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { data: signed } = await supabaseAdmin.storage
      .from("menu-images")
      .createSignedUrl(data.path, 60 * 60 * 24);
    return { url: signed?.signedUrl ?? null };
  });
