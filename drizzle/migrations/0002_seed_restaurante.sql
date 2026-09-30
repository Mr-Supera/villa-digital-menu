-- ENTRADAS
WITH c AS (
  INSERT INTO public.categories (section, name_pt, name_en, sort_order)
  VALUES ('restaurante','Entradas','Starters',1) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, name_en, price, sort_order)
SELECT c.id, v.n, v.e, v.p, v.s FROM c, (VALUES
 ('Pão de Alho','Garlic Bread',200,1),
 ('Pão de Alho com Queijo','Garlic Bread with Cheese',300,2),
 ('Azeitonas Temperadas','Seasoned Olives',150,3),
 ('Camarão Alhinho (6)','Garlic Shrimp (6)',550,4),
 ('Canapés','Canapés',250,5),
 ('Salgados à Villa das Palmeiras (6)','Villa das Palmeiras Savory Bites (6)',300,6),
 ('Moelas com Batata Frita','Gizzards with French Fries',250,7),
 ('Worse com Batata Frita','Sausage with French Fries',300,8),
 ('Babalaza com Batata Frita','Chicken Wings (6) with French Fries',300,9),
 ('Polvo à Villa das Palmeiras','Octopus à Villa das Palmeiras',400,10)
) AS v(n,e,p,s);

-- PRATOS + subcategorias
WITH p AS (
  INSERT INTO public.categories (section, name_pt, name_en, sort_order)
  VALUES ('restaurante','Pratos','Main Courses',2) RETURNING id
), carnes AS (
  INSERT INTO public.categories (section, parent_id, name_pt, name_en, sort_order)
  SELECT 'restaurante', p.id, 'Carnes','Meats',1 FROM p RETURNING id
), mar AS (
  INSERT INTO public.categories (section, parent_id, name_pt, name_en, sort_order)
  SELECT 'restaurante', p.id, 'Mariscos e Peixe','Seafood & Fish',2 FROM p RETURNING id
), i1 AS (
  INSERT INTO public.items (category_id, name_pt, name_en, price, sort_order)
  SELECT carnes.id, v.n, v.e, v.p, v.s FROM carnes, (VALUES
   ('1/2 Frango Grelhado com Batata Frita e Salada','Grilled 1/2 Chicken with French Fries and Salad',500,1),
   ('1/2 Frango à Zambeziana com Xima e Salada','Zambezi-style 1/2 Chicken with Xima and Salad',550,2),
   ('Frango Grelhado com Batata Frita e Salada','Grilled Chicken with French Fries and Salad',950,3),
   ('Frango à Zambeziana com Xima e Salada','Zambezi-style Chicken with Xima and Salad',1050,4),
   ('Peito de Frango com Batata Doce e Salada','Chicken Breast with Sweet Potato and Salad',900,5),
   ('Bife da Vazia com Batata Cozida e Cenoura','Beef Sirloin with Boiled Potato and Carrot',1100,6),
   ('Naco de Lombo com Legumes a Vapor e Batata Salté','Sirloin Steak with Steamed Vegetables and Sautéed Potatoes',1550,7),
   ('Bitoque com Batata Frita, Ovo e Salada','Steak with French Fries, Egg and Salad',1000,8),
   ('Costeletas de Burrego com Batata Rústica e Legumes Assados','Lamb Chops with Rustic Potatoes and Roasted Vegetables',1600,9),
   ('Almôndegas de Carne Moída com Batata Frita e Salada','Ground Beef Meatballs with French Fries and Salad',750,10),
   ('Tábua de Carnes (Picanha, Worse, Babalaza, Asinhas)','Mixed Grill Platter (Picanha, Sausage, Babalaza, Chicken Wings)',2500,11),
   ('Biryane de Frango','Chicken Biryani',700,12),
   ('T-Bone com Batata Frita e Salada','T-Bone Steak with French Fries and Salad',850,13),
   ('Picanha com Feijão Preto, Batata Frita e Salada','Picanha with Black Beans, French Fries and Salad',1300,14),
   ('Pato Grelhado com Arroz','Grilled Duck with Rice',850,15)
  ) AS v(n,e,p,s)
)
INSERT INTO public.items (category_id, name_pt, name_en, price, sort_order)
SELECT mar.id, v.n, v.e, v.p, v.s FROM mar, (VALUES
 ('Filete de Peixe Panado com Arroz Malandrinho','Breaded Fish Fillet with Malandrinho Rice',1350,1),
 ('Garoupa Grelhada com Legumes e Batata Cozida','Grilled Grouper with Vegetables and Boiled Potatoes',1400,2),
 ('Lota de Vermelhão com Legumes, Batata Assada e Molho de Manteiga e Limão','Red Snapper with Vegetables and Roasted Potatoes with Butter and Lemon Sauce',1200,3),
 ('Vermelhão Confitado com Legumes a Vapor, Batata e Ovo','Confit Red Snapper with Steamed Vegetables, Potatoes and Egg',1500,4),
 ('Bacalhau com Broa, Batata Assada e Couve','Cod with Cornbread, Roasted Potatoes and Kale',1900,5),
 ('Lagosta com Batata Frita e Salada','Lobster with French Fries and Salad',2500,6),
 ('Camarão Tigre com Batata Doce e Arroz Branco','Tiger Prawns with Sweet Potato and White Rice',3000,7),
 ('Camarão K com Batata Frita e Salada','King Prawns with French Fries and Salad',1850,8),
 ('Tiras de Peixe com Batata Frita e Salada','Fish Strips with French Fries and Salad',950,9),
 ('Vermelhão Grelhado com Legumes e Batata Cozida','Grilled Red Snapper with Vegetables and Boiled Potatoes',1200,10),
 ('Misto de Mariscos','Seafood Platter',2500,11),
 ('Lulas Grelhadas com Batata Frita e Salada','Grilled Squid with French Fries and Salad',1200,12),
 ('Peixe Pedra com Legumes','Stone Fish with Vegetables',1200,13),
 ('Filete de Garoupa com Legumes','Grouper Fillet with Vegetables',1200,14),
 ('Garoupa para 2 Pessoas','Grouper for 2 People',1900,15),
 ('Camarão Frito com Batata Frita e Salada','Fried Prawns with French Fries and Salad',1500,16),
 ('Arroz de Mariscos','Seafood Rice',1500,17)
) AS v(n,e,p,s);

-- PASTAS
WITH c AS (
  INSERT INTO public.categories (section, name_pt, name_en, sort_order)
  VALUES ('restaurante','Pastas','Pastas',3) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, name_en, price, sort_order)
SELECT c.id, v.n, v.e, v.p, v.s FROM c, (VALUES
 ('Fuzil com Molho Pesto','Fusilli with Pesto Sauce',550,1),
 ('Macarrão com Molho à Bolonhesa','Pasta with Bolognese Sauce',650,2),
 ('Massa Penne com Legumes','Penne Pasta with Vegetables',550,3)
) AS v(n,e,p,s);

-- PETISCOS
WITH c AS (
  INSERT INTO public.categories (section, name_pt, name_en, sort_order)
  VALUES ('restaurante','Petiscos','Appetizers',4) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, name_en, price, sort_order)
SELECT c.id, v.n, v.e, v.p, v.s FROM c, (VALUES
 ('Petisco de Dobrada','Tripe Appetizer',200,1),
 ('Petisco de Frango','Chicken Appetizer',250,2),
 ('Petisco de Amêijoa','Clam Appetizer',300,3),
 ('Petisco de Cabeça de Vaca','Beef Head Appetizer',300,4),
 ('Petisco de Cabeça de Peixe','Fish Head Appetizer',250,5),
 ('Revoada de Galinha','Fried Chicken Bites',500,6)
) AS v(n,e,p,s);

-- SOPAS
WITH c AS (
  INSERT INTO public.categories (section, name_pt, name_en, sort_order)
  VALUES ('restaurante','Sopas','Soups',5) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, name_en, price, description_pt, description_en, sort_order)
SELECT c.id, v.n, v.e, v.p, v.dp, v.de, v.s FROM c, (VALUES
 ('Creme de Legumes','Vegetable Cream Soup',200,NULL::text,NULL::text,1),
 ('Creme de Tomate','Tomato Cream Soup',200,NULL,NULL,2),
 ('Sopa de Legumes','Vegetable Soup',250,'Repolho, cebola, cenoura, batata, alho.','Cabbage, onion, carrot, potato, garlic.',3),
 ('Caldo Verde','Portuguese Green Soup',200,NULL,NULL,4)
) AS v(n,e,p,dp,de,s);

-- SALADAS
WITH c AS (
  INSERT INTO public.categories (section, name_pt, name_en, sort_order)
  VALUES ('restaurante','Saladas','Salads',6) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, name_en, price, description_pt, description_en, sort_order)
SELECT c.id, v.n, v.e, v.p, v.dp, v.de, v.s FROM c, (VALUES
 ('Salada Mista','Mixed Salad',300,'Alface, tomate, cebola, cenoura, pepino e azeitonas.','Lettuce, tomato, onion, carrot, cucumber and olives.',1),
 ('Salada Grega','Greek Salad',400,'Alface, tomate, pepino, cebola, pimentão, azeitonas e queijo feta.','Lettuce, tomato, cucumber, onion, bell pepper, olives and feta cheese.',2),
 ('Salada de Frango','Chicken Salad',400,'Alface, frango grelhado, tomate, cenoura, milho, croutons e molho da casa.','Lettuce, grilled chicken, tomato, carrot, corn, croutons and house dressing.',3),
 ('Salada de Atum','Tuna Salad',470,'Alface, atum, tomate, cebola, milho, ovo cozido e azeitonas.','Lettuce, tuna, tomato, onion, corn, boiled egg and olives.',4)
) AS v(n,e,p,dp,de,s);

-- PIZZAS
WITH c AS (
  INSERT INTO public.categories (section, name_pt, name_en, sort_order)
  VALUES ('restaurante','Pizzas','Pizzas',7) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, name_en, price, description_pt, description_en, sort_order)
SELECT c.id, v.n, v.e, v.p, v.dp, v.de, v.s FROM c, (VALUES
 ('Pizza de Carne','Meat Pizza',900,'Molho de tomate, queijo, carne moída, cebola e orégãos.','Tomato sauce, cheese, minced meat, onion and oregano.',1),
 ('Pizza de Frango','Chicken Pizza',850,'Molho de tomate, queijo, frango, cebola e pimentão.','Tomato sauce, cheese, chicken, onion and bell pepper.',2),
 ('Pizza Margherita','Margherita Pizza',600,'Molho de tomate, queijo mussarela, manjericão e orégãos.','Tomato sauce, mozzarella cheese, basil and oregano.',3),
 ('Pizza Mexicana','Mexican Pizza',850,'Molho de tomate, queijo, carne moída, feijão, milho, pimentão e jalapeños.','Tomato sauce, cheese, minced meat, beans, corn, bell pepper and jalapeños.',4),
 ('Pizza Pepperoni','Pepperoni Pizza',900,'Molho de tomate, queijo, peperoni e orégãos.','Tomato sauce, cheese, pepperoni and oregano.',5),
 ('Pizza de Camarão','Shrimp Pizza',1050,'Molho de tomate, queijo, camarão, alho e orégãos.','Tomato sauce, cheese, shrimp, garlic and oregano.',6),
 ('Pizza Quatro Estações','Four Seasons Pizza',800,'Molho de tomate, queijo, fiambre, cogumelos, alcachofra, azeitonas.','Tomato sauce, cheese, ham, mushrooms, artichoke and olives.',7),
 ('Pizza de Mariscos','Seafood Pizza',1200,'Molho de tomate, queijo, mariscos variados e alho.','Tomato sauce, cheese, mixed seafood and garlic.',8),
 ('Pizza Spice','Spice Pizza',1000,'Molho de tomate, queijo, frango picante, cebola roxa, pimentão e molho picante.','Tomato sauce, cheese, spicy chicken, red onion, bell pepper and spicy sauce.',9)
) AS v(n,e,p,dp,de,s);

-- TOSTAS E BRUNCH
WITH c AS (
  INSERT INTO public.categories (section, name_pt, name_en, sort_order)
  VALUES ('restaurante','Tostas e Brunch','Toasts & Brunch',8) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, name_en, price, sort_order)
SELECT c.id, v.n, v.e, v.p, v.s FROM c, (VALUES
 ('Prego no Pão com Batata Frita e Salada','Steak Sandwich with French Fries and Salad',350,1),
 ('Prego no Prato com Batata Frita e Salada','Steak on a Plate with French Fries and Salad',550,2),
 ('Prego de Frango com Batata Frita e Salada','Chicken Sandwich with French Fries and Salad',350,3),
 ('Tosta Mista com Batata Frita e Salada','Ham and Cheese Toast with French Fries and Salad',400,4),
 ('Tosta de Atum com Batata Frita e Salada','Tuna Toast with French Fries and Salad',300,5),
 ('Tosta de Frango com Batata Frita e Salada','Chicken Toast with French Fries and Salad',400,6),
 ('Torrada com Manteiga','Toast with Butter',150,7),
 ('Sandes Clube com Batata Frita e Salada','Club Sandwich with French Fries and Salad',550,8),
 ('Hamburger Completo','Full Burger',350,9),
 ('Hamburger Duplo','Double Burger',450,10)
) AS v(n,e,p,s);

-- SOBREMESA
WITH c AS (
  INSERT INTO public.categories (section, name_pt, name_en, sort_order)
  VALUES ('restaurante','Sobremesa','Desserts',9) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, name_en, price, description_pt, description_en, sort_order)
SELECT c.id, v.n, v.e, v.p, v.dp, v.de, v.s FROM c, (VALUES
 ('Pavé de Chocolate','Chocolate Pavé',300,'Camadas de biscoito e creme de chocolate, finalizado com cacau em pó.','Layers of biscuits and chocolate cream, finished with cocoa powder.',1),
 ('Sorvete em Cone','Ice Cream Cone',100,'Sorvete cremoso no sabor à escolha.','Creamy ice cream in a cone, flavor of your choice.',2),
 ('Sorvete no Copo','Ice Cream Cup',200,'Sorvete cremoso servido em copo, sabor à escolha.','Creamy ice cream served in a cup, flavor of your choice.',3),
 ('Salada de Fruta','Fruit Salad',150,'Frutas frescas da estação cortadas em cubos.','Fresh seasonal fruit salad.',4),
 ('Kibon Cone Clássico Amanhecer','Kibon Classic Amanhecer Cone',135,'Sorvete de creme com cobertura de chocolate e amendoim crocante.','Classic Amanhecer ice cream cone with chocolate topping and crispy peanuts.',5),
 ('Kibon Cookie Amanhecer','Kibon Amanhecer Cookie',160,'Sorvete de creme com pedaços de cookie e cobertura de chocolate.','Amanhecer cookie ice cream with cookie pieces and chocolate topping.',6),
 ('Kibon Mini de Amêndoa Amanhecer','Kibon Amanhecer Mini Almond',130,'Sorvete de creme com cobertura de chocolate e amêndoas crocantes.','Amanhecer mini almond ice cream with chocolate coating and crunchy almonds.',7),
 ('Magnum Almond Vanilla','Magnum Almond Vanilla',170,'Sorvete de baunilha com cobertura de chocolate e amêndoas crocantes.','Vanilla ice cream with chocolate coating and crunchy almonds.',8),
 ('Magnum de Chocolate','Magnum Chocolate',170,'Sorvete de chocolate com cobertura de chocolate ao leite.','Chocolate ice cream with milk chocolate coating.',9),
 ('Mousse de Chocolate','Chocolate Mousse',200,'Mousse leve e aerado de chocolate, feito com chocolate belga.','Light and airy chocolate mousse, made with Belgian chocolate.',10),
 ('Colchão de Noiva','Colchão de Noiva',300,'Doce tradicional à base de camadas de bolacha e creme.','Traditional dessert made with layers of biscuits and cream.',11),
 ('Fruta Laminada','Sliced Fruit',200,'Frutas frescas fatiadas.','Fresh sliced fruits.',12)
) AS v(n,e,p,dp,de,s);

-- EXTRAS
WITH c AS (
  INSERT INTO public.categories (section, name_pt, name_en, sort_order)
  VALUES ('restaurante','Extras','Extras',10) RETURNING id
)
INSERT INTO public.items (category_id, name_pt, name_en, price, description_pt, description_en, sort_order)
SELECT c.id, v.n, v.e, v.p, v.dp, v.de, v.s FROM c, (VALUES
 ('Dose de Batata Frita','French Fries Portion',200,'Batata frita crocante e dourada.','Crispy golden french fries.',1),
 ('Dose de Arroz Branco','White Rice Portion',200,'Arroz branco soltinho.','Plain white rice.',2),
 ('Dose de Feijão Preto','Black Beans Portion',300,'Feijão preto cozido temperado.','Seasoned black beans.',3),
 ('Dose de Legumes','Vegetables Portion',200,'Legumes cozidos no ponto.','Steamed mixed vegetables.',4),
 ('Couve Salteada','Sautéed Kale',300,'Couve refogada com alho.','Sautéed kale with garlic.',5),
 ('Salada de Alface','Lettuce Salad',200,'Alface fresca temperada.','Fresh seasoned lettuce.',6),
 ('Apas (6)','Apas (6)',350,'Seleção de 6 unidades.','Selection of 6 pieces.',7),
 ('Pão (1)','Bread (1)',30,'Pão fresco da casa.','Fresh bread.',8),
 ('Ovo (1)','Egg (1)',20,'Ovo cozido.','Boiled egg.',9),
 ('Take Away','Take Away',20,'Embalagem para viagem.','Take away packaging.',10),
 ('Take Away de Alumínio','Aluminum Take Away',40,'Embalagem de alumínio para viagem.','Aluminum take away container.',11)
) AS v(n,e,p,dp,de,s);
