import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useRef, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Clock3, Printer, Volume2, VolumeX } from "lucide-react";
import { AdminShell } from "@/components/admin";
import { OrderingToggle } from "@/components/ordering-toggle";
import { getOrderingStatus } from "@/lib/ordering";
import { ordersQuery, formatOrderAge, type OrderStatus } from "@/lib/orders";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";

export const Route=createFileRoute("/admin/pedidos")({component:OrdersPage});

const columns:OrderStatus[]=["novo","em_preparacao","pronto"];
const localDate=(d:Date|string)=>new Date(d).toLocaleDateString("en-CA");
const label=(s:OrderStatus)=>({novo:"Novos",em_preparacao:"Em preparação",pronto:"Prontos",entregue:"Entregues",cancelado:"Cancelados"}[s]);

function OrdersPage(){
  const q=useQuery({...ordersQuery(),refetchInterval:10000,refetchOnWindowFocus:true}),qc=useQueryClient();
  const ordering=useQuery({queryKey:["ordering-status"],queryFn:getOrderingStatus,staleTime:5000,refetchInterval:15000,refetchOnWindowFocus:true});
  const orders=q.data??[];
  const [tab,setTab]=useState<OrderStatus>("novo");
  const [sound,setSound]=useState(false),[realtime,setRealtime]=useState(true),[printId,setPrintId]=useState<string|null>(null);
  const audioRef=useRef<AudioContext|null>(null),wakeRef=useRef<any>(null);
  const [historyDate,setHistoryDate]=useState(localDate(new Date())),[historyTable,setHistoryTable]=useState("");

  useEffect(()=>{
    let channel:any;
    const connect=()=>{
      channel=supabase.channel("orders-live")
        .on("postgres_changes",{event:"*",schema:"public",table:"orders"},()=>{qc.invalidateQueries({queryKey:["orders"]});qc.invalidateQueries({queryKey:["admin-new-orders"]})})
        .on("postgres_changes",{event:"*",schema:"public",table:"order_items"},()=>{qc.invalidateQueries({queryKey:["orders"]})})
        .subscribe((status:string)=>setRealtime(status==="SUBSCRIBED"));
    };
    connect();
    const fallback=window.setInterval(()=>{qc.invalidateQueries({queryKey:["orders"]});},10000);
    return()=>{window.clearInterval(fallback);if(channel)supabase.removeChannel(channel)};
  },[qc]);

  useEffect(()=>{const count=orders.filter(o=>o.status==="novo"&&!o.seen_at).length;document.title=(count?"("+count+") ":"")+"Pedidos | Villa das Palmeiras";return()=>{document.title="Menu | Villa das Palmeiras"}},[orders]);
  useEffect(()=>{if(!("wakeLock" in navigator))return;let active=true;const request=async()=>{try{if(active)wakeRef.current=await (navigator as any).wakeLock.request("screen")}catch{}};request();return()=>{active=false;wakeRef.current?.release?.()}},[]);
  useEffect(()=>{if(!printId)return;const id=window.setTimeout(()=>window.print(),80);const done=()=>setPrintId(null);window.addEventListener("afterprint",done);return()=>{window.clearTimeout(id);window.removeEventListener("afterprint",done)}},[printId]);

  const enableSound=async()=>{try{const Ctx=window.AudioContext||(window as any).webkitAudioContext;audioRef.current=audioRef.current||new Ctx();await audioRef.current.resume();setSound(true);beep(audioRef.current)}catch{toast.error("O browser não permite activar o som.")}};
  const beep=(ctx:AudioContext)=>{try{const o=ctx.createOscillator(),g=ctx.createGain();o.frequency.value=880;g.gain.value=.06;o.connect(g);g.connect(ctx.destination);o.start();o.stop(ctx.currentTime+.18)}catch{}};
  useEffect(()=>{if(!sound)return;const channel=supabase.channel("orders-sound").on("postgres_changes",{event:"INSERT",schema:"public",table:"orders"},()=>{if(audioRef.current)beep(audioRef.current)}).subscribe();return()=>{supabase.removeChannel(channel)}},[sound]);

  const updateStatus=async(order:any,next:OrderStatus)=>{
    const {error}=await supabase.from("orders").update({status:next,updated_at:new Date().toISOString()}).eq("id",order.id);
    if(error)toast.error(error.message);else{toast.success("Estado actualizado.");qc.invalidateQueries({queryKey:["orders"]});qc.invalidateQueries({queryKey:["admin-new-orders"]})}
  };
  const markSeen=async(order:any)=>{if(order.seen_at)return;await supabase.from("orders").update({seen_at:new Date().toISOString()}).eq("id",order.id);qc.invalidateQueries({queryKey:["orders"]});qc.invalidateQueries({queryKey:["admin-new-orders"]})};
  const cancel=async(order:any)=>{if(!confirm("Cancelar este pedido?"))return;await updateStatus(order,"cancelado")};
  const next=(s:OrderStatus):OrderStatus|null=>s==="novo"?"em_preparacao":s==="em_preparacao"?"pronto":s==="pronto"?"entregue":null;

  const history=orders.filter(o=>(o.status==="entregue"||o.status==="cancelado")&&localDate(o.created_at)===historyDate&&(!historyTable||o.table_number===historyTable));
  const sold=history.filter(o=>o.status==="entregue").reduce((n,o)=>n+Number(o.total),0);
  const tables=[...new Set(orders.map(o=>o.table_number))].sort();

  const receipt=printId?orders.find(o=>o.id===printId):null;
  return <AdminShell ordersOnly>
    {q.error&&<div className="mb-4 flex flex-wrap items-center justify-between gap-3 rounded-lg border border-destructive/40 bg-destructive/10 px-3 py-3 text-sm text-destructive"><span>Sem permissão para ver pedidos. {q.error instanceof Error?q.error.message:"Não foi possível carregar os pedidos."}</span><button onClick={()=>q.refetch()} className="rounded-lg border border-destructive/40 px-3 py-1.5 font-semibold">Tentar de novo</button></div>}
    <div className="flex flex-wrap items-center justify-between gap-3"><div><h1 className="text-3xl font-bold text-forest">Pedidos</h1><p className="mt-1 text-sm text-muted-foreground">{realtime?"Ligado em tempo real":"Sem ligação em tempo real — actualização automática activa"}</p></div><div className="flex flex-wrap items-center gap-2"><OrderingToggle/>{!sound&&<button onClick={enableSound} className="rounded-lg bg-forest px-3 py-2 text-sm font-semibold text-cream"><Volume2 className="mr-1 inline h-4 w-4"/>Activar som</button>}{sound&&<button onClick={()=>setSound(false)} className="rounded-lg border px-3 py-2 text-sm"><VolumeX className="mr-1 inline h-4 w-4"/>Silenciar</button>}{!realtime&&<span className="rounded-lg border border-destructive/40 bg-destructive/5 px-3 py-2 text-sm text-destructive">Sem ligação em tempo real</span>}</div></div>
    {ordering.data?.enabled===false&&<div className="mt-4 rounded-lg border border-destructive/40 bg-destructive/10 px-3 py-2 text-sm font-semibold text-destructive">Os pedidos pela mesa estão desligados. Os clientes não podem fazer pedidos.</div>}
    <div className="mt-5 grid grid-cols-3 gap-1 rounded-xl border bg-card p-1 md:hidden">{columns.map(s=><button key={s} onClick={()=>setTab(s)} className={"rounded-lg px-2 py-2 text-xs font-semibold "+(tab===s?"bg-forest text-cream":"text-forest")}>{label(s)} <span className="ml-1 rounded-full bg-gold/20 px-1.5">{orders.filter(o=>o.status===s).length}</span></button>)}</div>
    <div className="mt-4 grid gap-4 md:grid-cols-3">{columns.map(s=><section key={s} className={(tab===s?"block":"hidden")+" md:block"}><div className="mb-2 flex items-center justify-between"><h2 className="text-xl font-bold text-forest">{label(s)}</h2><span className="rounded-full bg-gold/20 px-2 py-1 text-xs font-semibold">{orders.filter(o=>o.status===s).length}</span></div><div className="space-y-3">{orders.filter(o=>o.status===s).map(order=><OrderCard key={order.id} order={order} onSeen={markSeen} onNext={updateStatus} onCancel={cancel} onPrint={setPrintId} next={next(order.status)}/>)}</div></section>)}</div>
    <section className="mt-10 border-t pt-6"><div className="flex flex-wrap items-end gap-3"><div><h2 className="text-2xl font-bold text-forest">Histórico</h2><label className="mt-2 block text-sm">Data<input type="date" value={historyDate} onChange={e=>setHistoryDate(e.target.value)} className="mt-1 rounded border bg-card px-3 py-2"/></label></div><label className="text-sm">Mesa<select value={historyTable} onChange={e=>setHistoryTable(e.target.value)} className="mt-1 rounded border bg-card px-3 py-2"><option value="">Todas</option>{tables.map(t=><option key={t} value={t}>{t}</option>)}</select></label><div className="rounded-xl border bg-card px-4 py-3"><div className="text-xs text-muted-foreground">Total vendido</div><div className="text-xl font-bold text-forest">{sold.toLocaleString("pt-PT",{minimumFractionDigits:2})} MT</div></div></div><div className="mt-4 space-y-2">{history.map(o=><div key={o.id} className="flex flex-wrap items-center justify-between gap-2 rounded-lg border bg-card p-3 text-sm"><span><b>#{o.order_number}</b> · Mesa {o.table_number} · {new Date(o.created_at).toLocaleTimeString("pt-PT",{hour:"2-digit",minute:"2-digit"})}</span><span>{o.status==="entregue"?"Entregue":"Cancelado"} · {Number(o.total).toLocaleString("pt-PT",{minimumFractionDigits:2})} MT</span></div>)}{history.length===0&&<p className="py-5 text-sm text-muted-foreground">Sem pedidos neste filtro.</p>}</div></section>
    <div id="order-receipt-print">{receipt&&<><h1>VILLA DAS PALMEIRAS</h1><h2>Pedido #{receipt.order_number}</h2><p>Mesa: {receipt.table_number}</p><p>{new Date(receipt.created_at).toLocaleString("pt-PT")}</p><hr/>{(receipt.order_items||[]).map((x:any)=><div key={x.id}>{x.quantity} x {x.name_snapshot}{x.note?" — "+x.note:""}<br/>{(Number(x.price_snapshot)*x.quantity).toLocaleString("pt-PT",{minimumFractionDigits:2})} MT</div>)}<hr/><b>Total: {Number(receipt.total).toLocaleString("pt-PT",{minimumFractionDigits:2})} MT</b>{receipt.customer_name&&<p>Cliente: {receipt.customer_name}</p>}{receipt.customer_note&&<p>Obs.: {receipt.customer_note}</p>}</>}</div>
    <style>{`#order-receipt-print{display:none}@media print{body *{visibility:hidden!important}#order-receipt-print,#order-receipt-print *{visibility:visible!important}#order-receipt-print{display:block!important;position:absolute;left:0;top:0;width:80mm;padding:4mm;font-family:monospace;font-size:11px;color:#000}#order-receipt-print h1,#order-receipt-print h2{font-size:14px;margin:0 0 3mm}}`}</style>
  </AdminShell>
}

function OrderCard({order,onSeen,onNext,onCancel,onPrint,next}:{order:any;onSeen:(o:any)=>void;onNext:(o:any,s:OrderStatus)=>void;onCancel:(o:any)=>void;onPrint:(id:string)=>void;next:OrderStatus|null}){
  const [now,setNow]=useState(Date.now());useEffect(()=>{const id=window.setInterval(()=>setNow(Date.now()),30000);return()=>window.clearInterval(id)},[]);
  const old=order.status==="novo"&&(now-new Date(order.created_at).getTime())>15*60000;
  return <article onPointerDown={()=>onSeen(order)} className={"rounded-xl border bg-card p-4 "+(!order.seen_at?"ring-2 ring-gold":"")}>
    <div className="flex items-start justify-between gap-3"><div><div className="text-2xl font-black text-forest">MESA {order.table_number}</div><div className="mt-1 flex items-center gap-2 text-xs text-muted-foreground"><Clock3 className="h-3.5 w-3.5"/>{new Date(order.created_at).toLocaleTimeString("pt-PT",{hour:"2-digit",minute:"2-digit"})} · <span className={old?"font-bold text-destructive":""}>{formatOrderAge(order.created_at,now)}</span></div></div><div className="text-right"><div className="font-bold">#{order.order_number}</div><div className="mt-1 text-sm font-semibold text-forest">{Number(order.total).toLocaleString("pt-PT",{minimumFractionDigits:2})} MT</div></div></div>
    <div className="mt-4 space-y-2 border-y py-3">{Array.isArray(order.order_items)&&order.order_items.length>0?order.order_items.map((x:any)=><div key={x.id} className="text-sm"><b>{x.quantity}×</b> {x.name_snapshot}{x.note&&<div className="ml-5 text-xs text-muted-foreground">Nota: {x.note}</div>}</div>):<div className="rounded-lg border border-destructive/30 bg-destructive/5 px-3 py-2 text-sm text-destructive">itens indisponíveis</div>}</div>
    {order.customer_name&&<p className="mt-3 text-sm"><b>Cliente:</b> {order.customer_name}</p>}{order.customer_note&&<p className="mt-1 text-sm"><b>Obs.:</b> {order.customer_note}</p>}
    <div className="mt-4 flex flex-wrap gap-2"><button disabled={!next} onClick={()=>next&&onNext(order,next)} className="flex-1 rounded-lg bg-forest px-3 py-2.5 text-sm font-semibold text-cream disabled:opacity-40">{next==="em_preparacao"?"Avançar: Em preparação":next==="pronto"?"Avançar: Pronto":next==="entregue"?"Marcar entregue":"Concluído"}</button><button onClick={()=>onCancel(order)} className="rounded-lg border border-destructive/40 px-3 py-2.5 text-sm text-destructive">Cancelar</button><button onClick={()=>onPrint(order.id)} className="rounded-lg border px-3 py-2.5 text-sm"><Printer className="mr-1 inline h-4 w-4"/>Imprimir</button></div>
  </article>
}