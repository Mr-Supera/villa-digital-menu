import { supabase } from "@/integrations/supabase/client";
import { tableApi } from "@/lib/tableApi";

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
  session_token:string;
  device_id:string;
  items:{item_id:string;quantity:number;note?:string|null}[];
  customer_name?:string|null;
  customer_note?:string|null;
  honeypot?:string|null;
}) => {
  const result=await tableApi.createOrder({
    p_token:body.session_token,
    p_items:body.items.map(x=>({item_id:x.item_id,quantity:x.quantity,note:x.note??null})),
    p_customer_name:body.customer_name??null,
    p_customer_note:body.customer_note??null,
    p_honeypot:body.honeypot??null,
    p_device_id:body.device_id,
  });
  if(result?.ok===false||result?.code){
    const e=new Error(String(result.code||"E_SERVIDOR")) as Error&{code?:string;itemIds?:string[]};
    e.code=String(result.code||"E_SERVIDOR");
    e.itemIds=Array.isArray(result.item_ids)?result.item_ids:[];
    throw e;
  }
  if(!result?.order_number||!result?.public_token){
    const e=new Error("Resposta inválida do servidor.") as Error&{code?:string};e.code="E_SERVIDOR";throw e;
  }
  return result as {order_number:number;public_token:string};
};

export async function getOrderStatus(token:string){
  return tableApi.getOrderStatus({p_token:token}) as any;
}

export function formatOrderAge(createdAt:string, now=Date.now()){
  const minutes=Math.max(0,Math.floor((now-new Date(createdAt).getTime())/60000));
  if(minutes<1) return "agora";
  return "há "+minutes+" min";
}
