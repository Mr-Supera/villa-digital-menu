-- Fill only missing English names; never overwrite existing EN translations.
UPDATE public.categories AS c
SET name_en = v.name_en
FROM (VALUES
  ('Entradas','Starters'),('Pratos','Main Courses'),('Carnes','Meats'),('Mariscos e Peixe','Seafood & Fish'),
  ('Pastas','Pasta'),('Petiscos','Appetizers'),('Sopas','Soups'),('Saladas','Salads'),('Pizzas','Pizzas'),
  ('Tostas e Brunch','Toasts & Brunch'),('Sobremesa','Desserts'),('Extras','Extras'),('Refrigerantes','Soft Drinks'),
  ('Sumos','Juices'),('Sumos Naturais','Fresh Juices'),('Água','Water'),('Cafetaria','Coffee & Tea'),
  ('Cidras','Ciders'),('Cervejas','Beers'),('Cocktails','Cocktails'),('Espumantes','Sparkling Wines'),
  ('Vinhos','Wines'),('Tinto','Red'),('Branco','White'),('Vinhos Verdes','Vinho Verde (Green Wines)'),
  ('Rosé','Rosé'),('Vinhos do Porto','Port Wines'),('Vinhos à Taça','Wines by the Glass'),
  ('Dose Simples','Single Measures'),('Whisky','Whisky'),('Gin','Gin'),('Licor e Aperitivos','Liqueurs & Aperitifs'),
  ('Aguardente','Aguardente (Spirits)'),('Shots','Shots'),('Vodka','Vodka'),('Conhaque / Brandy','Cognac / Brandy'),
  ('Rum','Rum')
) AS v(name_pt,name_en)
WHERE c.name_pt=v.name_pt AND (c.name_en IS NULL OR btrim(c.name_en)='');

UPDATE public.items AS i
SET name_en = CASE i.name_pt
  WHEN 'Pequeno' THEN 'Small' WHEN 'Grande' THEN 'Large' WHEN 'Lata' THEN 'Can' WHEN 'Garrafa' THEN 'Bottle'
  WHEN 'Sumo de Laranja' THEN 'Orange Juice' WHEN 'Sumo de Pera' THEN 'Pear Juice'
  WHEN 'Sumo de Cenoura' THEN 'Carrot Juice' WHEN 'Sumo de Maçã' THEN 'Apple Juice'
  WHEN 'Sumo de Maracujá' THEN 'Passion Fruit Juice' WHEN 'Sumo de Misturas de Frutas' THEN 'Mixed Fruit Juice'
  WHEN 'Água Tónica' THEN 'Tonic Water' WHEN 'Café' THEN 'Coffee' WHEN 'Chá' THEN 'Tea'
  WHEN 'Chá de Leite' THEN 'Milk Tea' WHEN 'Chocolate Quente' THEN 'Hot Chocolate'
  WHEN 'Branco' THEN 'White' WHEN 'Tinto' THEN 'Red' WHEN 'Verde' THEN 'Vinho Verde'
  WHEN 'Porto' THEN 'Port' WHEN 'Licor' THEN 'Liqueur' WHEN 'Sem Álcool' THEN 'Alcohol-Free'
  ELSE i.name_pt
END
FROM public.categories AS c
WHERE c.id=i.category_id
  AND c.section='bebidas'
  AND (i.name_en IS NULL OR btrim(i.name_en)='')
  AND btrim(i.name_pt)<>'';