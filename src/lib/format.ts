/** Formata um valor em Meticais: 1.500,00 MT */
export function formatPrice(value: number | string | null | undefined): string {
  const n = typeof value === "string" ? Number(value) : (value ?? 0);
  const safe = Number.isFinite(n) ? n : 0;
  const [int, dec] = safe.toFixed(2).split(".");
  const withDots = int.replace(/\B(?=(\d{3})+(?!\d))/g, ".");
  return `${withDots},${dec} MT`;
}

/** Remove acentos e passa a minúsculas, para pesquisa tolerante. */
export function normalize(text: string): string {
  return text
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim();
}
