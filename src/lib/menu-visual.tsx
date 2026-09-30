import type { LucideIcon } from "lucide-react";
import { Apple, Beer, Beef, Cake, ChefHat, Citrus, Coffee, CookingPot, CupSoda, Drumstick, Fish, Flame, GlassWater, Grape, IceCream2, Leaf, Martini, Pizza, Salad, Sandwich, Shell, Soup, Sparkles, Utensils, UtensilsCrossed, Wheat, Wine } from "lucide-react";

export const CATEGORY_ICONS: Record<string,[LucideIcon,LucideIcon]> = {
  "Entradas":[UtensilsCrossed,Utensils],"Pratos":[ChefHat,CookingPot],"Carnes":[Beef,Drumstick],
  "Mariscos e Peixe":[Fish,Shell],"Pastas":[Wheat,UtensilsCrossed],"Petiscos":[Drumstick,Utensils],
  "Sopas":[Soup,CookingPot],"Saladas":[Salad,Leaf],"Pizzas":[Pizza,Pizza],"Tostas e Brunch":[Coffee,Sandwich],
  "Sobremesa":[Cake,IceCream2],"Extras":[Utensils,Leaf],"Refrigerantes":[CupSoda,CupSoda],
  "Sumos":[Citrus,Citrus],"Sumos Naturais":[Apple,Citrus],"Água":[GlassWater,GlassWater],
  "Cafetaria":[Coffee,Coffee],"Cidras":[Apple,GlassWater],"Cervejas":[Beer,Beer],"Cocktails":[Martini,Citrus],
  "Espumantes":[Sparkles,Wine],"Vinhos":[Wine,Grape],"Dose Simples":[Flame,GlassWater],
};

export function CategoryIcons({name}:{name:string}){const pair=CATEGORY_ICONS[name]??[Leaf,Leaf];const L=pair[0],R=pair[1];return <><L aria-hidden="true" className="h-6 w-6 shrink-0 text-gold-light md:h-7 md:w-7" strokeWidth={1.5}/><R aria-hidden="true" className="h-6 w-6 shrink-0 text-gold-light md:h-7 md:w-7" strokeWidth={1.5}/></>}

export function CornerOrnament({className=""}:{className?:string}){return <svg aria-hidden="true" viewBox="0 0 64 64" className={className} fill="none"><path d="M3 61C3 29 20 8 57 3M3 61C23 59 38 48 47 31M3 61C13 58 20 51 25 42M12 51c4-8 10-12 18-13M23 39c-1-7 1-13 7-18M38 23c7 1 12 5 15 11M47 31c7 0 11 3 14 8" stroke="currentColor" strokeWidth="1.25" strokeLinecap="round"/><path d="M17 50c-5-1-9-4-12-9M27 37c-5-2-8-5-10-10M38 23c1-6 4-10 9-13M47 31c5-2 10-2 14 1" stroke="currentColor" strokeWidth="1.1" strokeLinecap="round"/></svg>}

export function DividerFlourish(){return <div aria-hidden="true" className="mx-auto flex w-[70%] max-w-xl items-center gap-3 py-2 text-gold"><span className="h-px flex-1 bg-gold/60"/><svg viewBox="0 0 28 12" className="h-3 w-7" fill="none"><path d="M2 6h24M8 6c2-6 5-6 6 0 1-6 4-6 6 0M8 6c2 6 5 6 6 0 1 6 4 6 6 0" stroke="currentColor" strokeWidth="1" strokeLinecap="round"/></svg><span className="h-px flex-1 bg-gold/60"/></div>}

export function OrnamentalFrame({children,position}:{children:React.ReactNode;position:"header"|"footer"}){return <div className={position==="header"?"relative":"relative"}><div aria-hidden="true" className="pointer-events-none absolute inset-3 border border-gold/55"><CornerOrnament className="absolute left-0 top-0 h-11 w-11 text-gold-light"/><CornerOrnament className="absolute right-0 top-0 h-11 w-11 rotate-90 text-gold-light"/><CornerOrnament className="absolute bottom-0 left-0 h-11 w-11 -rotate-90 text-gold-light"/><CornerOrnament className="absolute bottom-0 right-0 h-11 w-11 rotate-180 text-gold-light"/></div>{children}</div>}
