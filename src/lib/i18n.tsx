import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from "react";

export type Lang = "pt" | "en";

const dict = {
  pt: {
    restaurant: "Restaurante",
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
    restaurant: "Restaurant",
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

/** Escolhe o texto no idioma activo, com fallback para português. */
export function pick(lang: Lang, pt: string | null, en: string | null): string {
  if (lang === "en") return (en && en.trim()) || pt || "";
  return pt || en || "";
}
