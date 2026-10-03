import { supabase } from "@/integrations/supabase/client";

export type TableApiErrorCode =
  | "E_CHAVE"
  | "E_OCUPADA"
  | "E_PIN_FRACO"
  | "E_PIN"
  | "E_BLOQUEADA"
  | "E_SESSAO"
  | "E_OFF"
  | "E_ITEM"
  | "E_LIMITE"
  | "E_DADOS"
  | "E_SERVIDOR"
  | "E_REDE";

export type TableApiError = Error & {
  code: TableApiErrorCode;
  attempts_left?: number;
  item_ids?: string[];
  rpc_code?: string;
};

function makeError(
  code: TableApiErrorCode,
  details?: { attempts_left?: unknown; item_ids?: unknown; rpc_code?: unknown; message?: string },
): TableApiError {
  const error = new Error(details?.message || code) as TableApiError;
  error.code = code;
  if (Number.isFinite(Number(details?.attempts_left))) {
    error.attempts_left = Number(details?.attempts_left);
  }
  if (Array.isArray(details?.item_ids)) {
    error.item_ids = details.item_ids.filter((id): id is string => typeof id === "string");
  }
  if (typeof details?.rpc_code === "string") {
    error.rpc_code = details.rpc_code;
  }
  return error;
}

function normalizeCode(value: unknown): TableApiErrorCode {
  const code = String(value || "");
  const allowed: TableApiErrorCode[] = [
    "E_CHAVE",
    "E_OCUPADA",
    "E_PIN_FRACO",
    "E_PIN",
    "E_BLOQUEADA",
    "E_SESSAO",
    "E_OFF",
    "E_ITEM",
    "E_LIMITE",
    "E_DADOS",
    "E_SERVIDOR",
    "E_REDE",
  ];
  return (allowed.includes(code as TableApiErrorCode) ? code : "E_SERVIDOR") as TableApiErrorCode;
}

async function rpc<T extends Record<string, any> = Record<string, any>>(
  name: string,
  args: Record<string, unknown> = {},
): Promise<T> {
  const { data, error } = await (supabase.rpc as any)(name, args);

  if (error) {
    const rpcCode = String((error as any).code || "");
    const message = String((error as any).message || "");

    // PGRST202 = function/signature not exposed by PostgREST.
    if (rpcCode === "PGRST202" || /PGRST202/i.test(message)) {
      throw makeError("E_REDE", { rpc_code: rpcCode || "PGRST202", message });
    }

    throw makeError(normalizeCode((error as any).details?.code || rpcCode), {
      rpc_code: rpcCode,
      message,
    });
  }

  const result = (data ?? {}) as T;

  if (result && result['ok'] === false) {
    throw makeError(normalizeCode(result['code']), {
      attempts_left: result['attempts_left'],
      item_ids: result['item_ids'],
      message: typeof result['message'] === "string" ? result['message'] : undefined,
    });
  }

  return result;
}

export const tableApi = {
  getTableState: (args: { p_table: string; p_key: string; p_token?: string | null }) =>
    rpc("get_table_state", args),

  openTable: (args: { p_table: string; p_key: string; p_pin: string; p_device_id: string }) =>
    rpc("open_table", args),

  joinTable: (args: { p_table: string; p_key: string; p_pin: string; p_device_id: string }) =>
    rpc("join_table", args),

  endTableByClient: (args: { p_token: string }) =>
    rpc("end_table_by_client", args),

  createOrder: (args: {
    p_token: string;
    p_items: { item_id: string; quantity: number; note: string | null }[];
    p_customer_name: string | null;
    p_customer_note: string | null;
    p_honeypot: string | null;
    p_device_id: string;
  }) => rpc("create_order", args),

  getSessionOrders: (args: { p_token: string }) =>
    rpc("get_session_orders", args),

  getOrderStatus: (args: { p_token: string }) =>
    rpc("get_order_status", args),

  listTablesStatus: () =>
    rpc("list_tables_status"),

  endTableByStaff: (args: { p_table_id: string }) =>
    rpc("end_table_by_staff", args),

  openTableByStaff: (args: { p_table_id: string; p_pin: string }) =>
    rpc("open_table_by_staff", args),

  rotateTableKey: (args: { p_table_id: string }) =>
    rpc("rotate_table_key", args),

  rotateAllTableKeys: () =>
    rpc("rotate_all_table_keys"),
};
