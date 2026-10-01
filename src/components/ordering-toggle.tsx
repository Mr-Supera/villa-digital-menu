import { useEffect, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Power } from "lucide-react";
import { toast } from "sonner";
import { getOrderingStatus, setOrderingEnabled } from "@/lib/ordering";
import { useLang } from "@/lib/i18n";

export function OrderingToggle({ compact = false }: { compact?: boolean }) {
  const { lang } = useLang();
  const qc = useQueryClient();
  const q = useQuery({
    queryKey: ["ordering-status"],
    queryFn: getOrderingStatus,
    staleTime: 5_000,
    refetchInterval: 15_000,
    refetchOnWindowFocus: true,
  });
  const [saving, setSaving] = useState(false);
  const enabled = q.data?.enabled ?? true;

  useEffect(() => {
    const refresh = () => { void q.refetch(); };
    window.addEventListener("focus", refresh);
    return () => window.removeEventListener("focus", refresh);
  }, [q.refetch]);

  const toggle = async () => {
    const next = !enabled;
    if (!next) {
      const ok = window.confirm(
        lang === "en"
          ? "Turn off table ordering? Customers will no longer be able to place new orders. Orders already sent will remain in the panel."
          : "Desligar os pedidos pela mesa? Os clientes deixam de poder fazer novos pedidos. Os pedidos já enviados continuam no painel."
      );
      if (!ok) return;
    }

    const previous = q.data;
    qc.setQueryData(["ordering-status"], { ...(previous ?? { updated_by_email: null, updated_at: null }), enabled: next });
    setSaving(true);
    try {
      await setOrderingEnabled(next);
      await q.refetch();
      toast.success(next ? (lang === "en" ? "Orders enabled" : "Pedidos ligados") : (lang === "en" ? "Orders disabled" : "Pedidos desligados"));
    } catch (error: any) {
      qc.setQueryData(["ordering-status"], previous);
      toast.error(error?.message || (lang === "en" ? "Could not change table ordering." : "Não foi possível alterar os pedidos pela mesa."));
    } finally {
      setSaving(false);
    }
  };

  const statusText = enabled
    ? (lang === "en" ? "Table orders: ON" : "Pedidos pela mesa: LIGADOS")
    : (lang === "en" ? "Table orders: OFF" : "Pedidos pela mesa: DESLIGADOS");
  const changed = q.data?.updated_at
    ? new Date(q.data.updated_at).toLocaleString(lang === "en" ? "en-GB" : "pt-PT", { dateStyle: "short", timeStyle: "short" })
    : null;

  if (compact) {
    return (
      <button
        type="button"
        onClick={toggle}
        disabled={saving || q.isLoading}
        title={statusText}
        aria-label={statusText}
        className={"flex shrink-0 items-center gap-1.5 rounded-lg border px-2 py-1.5 text-xs font-semibold transition-opacity disabled:opacity-60 " + (enabled ? "border-green-700/30 bg-green-700/10 text-green-800" : "border-destructive/30 bg-destructive/10 text-destructive")}
      >
        <Power className="h-3.5 w-3.5" />
        <span>{enabled ? (lang === "en" ? "Orders ON" : "Pedidos ON") : (lang === "en" ? "Orders OFF" : "Pedidos OFF")}</span>
      </button>
    );
  }

  return (
    <div className="rounded-xl border bg-card p-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex min-w-0 items-center gap-3">
          <button
            type="button"
            role="switch"
            aria-checked={enabled}
            onClick={toggle}
            disabled={saving || q.isLoading}
            className={"relative h-10 w-20 shrink-0 rounded-full border-2 p-1 transition-colors disabled:opacity-60 " + (enabled ? "border-green-700 bg-green-700" : "border-destructive bg-destructive")}
          >
            <span className={"block h-7 w-7 rounded-full bg-cream shadow-sm transition-transform " + (enabled ? "translate-x-10" : "translate-x-0")} />
          </button>
          <div>
            <div className={"inline-flex rounded-full px-3 py-1 text-sm font-bold " + (enabled ? "bg-green-700/10 text-green-800" : "bg-destructive/10 text-destructive")}>{statusText}</div>
            {changed && <p className="mt-1 text-xs text-muted-foreground">{lang === "en" ? "Changed by" : "Alterado por"} {q.data?.updated_by_email || "—"} {lang === "en" ? "at" : "às"} {changed}</p>}
          </div>
        </div>
      </div>
    </div>
  );
}
