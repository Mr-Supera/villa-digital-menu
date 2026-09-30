WITH c AS (
  INSERT INTO public.categories (section, name_pt, sort_order) VALUES ('bebidas','Refrigerantes',1) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, price, sort_order)
SELECT c.id, v.n, v.p, v.s FROM c, (VALUES
 ('Coca-Cola / Coca-Cola Zero',100,1),('Fanta (Ananás, Laranja ou Uva)',100,2),
 ('Sparletta (Cream Soda ou Morango)',100,3),('Sprite',100,4),('Lemon Twist',100,5),
 ('Schweppes (Dry Lemon)',100,6),('Red Bull',170,7)
) AS v(n,p,s);

WITH c AS (
  INSERT INTO public.categories (section, name_pt, sort_order) VALUES ('bebidas','Sumos',2) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, price, sort_order)
SELECT c.id, v.n, v.p, v.s FROM c, (VALUES
 ('Ceres Pequeno 250ml',70,1),('Ceres Grande 1L',180,2),('Compal Pequeno 500ml',120,3),
 ('Compal Grande 1L',180,4),('Santal',150,5),('Cappy Lata (Laranja, Manga ou Maracujá)',120,6)
) AS v(n,p,s);

WITH c AS (
  INSERT INTO public.categories (section, name_pt, sort_order) VALUES ('bebidas','Sumos Naturais',3) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, price, sort_order)
SELECT c.id, v.n, v.p, v.s FROM c, (VALUES
 ('Sumo de Laranja',280,1),('Sumo de Pera',280,2),('Sumo de Cenoura',280,3),
 ('Sumo de Maçã',280,4),('Sumo de Maracujá',280,5),('Sumo de Misturas de Frutas',350,6)
) AS v(n,p,s);

WITH c AS (
  INSERT INTO public.categories (section, name_pt, sort_order) VALUES ('bebidas','Água',4) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, price, sort_order)
SELECT c.id, v.n, v.p, v.s FROM c, (VALUES
 ('Namaacha Pequena 500ml',50,1),('Namaacha Grande 1,5L',100,2),('Vumba Pequena 500ml',50,3),
 ('Vumba Grande 1,5L',120,4),('Água Tónica',100,5),('Água das Pedras (Regular ou Limão)',120,6)
) AS v(n,p,s);

WITH c AS (
  INSERT INTO public.categories (section, name_pt, sort_order) VALUES ('bebidas','Cafetaria',5) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, price, sort_order)
SELECT c.id, v.n, v.p, v.s FROM c, (VALUES
 ('Café',80,1),('Chá',80,2),('Capuccino',150,3),('Chá de Leite',150,4),('Chocolate Quente',120,5)
) AS v(n,p,s);

WITH c AS (
  INSERT INTO public.categories (section, name_pt, sort_order) VALUES ('bebidas','Cidras',6) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, price, sort_order)
SELECT c.id, v.n, v.p, v.s FROM c, (VALUES
 ('Bernini Garrafa/Lata',170,1),('Brutal Garrafa/Lata',170,2),('Hunters Dry/Gold',150,3),
 ('Savana Dry/Lemon',150,4),('Smirnoff Spin',150,5),('Mayfair',160,6),('JC Le Roux a Lata',170,7)
) AS v(n,p,s);

WITH c AS (
  INSERT INTO public.categories (section, name_pt, sort_order) VALUES ('bebidas','Cervejas',7) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, price, sort_order)
SELECT c.id, v.n, v.p, v.s FROM c, (VALUES
 ('2M (Lata ou Txoti)',100,1),('Castle Lite Garrafa',100,2),('Impala',100,3),('Manica',100,4),
 ('Super Bock',100,5),('Txilar',100,6),('Laurentina Preta',100,7),('Flying Fish',120,8),
 ('Heineken Mini',150,9),('Heineken Silver',180,10),('Stella Artois',150,11),('Corona Extra',150,12)
) AS v(n,p,s);

WITH c AS (
  INSERT INTO public.categories (section, name_pt, sort_order) VALUES ('bebidas','Cocktails',8) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, price, sort_order)
SELECT c.id, v.n, v.p, v.s FROM c, (VALUES
 ('Caipirinha de Limão / Maracujá',400,1),('Sex On The Beach',400,2),('Tequila Sunrise',400,3),
 ('Piña Colada',400,4),('Tipo Tinto',300,5),('Lagoa Azul',400,6),('Long Island Iced Tea',500,7),
 ('Vodka c/ Sumo de Laranja ou Red Bull',350,8)
) AS v(n,p,s);

WITH c AS (
  INSERT INTO public.categories (section, name_pt, sort_order) VALUES ('bebidas','Espumantes',9) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, price, sort_order)
SELECT c.id, v.n, v.p, v.s FROM c, (VALUES
 ('Chandon Sem Álcool',750,1),('JC Branco / Rosé',1000,2),('Krone Night Nectar',5000,3),
 ('Nuà Brut',1600,4),('Laurent Perrier Demi Sec',1600,5),('Pongracz Noble Nectar',1800,6),
 ('Moët Nectar',5000,7),('Tosti Moscato',1400,8),('Murganheira',1800,9),
 ('Don Pérignon Vintage 2013',20000,10),('Moët & Chandon Impérial Rosé',7000,11),('Bar Royal Melon',750,12)
) AS v(n,p,s);

-- VINHOS
WITH p AS (
  INSERT INTO public.categories (section, name_pt, sort_order) VALUES ('bebidas','Vinhos',10) RETURNING id
), tinto AS (
  INSERT INTO public.categories (section, parent_id, name_pt, sort_order) SELECT 'bebidas', p.id, 'Tinto',1 FROM p RETURNING id
), branco AS (
  INSERT INTO public.categories (section, parent_id, name_pt, sort_order) SELECT 'bebidas', p.id, 'Branco',2 FROM p RETURNING id
), verdes AS (
  INSERT INTO public.categories (section, parent_id, name_pt, sort_order) SELECT 'bebidas', p.id, 'Vinhos Verdes',3 FROM p RETURNING id
), rose AS (
  INSERT INTO public.categories (section, parent_id, name_pt, sort_order) SELECT 'bebidas', p.id, 'Rosé',4 FROM p RETURNING id
), porto AS (
  INSERT INTO public.categories (section, parent_id, name_pt, sort_order) SELECT 'bebidas', p.id, 'Vinhos do Porto',5 FROM p RETURNING id
), taca AS (
  INSERT INTO public.categories (section, parent_id, name_pt, sort_order) SELECT 'bebidas', p.id, 'Vinhos à Taça',6 FROM p RETURNING id
), a1 AS (
  INSERT INTO public.items (category_id, name_pt, price, sort_order)
  SELECT tinto.id, v.n, v.p, v.s FROM tinto, (VALUES
   ('Cabriz Reserva',1800,1),('Casar do Bispo',1500,2),('Ethos',1700,3),('Portada Tinto',1200,4),
   ('Gran Appassos',2200,5),('Quinta do Ministro Tinto',1800,6),('Rupert',1600,7),
   ('Segredos de São Miguel',2000,8),('Segredos do Valentim',1600,9),('Silk & Spice',1800,10),
   ('Terra Linda',2500,11),('Anthonij Rupert Optima',1800,12),('Duas Quintas Reserva',4800,13),
   ('Esporão',3500,14),('Esteva Douro',1800,15),('Kleine Zalze Cabernet',1800,16),
   ('Nicolas Catena Zapata',10000,17),('Regateiro Vinha do Forno',3000,18),('Fat Bastard',1800,19),
   ('Muchu Más',2500,20),('Quinta Nova',5500,21)
  ) AS v(n,p,s)
), a2 AS (
  INSERT INTO public.items (category_id, name_pt, price, sort_order)
  SELECT branco.id, v.n, v.p, v.s FROM branco, (VALUES
   ('Cabriz Branco',1700,1),('Fat Bastard Chardonnay',1700,2),('Fleur Ducap',1200,3),
   ('Portada Branco',1700,4),('Quinta do Ministro Branco',1500,5),('Boschendal White',1500,6),
   ('Defesa do Esporão Branco',1800,7),('Dona Ermelinda Palmela',1800,8),('Duas Quintas Reserva',3800,9),
   ('Fado Portugal Branco',1000,10),('Planalto Reserva Douro',2000,11),('Aveleda Branco',1200,12),
   ('Vinhas de Fridão',1200,13)
  ) AS v(n,p,s)
), a3 AS (
  INSERT INTO public.items (category_id, name_pt, price, sort_order)
  SELECT verdes.id, v.n, v.p, v.s FROM verdes, (VALUES
   ('Aveleda Verde',1500,1),('Quinta da Calçada Loureiro Verde',1300,2),('Portal da Calçada Loureiro Verde',1500,3),
   ('Gatão Verde',1000,4),('Gazela',900,5),('Casal Garcia',1000,6)
  ) AS v(n,p,s)
), a4 AS (
  INSERT INTO public.items (category_id, name_pt, price, sort_order)
  SELECT rose.id, v.n, v.p, v.s FROM rose, (VALUES
   ('Quinta do Ministro Rosé',1700,1),('Robertson Rosé',1000,2),('Vinho Nederburg Rosé',900,3),
   ('Mateus Rosé',1300,4),('Riesling Vintage 2022',1500,5)
  ) AS v(n,p,s)
), a5 AS (
  INSERT INTO public.items (category_id, name_pt, price, sort_order)
  SELECT porto.id, v.n, v.p, v.s FROM porto, (VALUES
   ('Kopke Fine Tawny Porto',1800,1),('Pacheca Porto Tawny',2000,2),
   ('Quinta dos Murças 10 Anos Tawny Porto',3500,3),('Pacheca Reserva',2200,4)
  ) AS v(n,p,s)
)
INSERT INTO public.items (category_id, name_pt, price, sort_order)
SELECT taca.id, v.n, v.p, v.s FROM taca, (VALUES ('Branco',180,1),('Tinto',200,2)) AS v(n,p,s);

-- DOSE SIMPLES
WITH p AS (
  INSERT INTO public.categories (section, name_pt, sort_order) VALUES ('bebidas','Dose Simples',11) RETURNING id
), whisky AS (
  INSERT INTO public.categories (section, parent_id, name_pt, sort_order) SELECT 'bebidas', p.id, 'Whisky',1 FROM p RETURNING id
), gin AS (
  INSERT INTO public.categories (section, parent_id, name_pt, sort_order) SELECT 'bebidas', p.id, 'Gin',2 FROM p RETURNING id
), licor AS (
  INSERT INTO public.categories (section, parent_id, name_pt, sort_order) SELECT 'bebidas', p.id, 'Licor e Aperitivos',3 FROM p RETURNING id
), agua AS (
  INSERT INTO public.categories (section, parent_id, name_pt, sort_order) SELECT 'bebidas', p.id, 'Aguardente',4 FROM p RETURNING id
), shots AS (
  INSERT INTO public.categories (section, parent_id, name_pt, sort_order) SELECT 'bebidas', p.id, 'Shots',5 FROM p RETURNING id
), vodka AS (
  INSERT INTO public.categories (section, parent_id, name_pt, sort_order) SELECT 'bebidas', p.id, 'Vodka',6 FROM p RETURNING id
), conhaque AS (
  INSERT INTO public.categories (section, parent_id, name_pt, sort_order) SELECT 'bebidas', p.id, 'Conhaque / Brandy',7 FROM p RETURNING id
), rum AS (
  INSERT INTO public.categories (section, parent_id, name_pt, sort_order) SELECT 'bebidas', p.id, 'Rum',8 FROM p RETURNING id
), b1 AS (
  INSERT INTO public.items (category_id, name_pt, price, sort_order)
  SELECT whisky.id, v.n, v.p, v.s FROM whisky, (VALUES
   ('Jameson',150,1),('Black Label',180,2),('Red Label',150,3),('Gold Label',300,4),
   ('Chivas Regal',150,5),('Glenfiddich 12',200,6),('Glenfiddich 15',250,7),('J&B',150,8)
  ) AS v(n,p,s)
), b2 AS (
  INSERT INTO public.items (category_id, name_pt, price, sort_order)
  SELECT gin.id, v.n, v.p, v.s FROM gin, (VALUES
   ('Bombay',180,1),('Gordon''s',150,2),('Beefeater',150,3),('Tanqueray',200,4),
   ('Hendrick''s',200,5),('Star of Bombay',200,6)
  ) AS v(n,p,s)
), b3 AS (
  INSERT INTO public.items (category_id, name_pt, price, sort_order)
  SELECT licor.id, v.n, v.p, v.s FROM licor, (VALUES
   ('Amarula',150,1),('Drambuie Licor',200,2),('Kahlúa Coffee Liqueur',150,3),('Licor Beirão',200,4),
   ('Amarguinha',200,5),('Bottega Limoncino',200,6),('Martini Branco / Rosa',200,7)
  ) AS v(n,p,s)
), b4 AS (
  INSERT INTO public.items (category_id, name_pt, price, sort_order)
  SELECT agua.id, v.n, v.p, v.s FROM agua, (VALUES
   ('São Domingos',150,1),('Macieira',150,2),('Brandy 1920',150,3),('CR&F Old Brandy',250,4),
   ('Pitú',150,5),('Antiqua',200,6)
  ) AS v(n,p,s)
), b5 AS (
  INSERT INTO public.items (category_id, name_pt, price, sort_order)
  SELECT shots.id, v.n, v.p, v.s FROM shots, (VALUES
   ('Olmeca Tequila',150,1),('Jägermeister',150,2),('Tequila Jose Cuervo',200,3),
   ('Samboca',200,4),('Blow Job',200,5),('Tequila Patrón',200,6)
  ) AS v(n,p,s)
), b6 AS (
  INSERT INTO public.items (category_id, name_pt, price, sort_order)
  SELECT vodka.id, v.n, v.p, v.s FROM vodka, (VALUES
   ('Absolut Vodka',180,1),('Cîroc',150,2),('Smirnoff 1818',150,3)
  ) AS v(n,p,s)
), b7 AS (
  INSERT INTO public.items (category_id, name_pt, price, sort_order)
  SELECT conhaque.id, v.n, v.p, v.s FROM conhaque, (VALUES
   ('Rémy Martin',350,1),('Hennessy',250,2),('Hennessy XO',500,3),('Courvoisier VS Cognac',200,4)
  ) AS v(n,p,s)
)
INSERT INTO public.items (category_id, name_pt, price, sort_order)
SELECT rum.id, v.n, v.p, v.s FROM rum, (VALUES ('Bacardi',180,1),('Captain Morgan',150,2)) AS v(n,p,s);
