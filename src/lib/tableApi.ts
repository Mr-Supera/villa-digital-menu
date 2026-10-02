import { supabase } from "@/integrations/supabase/client";

type RpcResult<T> = { ok: boolean; code?: string; [key: string]: any } & T;

async function rpc<T = any>(name: string, args?: Record<string, unknown>): Promise<RpcResult<T>> {
  const { data, error } = await (supabase.rpc as any)(name, args ?? {});
  if (error) {
    const e = new Error(error.message || "RPC error") as Error & { code?: string };
    e.code = String((error as any).code || "E_SERVIDOR");
    throw e;
  }
  return data as RpcResult<T>;
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
  listTablesStatus: () => rpc("list_tables_status"),
  endTableByStaff: (args: { p_table_id: string }) =>
    rpc("end_table_by_staff", args),
  openTableByStaff: (args: { p_table_id: string; p_pin: string }) =>
    rpc("open_table_by_staff", args),
  rotateTableKey: (args: { p_table_id: string }) =>
    rpc("rotate_table_key", args),
  rotateAllTableKeys: () => rpc("rotate_all_table_keys"),
};
