import { supabase } from "@/integrations/supabase/client";

export type RestaurantTable = { id:string; number:string; label:string|null; is_active:boolean; sort_order:number };
export type CartLine = { itemId:string; quantity:number; note:string };
export type OrderStatus = "novo"|"em_preparacao"|"pronto"|"entregue"|"cancelado";

export const tablesQuery = () => ({
  queryKey:["restaurant-tables"],
  staleTime:5*60*1000,
  queryFn:async():Promise<RestaurantTable[]> => {
    const {data,error}=await supabase.from("restaurant_tables").select("id,number,label,is_active,sort_order").eq("is_active",true).order("sort_order").order("number");
    if(error) throw error;
    return (data??[]) as RestaurantTable[];
  },
});

export const ordersQuery = () => ({
  queryKey:["orders"],
  staleTime:5*1000,
  queryFn:async()=> {
    const {data,error}=await (supabase.from("orders") as any).select("*, order_items(*)").order("created_at",{ascending:false});
    if(error) throw error;
    return (data??[]) as any[];
  },
});

export const createOrder = async (body:{
  table_number:string;
  items:{item_id:string;quantity:number;note?:string|null}[];
  customer_name?:string|null;
  customer_note?:string|null;
  honeypot?:string;
}) => {
  const {data,error}=await supabase.functions.invoke("create-order",{body});
  if(error) throw error;
  if(data?.error) throw new Error(data.error);
  return data as {order_number:number;public_token:string};
};

export async function getOrderStatus(token:string){
  const {data,error}=await (supabase.rpc as any)("get_order_status",{p_token:token});
  if(error) throw error;
  return data as {order_number:number;status:OrderStatus;table_number:string;created_at:string;items:{name:string;quantity:number}[]}|null;
}

export function formatOrderAge(createdAt:string, now=Date.now()){
  const minutes=Math.max(0,Math.floor((now-new Date(createdAt).getTime())/60000));
  if(minutes<1) return "agora";
  return "há "+minutes+" min";
}
