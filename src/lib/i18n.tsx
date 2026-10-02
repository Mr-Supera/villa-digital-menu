import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from "react";

export type Lang = "pt" | "en";

const dict = {
  pt: {
    restaurant: "Refeições",
    drinks: "Bebidas",
    search: "Pesquisar pratos e bebidas...",
    noResults: "Nada encontrado.",
    soldOut: "Esgotado",
    prices: "Preços em Meticais (MT)",
    top: "Voltar ao topo",
    menu: "Menu",
    loading: "A carregar...",
    close: "Fechar",
  },
  en: {
    restaurant: "Meals",
    drinks: "Drinks",
    search: "Search dishes and drinks...",
    noResults: "Nothing found.",
    soldOut: "Sold out",
    prices: "Prices in Meticais (MT)",
    top: "Back to top",
    menu: "Menu",
    loading: "Loading...",
    close: "Close",
  },
} as const;

type Key = keyof (typeof dict)["pt"];

const errorMessages: Record<string, { pt: string; en: string }> = {
  E_CHAVE: { pt: "Leia o QR code da sua mesa.", en: "Scan your table QR code." },
  E_OCUPADA: { pt: "Esta mesa já está aberta. Introduza o PIN.", en: "This table is already open. Enter the PIN." },
  E_PIN_FRACO: { pt: "PIN demasiado simples. Escolha outro.", en: "PIN is too simple. Choose another." },
  E_PIN: { pt: "PIN incorrecto. Restam {n} tentativas.", en: "Incorrect PIN. {n} attempts left." },
  E_BLOQUEADA: { pt: "Demasiadas tentativas. Chame o empregado.", en: "Too many attempts. Please call a staff member." },
  E_SESSAO: { pt: "A sua mesa foi encerrada. Leia o QR code outra vez.", en: "Your table session has ended. Scan the QR code again." },
  E_OFF: { pt: "Os pedidos pela mesa estão desligados. Por favor chame o empregado.", en: "Table ordering is turned off. Please call a staff member." },
  E_ITEM: { pt: "Algum prato já não está disponível. Reveja o seu pedido.", en: "An item is no longer available. Review your order." },
  E_LIMITE: { pt: "Aguarde um momento e tente de novo. Se continuar, chame o empregado.", en: "Please wait a moment and try again. If it continues, call a staff member." },
  E_REDE: { pt: "Não foi possível enviar. Tente de novo ou chame o empregado.", en: "Could not send. Try again or call a staff member." },
  E_DADOS: { pt: "Não foi possível enviar. Tente de novo ou chame o empregado.", en: "Could not send. Try again or call a staff member." },
  E_SERVIDOR: { pt: "Não foi possível enviar. Tente de novo ou chame o empregado.", en: "Could not send. Try again or call a staff member." },
};

const LangContext = createContext<{
  lang: Lang;
  setLang: (l: Lang) => void;
  t: (k: Key) => string;
}>({ lang: "pt", setLang: () => {}, t: (k) => dict.pt[k] });

export function LanguageProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>("pt");

  useEffect(() => {
    const stored = window.localStorage.getItem("vdp-lang");
    if (stored === "pt" || stored === "en") setLangState(stored);
  }, []);

  const setLang = useCallback((l: Lang) => {
    setLangState(l);
    window.localStorage.setItem("vdp-lang", l);
  }, []);

  const t = useCallback((k: Key) => dict[lang][k], [lang]);

  return <LangContext.Provider value={{ lang, setLang, t }}>{children}</LangContext.Provider>;
}

export function useLang() {
  return useContext(LangContext);
}

export function getLocalized(pt: string | null, en: string | null, lang: Lang): string {
  if (lang === "en") return (en && en.trim()) || (pt && pt.trim()) || "";
  return (pt && pt.trim()) || (en && en.trim()) || "";
}

export function pick(lang: Lang, pt: string | null, en: string | null): string {
  return getLocalized(pt, en, lang);
}

export function tableErrorMessage(lang: Lang, code: string, attemptsLeft?: number): string {
  const message = errorMessages[code] ?? errorMessages.E_SERVIDOR;
  return (lang === "en" ? message.en : message.pt).replace("{n}", String(attemptsLeft ?? 0));
}
