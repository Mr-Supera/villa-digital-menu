import { supabase } from "@/integrations/supabase/client";

export type OrderingStatus = {
  enabled: boolean;
  updated_by_email: string | null;
  updated_at: string | null;
};

export async function getOrderingStatus(): Promise<OrderingStatus> {
  const { data, error } = await (supabase.rpc as any)("get_ordering_status");
  if (error) throw error;
  return (data ?? { enabled: true, updated_by_email: null, updated_at: null }) as OrderingStatus;
}

export async function setOrderingEnabled(enabled: boolean): Promise<boolean> {
  const { data, error } = await (supabase.rpc as any)("set_ordering_enabled", { p_enabled: enabled });
  if (error) throw error;
  return Boolean(data);
}
