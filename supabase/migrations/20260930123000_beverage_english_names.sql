begin;

-- Fill only missing English display names for beverage categories.
update public.categories set name_en = case trim(name_pt)
  when 'Refrigerantes' then 'Soft Drinks'
  when 'Sumos' then 'Juices'
  when 'Sumos Naturais' then 'Fresh Juices'
  when 'Água' then 'Water'
  when 'Cafetaria' then 'Coffee & Tea'
  when 'Cidras' then 'Ciders'
  when 'Cervejas' then 'Beers'
  when 'Cocktails' then 'Cocktails'
  when 'Espumantes' then 'Sparkling Wines'
  when 'Vinhos' then 'Wines'
  when 'Tinto' then 'Red'
  when 'Branco' then 'White'
  when 'Vinhos Verdes' then 'Vinho Verde (Green Wines)'
  when 'Rosé' then 'Rosé'
  when 'Vinhos do Porto' then 'Port Wines'
  when 'Vinhos à Taça' then 'Wines by the Glass'
  when 'Dose Simples' then 'Single Measures'
  when 'Whisky' then 'Whisky'
  when 'Gin' then 'Gin'
  when 'Licor e Aperitivos' then 'Liqueurs & Aperitifs'
  when 'Aguardente' then 'Aguardente (Spirits)'
  when 'Shots' then 'Shots'
  when 'Vodka' then 'Vodka'
  when 'Conhaque / Brandy' then 'Cognac / Brandy'
  when 'Rum' then 'Rum'
  else name_en end
where lower(coalesce(section,'')) = 'bebidas'
  and trim(coalesce(name_en,'')) = ''
  and trim(name_pt) in ('Refrigerantes','Sumos','Sumos Naturais','Água','Cafetaria','Cidras','Cervejas','Cocktails','Espumantes','Vinhos','Tinto','Branco','Vinhos Verdes','Rosé','Vinhos do Porto','Vinhos à Taça','Dose Simples','Whisky','Gin','Licor e Aperitivos','Aguardente','Shots','Vodka','Conhaque / Brandy','Rum');

-- Fill explicitly supplied beverage item translations.
update public.items set name_en = case trim(name_pt)
  when 'Fanta (Ananás, Laranja ou Uva)' then 'Fanta (Pineapple, Orange or Grape)'
  when 'Sparletta (Cream Soda ou Morango)' then 'Sparletta (Cream Soda or Strawberry)'
  when 'Ceres Pequeno 250ml' then 'Ceres Small 250ml'
  when 'Ceres Grande 1L' then 'Ceres Large 1L'
  when 'Compal Pequeno 500ml' then 'Compal Small 500ml'
  when 'Compal Grande 1L' then 'Compal Large 1L'
  when 'Cappy Lata (Laranja, Manga ou Maracujá)' then 'Cappy Can (Orange, Mango or Passion Fruit)'
  when 'Sumo de Laranja' then 'Orange Juice'
  when 'Sumo de Pera' then 'Pear Juice'
  when 'Sumo de Cenoura' then 'Carrot Juice'
  when 'Sumo de Maçã' then 'Apple Juice'
  when 'Sumo de Maracujá' then 'Passion Fruit Juice'
  when 'Sumo de Misturas de Frutas' then 'Mixed Fruit Juice'
  when 'Namaacha Pequena 500ml' then 'Namaacha Small 500ml'
  when 'Namaacha Grande 1,5L' then 'Namaacha Large 1.5L'
  when 'Vumba Pequena 500ml' then 'Vumba Small 500ml'
  when 'Vumba Grande 1,5L' then 'Vumba Large 1.5L'
  when 'Água Tónica' then 'Tonic Water'
  when 'Água das Pedras (Regular ou Limão)' then 'Água das Pedras (Regular or Lemon)'
  when 'Café' then 'Coffee'
  when 'Chá' then 'Tea'
  when 'Capuccino' then 'Cappuccino'
  when 'Chá de Leite' then 'Milk Tea'
  when 'Chocolate Quente' then 'Hot Chocolate'
  when 'Bernini Garrafa/Lata' then 'Bernini Bottle/Can'
  when 'Brutal Garrafa/Lata' then 'Brutal Bottle/Can'
  when 'JC Le Roux a Lata' then 'JC Le Roux Can'
  when '2M (Lata ou Txoti)' then '2M (Can or Txoti)'
  when 'Castle Lite Garrafa' then 'Castle Lite Bottle'
  when 'Laurentina Preta' then 'Laurentina Preta (Dark Beer)'
  when 'Caipirinha de Limão / Maracujá' then 'Caipirinha (Lime / Passion Fruit)'
  when 'Lagoa Azul' then 'Blue Lagoon'
  when 'Vodka c/ Sumo de Laranja ou Red Bull' then 'Vodka with Orange Juice or Red Bull'
  when 'Chandon Sem Álcool' then 'Chandon Alcohol-Free'
  when 'JC Branco / Rosé' then 'JC White / Rosé'
  when 'Cabriz Branco' then 'Cabriz White'
  when 'Portada Tinto' then 'Portada Red'
  when 'Portada Branco' then 'Portada White'
  when 'Quinta do Ministro Tinto' then 'Quinta do Ministro Red'
  when 'Quinta do Ministro Branco' then 'Quinta do Ministro White'
  when 'Defesa do Esporão Branco' then 'Defesa do Esporão White'
  when 'Aveleda Branco' then 'Aveleda White'
  when 'Aveleda Verde' then 'Aveleda Vinho Verde'
  when 'Quinta da Calçada Loureiro Verde' then 'Quinta da Calçada Loureiro Vinho Verde'
  when 'Portal da Calçada Loureiro Verde' then 'Portal da Calçada Loureiro Vinho Verde'
  when 'Gatão Verde' then 'Gatão Vinho Verde'
  when 'Fado Portugal Branco' then 'Fado Portugal White'
  when 'Quinta do Ministro Rosé' then 'Quinta do Ministro Rosé'
  when 'Vinho Nederburg Rosé' then 'Nederburg Rosé Wine'
  when 'Kopke Fine Tawny Porto' then 'Kopke Fine Tawny Port'
  when 'Pacheca Porto Tawny' then 'Pacheca Tawny Port'
  when 'Quinta dos Murças 10 Anos Tawny Porto' then 'Quinta dos Murças 10 Year Tawny Port'
  when 'Pacheca Reserva' then 'Pacheca Reserve'
  when 'Branco' then 'White'
  when 'Tinto' then 'Red'
  when 'Drambuie Licor' then 'Drambuie Liqueur'
  when 'Licor Beirão' then 'Licor Beirão Liqueur'
  when 'Martini Branco / Rosa' then 'Martini White / Rosé'
  else name_en end
where exists (
  select 1 from public.categories c
  where c.id = items.category_id and lower(coalesce(c.section,'')) = 'bebidas'
)
and trim(coalesce(name_en,'')) = '';

-- Any remaining beverage item without an English name keeps its brand/proper name.
update public.items
set name_en = name_pt
where exists (
  select 1 from public.categories c
  where c.id = items.category_id and lower(coalesce(c.section,'')) = 'bebidas'
)
and trim(coalesce(name_en,'')) = ''
and trim(coalesce(name_pt,'')) <> '';

commit;