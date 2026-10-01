import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.0";
import { z } from "https://esm.sh/zod@3.25.76";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-retry-count, traceparent, tracestate, baggage",
  "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
  "Content-Type": "application/json",
};

const ItemSchema = z.object({
  item_id: z.string().uuid(),
  quantity: z.number().int().min(1).max(20),
  note: z.string().max(120).optional().nullable(),
});
const BodySchema = z.object({
  table_number: z.string().min(1).max(40),
  items: z.array(ItemSchema).min(1),
  customer_name: z.string().max(40).optional().nullable(),
  customer_note: z.string().max(200).optional().nullable(),
  honeypot: z.string().optional().nullable(),
});

function clean(value: string | null | undefined, max: number) {
  return (value ?? "")
    .replace(/<[^>]*>/g, "")
    .replace(/[\u0000-\u001F\u007F]/g, "")
    .replace(/[<>]/g, "")
    .trim()
    .slice(0, max);
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: cors });
}

async function hashIp(ip: string, salt: string) {
  const bytes = new TextEncoder().encode(salt + ":" + ip);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest)).map(b => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "E_SERVIDOR", code: "E_SERVIDOR", message: "Pedido inválido." }, 405);

  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const configuredSalt = Deno.env.get("IP_HASH_SALT") || Deno.env.get("ORDER_RATE_LIMIT_SALT");
    const RATE_SALT = configuredSalt || SERVICE_ROLE;
    if (!configuredSalt) console.warn("IP_HASH_SALT is not configured; using the service-role key as the fallback salt.");
    if (!SUPABASE_URL || !SERVICE_ROLE) return json({ error: "E_SERVIDOR", code: "E_SERVIDOR", message: "Serviço indisponível." }, 503);

    const raw = await req.json();
    const parsed = BodySchema.safeParse(raw);
    if (!parsed.success) return json({ error: "E_SERVIDOR", code: "E_SERVIDOR", message: "Pedido inválido." }, 400);

    if (clean(parsed.data.honeypot, 200)) return json({ ok: true }, 200);

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const settingsResult = await supabase
      .from("settings")
      .select("key,value")
      .in("key", ["ordering_enabled", "max_items_per_order", "order_cooldown_seconds"]);
    if (settingsResult.error) throw settingsResult.error;
    const settings = Object.fromEntries((settingsResult.data ?? []).map((x: any) => [x.key, x.value ?? ""]));
    if (settings.ordering_enabled !== "true") return json({ error: "E_OFF", code: "E_OFF", message: "Os pedidos pela mesa estão desligados." }, 409);

    const maxItems = Math.max(1, Math.min(30, Number(settings.max_items_per_order) || 30));
    if (parsed.data.items.length > maxItems) return json({ error: "E_LIMITE", code: "E_LIMITE", message: "O pedido excede o limite permitido." }, 400);

    const tableNumber = clean(parsed.data.table_number, 40);
    const tableResult = await supabase
      .from("restaurant_tables")
      .select("id,number")
      .eq("is_active", true);
    if (tableResult.error) throw tableResult.error;
    const normalizedTable = tableNumber.trim().toLocaleLowerCase();
    const matchedTable = (tableResult.data ?? []).find((t: any) => String(t.number ?? "").trim().toLocaleLowerCase() === normalizedTable);
    if (!matchedTable) return json({ error: "E_MESA", code: "E_MESA", message: "Mesa não encontrada" }, 400);

    const itemIds = parsed.data.items.map(x => x.item_id);
    const itemResult = await supabase
      .from("items")
      .select("id,name_pt,price,is_active,is_available")
      .in("id", itemIds);
    if (itemResult.error) throw itemResult.error;

    const byId = new Map((itemResult.data ?? []).map((x: any) => [x.id, x]));
    const unavailableItemIds = parsed.data.items
      .filter(line => {
        const item: any = byId.get(line.item_id);
        return !item || !item.is_active || item.is_available === false;
      })
      .map(line => line.item_id);
    if (unavailableItemIds.length) return json({ error: "E_ITEM", code: "E_ITEM", message: "Algum prato já não está disponível.", item_ids: unavailableItemIds }, 409);

    const lines = parsed.data.items.map(line => {
      const item: any = byId.get(line.item_id);
      return {
        item_id: item.id,
        name_snapshot: item.name_pt,
        price_snapshot: Number(item.price),
        quantity: line.quantity,
        note: clean(line.note, 120) || null,
      };
    });

    const ipHeader = req.headers.get("x-forwarded-for") || req.headers.get("x-real-ip") || "unknown";
    const ip = ipHeader.split(",")[0].trim().slice(0, 200);
    const ipHash = await hashIp(ip, RATE_SALT);
    const now = Date.now();
    const cooldown = Math.max(0, Number(settings.order_cooldown_seconds) || 60);

    const [tableRecent, ipRecent] = await Promise.all([
      supabase.from("orders").select("id,created_at").eq("table_number", tableNumber)
        .gte("created_at", new Date(now - cooldown * 1000).toISOString()).limit(1),
      supabase.from("orders").select("id").eq("ip_hash", ipHash)
        .gte("created_at", new Date(now - 60 * 60 * 1000).toISOString()).limit(10),
    ]);
    if (tableRecent.error || ipRecent.error) throw tableRecent.error || ipRecent.error;
    if ((tableRecent.data ?? []).length > 0 || (ipRecent.data ?? []).length >= 10) {
      return json({ error: "Aguarde antes de enviar outro pedido." }, 429);
    }

    const total = Number(lines.reduce((sum, line) => sum + line.price_snapshot * line.quantity, 0).toFixed(2));
    const orderResult = await supabase.from("orders").insert({
      table_id: matchedTable.id,
      table_number: matchedTable.number,
      customer_name: clean(parsed.data.customer_name, 40) || null,
      customer_note: clean(parsed.data.customer_note, 200) || null,
      total,
      ip_hash: ipHash,
      status: "novo",
    }).select("id,order_number,public_token").single();
    if (orderResult.error || !orderResult.data) throw orderResult.error || new Error("ORDER_CREATE_FAILED");

    const itemInsert = await supabase.from("order_items").insert(
      lines.map(line => ({ ...line, order_id: orderResult.data.id }))
    );
    if (itemInsert.error) {
      await supabase.from("orders").delete().eq("id", orderResult.data.id);
      throw itemInsert.error;
    }

    return json({
      order_number: orderResult.data.order_number,
      public_token: orderResult.data.public_token,
    });
  } catch (error) {
    if (error instanceof Error && error.message === "ITEM_UNAVAILABLE") {
      return json({ error: "Um ou mais itens já não estão disponíveis." }, 409);
    }
    console.error(error);
    return json({ error: "E_SERVIDOR", code: "E_SERVIDOR", message: "Não foi possível criar o pedido." }, 500);
  }
});