# Villa Digital Menu

Constrói um MENU DIGITAL profissional para o restaurante "Villa das Palmeiras" (Katembe-Khaelisa, Maputo, Moçambique), com uma área de administração protegida por login, onde o dono/gestor pode editar preços, adicionar/editar/remover pratos, bebidas e categorias. O menu público será aberto por QR code, por isso tem de ser MOBILE-FIRST, rápido e elegante.

Toda a interface em português de Moçambique, com opção de alternar para inglês (PT/EN).

==================================================
1. STACK
==================================================
- React + Vite + TypeScript + Tailwind + shadcn/ui
- Lovable Cloud / Supabase para base de dados, autenticação e armazenamento de imagens
- Sem dados fixos no código: tudo o que aparece no menu vem da base de dados

==================================================
2. IDENTIDADE VISUAL
==================================================
- Verde floresta escuro #24500F (principal), verde muito escuro #1B3D0B (fundos/rodapé)
- Dourado #A8732B (destaques, linhas, preços em hover), creme #FBF8F0 (fundo dos cartões e texto sobre verde)
- Tipografia: títulos em serif elegante (Playfair Display ou Cormorant Garamond), corpo em Lora ou similar, e uma fonte manuscrita/script APENAS em pequenos detalhes decorativos
- Estilo: sofisticado, tropical e acolhedor, com aspecto de menu impresso de restaurante. Cabeçalhos de secção em faixa verde escura com filete dourado fino (como no menu em papel), texto em maiúsculas com espaçamento entre letras, subtítulo em inglês em dourado
- Ilustrações de folhas de palmeira/monstera muito subtis (planas, baixa opacidade) só no cabeçalho e no rodapé. Sem excesso de decoração, sem efeitos de vidro, sem brilhos
- Deixa um espaço no cabeçalho para eu carregar o LOGO (upload nas definições do admin) e, até haver logo, mostra o texto "Villa das Palmeiras" em fonte script
- Modo claro apenas

==================================================
3. MENU PÚBLICO (rota "/")
==================================================
- Cabeçalho: logo centrado, nome, botão de idioma PT | EN
- Duas abas principais no topo: "Restaurante" e "Bebidas"
- Por baixo, barra de categorias horizontal (chips) fixa ao fazer scroll (sticky), que salta para a secção e destaca a categoria activa
- Campo de pesquisa que filtra pratos e bebidas em tempo real (ignorar acentos)
- Cada categoria: faixa de título (nome PT grande + nome EN em dourado) e lista de itens
- Cada item: nome, descrição (se existir), preço à direita, com linha ponteada entre itens (como no menu em papel). Se tiver foto, mostra miniatura à direita que abre em ecrã grande ao tocar
- Formato de preço: "1.500,00 MT" (ponto nos milhares, vírgula nos decimais)
- Itens marcados como "Esgotado" aparecem esmaecidos com etiqueta "Esgotado" (não desaparecem). Itens inactivos NÃO aparecem
- Itens "Destaque" mostram uma pequena estrela dourada
- Subcategorias aparecem como subtítulos dentro da categoria-mãe (ex.: Pratos > Carnes / Mariscos e Peixe; Vinhos > Tinto / Branco...)
- Rodapé: telefone/WhatsApp +258 85 202 1633 (link wa.me/258852021633), Instagram @grupovilladaspalmeiras (link), "Katembe-Khaelisa, Maputo", e o texto "Preços em Meticais (MT)"
- Botão flutuante "voltar ao topo"
- Carregamento rápido (skeletons), imagens com lazy-loading, boa acessibilidade e contraste
- Meta tags e título "Menu | Villa das Palmeiras", favicon com palmeira, e possibilidade de instalar como PWA simples
- Rota extra "/qr" (só visível para admins) que mostra o QR code do endereço público do menu, com botão para descarregar em PNG e SVG em alta resolução

==================================================
4. ÁREA DE ADMINISTRAÇÃO
==================================================
Rotas: /admin/login, /admin (dashboard), /admin/categorias, /admin/itens, /admin/definicoes, /admin/utilizadores

Autenticação e segurança (IMPORTANTE):
- Login com email + palavra-passe (Supabase Auth). Desactivar registo público
- Roles numa tabela SEPARADA "user_roles" (enum app_role: 'admin', 'editor'), com função SQL security definer has_role(). NUNCA guardar roles no perfil nem em localStorage
- Primeiro administrador: se a tabela user_roles estiver vazia, a página /admin/setup permite criar a primeira conta e atribui-lhe 'admin'. Depois de existir um admin, /admin/setup deixa de funcionar
- Admin pode: tudo, incluindo gerir utilizadores (criar contas de editores, remover acesso, repor palavra-passe). Editor pode: editar preços e itens, mas não gerir utilizadores nem definições
- RLS: leitura pública apenas de categorias e itens activos; escrita só para utilizadores com role admin/editor. Validar tudo no servidor (RLS), não só no frontend
- Botão "Terminar sessão", sessão persistente, recuperação de palavra-passe por email

Dashboard (/admin):
- Cartões com: total de itens, total de categorias, itens esgotados, itens inactivos
- Atalhos: "Novo item", "Nova categoria", "Ver menu público", "QR code"

Categorias (/admin/categorias):
- Lista com arrastar-e-largar para reordenar
- Criar/editar/apagar categoria: nome PT, nome EN (opcional), secção (Restaurante ou Bebidas), categoria-mãe (opcional, para subcategorias), ícone opcional, activa/inactiva
- Não permitir apagar categoria com itens sem pedir para mover os itens ou confirmar apagar tudo

Itens (/admin/itens):
- Tabela pesquisável e filtrável (por secção, categoria, esgotado/inactivo)
- EDIÇÃO RÁPIDA DE PREÇO directamente na tabela (clicar no preço, escrever, Enter para guardar) com confirmação visual
- Criar/editar item: nome PT, nome EN (opcional), descrição PT, descrição EN, preço (MT, número decimal), categoria, foto (upload para o storage, com pré-visualização e remoção), Disponível/Esgotado, Ativo/Inactivo (visível ou oculto), Destaque
- Acções: duplicar item, apagar (com confirmação), reordenar dentro da categoria (arrastar)
- AJUSTE EM MASSA DE PREÇOS: escolher uma categoria (ou todas), aumentar/diminuir por percentagem ou valor fixo, com pré-visualização "preço antigo → preço novo" antes de confirmar, e arredondamento opcional (a 5 ou 10 MT)
- Botão "Guardar" com toast de sucesso/erro; avisar se houver alterações por guardar ao sair

Definições (/admin/definicoes) [só admin]:
- Upload do logo, nome do restaurante, telefone/WhatsApp, Instagram, morada, mensagem do rodapé, cores principais
- Histórico simples de alterações de preço (data, utilizador, item, preço antigo, preço novo)

Utilizadores (/admin/utilizadores) [só admin]:
- Listar utilizadores e roles, convidar novo editor por email, remover acesso

==================================================
5. MODELO DE DADOS
==================================================
- categories: id, section ('restaurante' | 'bebidas'), parent_id (nullable), name_pt, name_en, sort_order, is_active, created_at
- items: id, category_id, name_pt, name_en, description_pt, description_en, price (numeric 10,2), image_url, is_available (bool), is_active (bool), is_featured (bool), sort_order, created_at, updated_at
- price_history: id, item_id, old_price, new_price, changed_by, changed_at
- settings: chave/valor (logo_url, phone, whatsapp, instagram, address, footer_text)
- user_roles: id, user_id (referência a auth.users), role (app_role)
- Bucket de storage público "menu-images" para fotos e logo (upload só para admin/editor)

==================================================
6. DADOS INICIAIS (SEED) - INSERIR TODOS NA BASE DE DADOS
==================================================
Formato: Nome PT | Nome EN | Preço MT | [Descrição PT] | [Descrição EN]
A ordem abaixo é a ordem de apresentação (sort_order).

------------------ SECÇÃO: RESTAURANTE ------------------

CATEGORIA: Entradas / Starters
Pão de Alho | Garlic Bread | 200
Pão de Alho com Queijo | Garlic Bread with Cheese | 300
Azeitonas Temperadas | Seasoned Olives | 150
Camarão Alhinho (6) | Garlic Shrimp (6) | 550
Canapés | Canapés | 250
Salgados à Villa das Palmeiras (6) | Villa das Palmeiras Savory Bites (6) | 300
Moelas com Batata Frita | Gizzards with French Fries | 250
Worse com Batata Frita | Sausage with French Fries | 300
Babalaza com Batata Frita | Chicken Wings (6) with French Fries | 300
Polvo à Villa das Palmeiras | Octopus à Villa das Palmeiras | 400

CATEGORIA: Pratos / Main Courses
  SUBCATEGORIA: Carnes / Meats
  1/2 Frango Grelhado com Batata Frita e Salada | Grilled 1/2 Chicken with French Fries and Salad | 500
  1/2 Frango à Zambeziana com Xima e Salada | Zambezi-style 1/2 Chicken with Xima and Salad | 550
  Frango Grelhado com Batata Frita e Salada | Grilled Chicken with French Fries and Salad | 950
  Frango à Zambeziana com Xima e Salada | Zambezi-style Chicken with Xima and Salad | 1050
  Peito de Frango com Batata Doce e Salada | Chicken Breast with Sweet Potato and Salad | 900
  Bife da Vazia com Batata Cozida e Cenoura | Beef Sirloin with Boiled Potato and Carrot | 1100
  Naco de Lombo com Legumes a Vapor e Batata Salté | Sirloin Steak with Steamed Vegetables and Sautéed Potatoes | 1550
  Bitoque com Batata Frita, Ovo e Salada | Steak with French Fries, Egg and Salad | 1000
  Costeletas de Burrego com Batata Rústica e Legumes Assados | Lamb Chops with Rustic Potatoes and Roasted Vegetables | 1600
  Almôndegas de Carne Moída com Batata Frita e Salada | Ground Beef Meatballs with French Fries and Salad | 750
  Tábua de Carnes (Picanha, Worse, Babalaza, Asinhas) | Mixed Grill Platter (Picanha, Sausage, Babalaza, Chicken Wings) | 2500
  Biryane de Frango | Chicken Biryani | 700
  T-Bone com Batata Frita e Salada | T-Bone Steak with French Fries and Salad | 850
  Picanha com Feijão Preto, Batata Frita e Salada | Picanha with Black Beans, French Fries and Salad | 1300
  Pato Grelhado com Arroz | Grilled Duck with Rice | 850

  SUBCATEGORIA: Mariscos e Peixe / Seafood & Fish
  Filete de Peixe Panado com Arroz Malandrinho | Breaded Fish Fillet with Malandrinho Rice | 1350
  Garoupa Grelhada com Legumes e Batata Cozida | Grilled Grouper with Vegetables and Boiled Potatoes | 1400
  Lota de Vermelhão com Legumes, Batata Assada e Molho de Manteiga e Limão | Red Snapper with Vegetables and Roasted Potatoes with Butter and Lemon Sauce | 1200
  Vermelhão Confitado com Legumes a Vapor, Batata e Ovo | Confit Red Snapper with Steamed Vegetables, Potatoes and Egg | 1500
  Bacalhau com Broa, Batata Assada e Couve | Cod with Cornbread, Roasted Potatoes and Kale | 1900
  Lagosta com Batata Frita e Salada | Lobster with French Fries and Salad | 2500
  Camarão Tigre com Batata Doce e Arroz Branco | Tiger Prawns with Sweet Potato and White Rice | 3000
  Camarão K com Batata Frita e Salada | King Prawns with French Fries and Salad | 1850
  Tiras de Peixe com Batata Frita e Salada | Fish Strips with French Fries and Salad | 950
  Vermelhão Grelhado com Legumes e Batata Cozida | Grilled Red Snapper with Vegetables and Boiled Potatoes | 1200
  Misto de Mariscos | Seafood Platter | 2500
  Lulas Grelhadas com Batata Frita e Salada | Grilled Squid with French Fries and Salad | 1200
  Peixe Pedra com Legumes | Stone Fish with Vegetables | 1200
  Filete de Garoupa com Legumes | Grouper Fillet with Vegetables | 1200
  Garoupa para 2 Pessoas | Grouper for 2 People | 1900
  Camarão Frito com Batata Frita e Salada | Fried Prawns with French Fries and Salad | 1500
  Arroz de Mariscos | Seafood Rice | 1500

CATEGORIA: Pastas / Pastas
Fuzil com Molho Pesto | Fusilli with Pesto Sauce | 550
Macarrão com Molho à Bolonhesa | Pasta with Bolognese Sauce | 650
Massa Penne com Legumes | Penne Pasta with Vegetables | 550

CATEGORIA: Petiscos / Appetizers
Petisco de Dobrada | Tripe Appetizer | 200
Petisco de Frango | Chicken Appetizer | 250
Petisco de Amêijoa | Clam Appetizer | 300
Petisco de Cabeça de Vaca | Beef Head Appetizer | 300
Petisco de Cabeça de Peixe | Fish Head Appetizer | 250
Revoada de Galinha | Fried Chicken Bites | 500

CATEGORIA: Sopas / Soups
Creme de Legumes | Vegetable Cream Soup | 200
Creme de Tomate | Tomato Cream Soup | 200
Sopa de Legumes | Vegetable Soup | 250 | (repolho, cebola, cenoura, batata, alho) | (cabbage, onion, carrot, potato, garlic)
Caldo Verde | Portuguese Green Soup | 200

CATEGORIA: Saladas / Salads
Salada Mista | Mixed Salad | 300 | Alface, tomate, cebola, cenoura, pepino e azeitonas. | Lettuce, tomato, onion, carrot, cucumber and olives.
Salada Grega | Greek Salad | 400 | Alface, tomate, pepino, cebola, pimentão, azeitonas e queijo feta. | Lettuce, tomato, cucumber, onion, bell pepper, olives and feta cheese.
Salada de Frango | Chicken Salad | 400 | Alface, frango grelhado, tomate, cenoura, milho, croutons e molho da casa. | Lettuce, grilled chicken, tomato, carrot, corn, croutons and house dressing.
Salada de Atum | Tuna Salad | 470 | Alface, atum, tomate, cebola, milho, ovo cozido e azeitonas. | Lettuce, tuna, tomato, onion, corn, boiled egg and olives.

CATEGORIA: Pizzas / Pizzas
Pizza de Carne | Meat Pizza | 900 | Molho de tomate, queijo, carne moída, cebola e orégãos. | Tomato sauce, cheese, minced meat, onion and oregano.
Pizza de Frango | Chicken Pizza | 850 | Molho de tomate, queijo, frango, cebola e pimentão. | Tomato sauce, cheese, chicken, onion and bell pepper.
Pizza Margherita | Margherita Pizza | 600 | Molho de tomate, queijo mussarela, manjericão e orégãos. | Tomato sauce, mozzarella cheese, basil and oregano.
Pizza Mexicana | Mexican Pizza | 850 | Molho de tomate, queijo, carne moída, feijão, milho, pimentão e jalapeños. | Tomato sauce, cheese, minced meat, beans, corn, bell pepper and jalapeños.
Pizza Pepperoni | Pepperoni Pizza | 900 | Molho de tomate, queijo, peperoni e orégãos. | Tomato sauce, cheese, pepperoni and oregano.
Pizza de Camarão | Shrimp Pizza | 1050 | Molho de tomate, queijo, camarão, alho e orégãos. | Tomato sauce, cheese, shrimp, garlic and oregano.
Pizza Quatro Estações | Four Seasons Pizza | 800 | Molho de tomate, queijo, fiambre, cogumelos, alcachofra, azeitonas. | Tomato sauce, cheese, ham, mushrooms, artichoke and olives.
Pizza de Mariscos | Seafood Pizza | 1200 | Molho de tomate, queijo, mariscos variados e alho. | Tomato sauce, cheese, mixed seafood and garlic.
Pizza Spice | Spice Pizza | 1000 | Molho de tomate, queijo, frango picante, cebola roxa, pimentão e molho picante. | Tomato sauce, cheese, spicy chicken, red onion, bell pepper and spicy sauce.

CATEGORIA: Tostas e Brunch / Toasts & Brunch
Prego no Pão com Batata Frita e Salada | Steak Sandwich with French Fries and Salad | 350
Prego no Prato com Batata Frita e Salada | Steak on a Plate with French Fries and Salad | 550
Prego de Frango com Batata Frita e Salada | Chicken Sandwich with French Fries and Salad | 350
Tosta Mista com Batata Frita e Salada | Ham and Cheese Toast with French Fries and Salad | 400
Tosta de Atum com Batata Frita e Salada | Tuna Toast with French Fries and Salad | 300
Tosta de Frango com Batata Frita e Salada | Chicken Toast with French Fries and Salad | 400
Torrada com Manteiga | Toast with Butter | 150
Sandes Clube com Batata Frita e Salada | Club Sandwich with French Fries and Salad | 550
Hamburger Completo | Full Burger | 350
Hamburger Duplo | Double Burger | 450

CATEGORIA: Sobremesa / Desserts
Pavé de Chocolate | Chocolate Pavé | 300 | Camadas de biscoito e creme de chocolate, finalizado com cacau em pó. | Layers of biscuits and chocolate cream, finished with cocoa powder.
Sorvete em Cone | Ice Cream Cone | 100 | Sorvete cremoso no sabor à escolha. | Creamy ice cream in a cone, flavor of your choice.
Sorvete no Copo | Ice Cream Cup | 200 | Sorvete cremoso servido em copo, sabor à escolha. | Creamy ice cream served in a cup, flavor of your choice.
Salada de Fruta | Fruit Salad | 150 | Frutas frescas da estação cortadas em cubos. | Fresh seasonal fruit salad.
Kibon Cone Clássico Amanhecer | Kibon Classic Amanhecer Cone | 135 | Sorvete de creme com cobertura de chocolate e amendoim crocante. | Classic Amanhecer ice cream cone with chocolate topping and crispy peanuts.
Kibon Cookie Amanhecer | Kibon Amanhecer Cookie | 160 | Sorvete de creme com pedaços de cookie e cobertura de chocolate. | Amanhecer cookie ice cream with cookie pieces and chocolate topping.
Kibon Mini de Amêndoa Amanhecer | Kibon Amanhecer Mini Almond | 130 | Sorvete de creme com cobertura de chocolate e amêndoas crocantes. | Amanhecer mini almond ice cream with chocolate coating and crunchy almonds.
Magnum Almond Vanilla | Magnum Almond Vanilla | 170 | Sorvete de baunilha com cobertura de chocolate e amêndoas crocantes. | Vanilla ice cream with chocolate coating and crunchy almonds.
Magnum de Chocolate | Magnum Chocolate | 170 | Sorvete de chocolate com cobertura de chocolate ao leite. | Chocolate ice cream with milk chocolate coating.
Mousse de Chocolate | Chocolate Mousse | 200 | Mousse leve e aerado de chocolate, feito com chocolate belga. | Light and airy chocolate mousse, made with Belgian chocolate.
Colchão de Noiva | Colchão de Noiva | 300 | Doce tradicional à base de camadas de bolacha e creme. | Traditional dessert made with layers of biscuits and cream.
Fruta Laminada | Sliced Fruit | 200 | Frutas frescas fatiadas. | Fresh sliced fruits.

CATEGORIA: Extras / Extras
Dose de Batata Frita | French Fries Portion | 200 | Batata frita crocante e dourada. | Crispy golden french fries.
Dose de Arroz Branco | White Rice Portion | 200 | Arroz branco soltinho. | Plain white rice.
Dose de Feijão Preto | Black Beans Portion | 300 | Feijão preto cozido temperado. | Seasoned black beans.
Dose de Legumes | Vegetables Portion | 200 | Legumes cozidos no ponto. | Steamed mixed vegetables.
Couve Salteada | Sautéed Kale | 300 | Couve refogada com alho. | Sautéed kale with garlic.
Salada de Alface | Lettuce Salad | 200 | Alface fresca temperada. | Fresh seasoned lettuce.
Apas (6) | Apas (6) | 350 | Seleção de 6 unidades. | Selection of 6 pieces.
Pão (1) | Bread (1) | 30 | Pão fresco da casa. | Fresh bread.
Ovo (1) | Egg (1) | 20 | Ovo cozido. | Boiled egg.
Take Away | Take Away | 20 | Embalagem para viagem. | Take away packaging.
Take Away de Alumínio | Aluminum Take Away | 40 | Embalagem de alumínio para viagem. | Aluminum take away container.

------------------ SECÇÃO: BEBIDAS ------------------
(as bebidas não têm nome EN no menu original: deixar name_en vazio)

CATEGORIA: Refrigerantes
Coca-Cola / Coca-Cola Zero | 100
Fanta (Ananás, Laranja ou Uva) | 100
Sparletta (Cream Soda ou Morango) | 100
Sprite | 100
Lemon Twist | 100
Schweppes (Dry Lemon) | 100
Red Bull | 170

CATEGORIA: Sumos
Ceres Pequeno 250ml | 70
Ceres Grande 1L | 180
Compal Pequeno 500ml | 120
Compal Grande 1L | 180
Santal | 150
Cappy Lata (Laranja, Manga ou Maracujá) | 120

CATEGORIA: Sumos Naturais
Sumo de Laranja | 280
Sumo de Pera | 280
Sumo de Cenoura | 280
Sumo de Maçã | 280
Sumo de Maracujá | 280
Sumo de Misturas de Frutas | 350

CATEGORIA: Água
Namaacha Pequena 500ml | 50
Namaacha Grande 1,5L | 100
Vumba Pequena 500ml | 50
Vumba Grande 1,5L | 120
Água Tónica | 100
Água das Pedras (Regular ou Limão) | 120

CATEGORIA: Cafetaria
Café | 80
Chá | 80
Capuccino | 150
Chá de Leite | 150
Chocolate Quente | 120

CATEGORIA: Cidras
Bernini Garrafa/Lata | 170
Brutal Garrafa/Lata | 170
Hunters Dry/Gold | 150
Savana Dry/Lemon | 150
Smirnoff Spin | 150
Mayfair | 160
JC Le Roux a Lata | 170

CATEGORIA: Cervejas
2M (Lata ou Txoti) | 100
Castle Lite Garrafa | 100
Impala | 100
Manica | 100
Super Bock | 100
Txilar | 100
Laurentina Preta | 100
Flying Fish | 120
Heineken Mini | 150
Heineken Silver | 180
Stella Artois | 150
Corona Extra | 150

CATEGORIA: Cocktails
Caipirinha de Limão / Maracujá | 400
Sex On The Beach | 400
Tequila Sunrise | 400
Piña Colada | 400
Tipo Tinto | 300
Lagoa Azul | 400
Long Island Iced Tea | 500
Vodka c/ Sumo de Laranja ou Red Bull | 350

CATEGORIA: Espumantes
Chandon Sem Álcool | 750
JC Branco / Rosé | 1000
Krone Night Nectar | 5000
Nuà Brut | 1600
Laurent Perrier Demi Sec | 1600
Pongracz Noble Nectar | 1800
Moët Nectar | 5000
Tosti Moscato | 1400
Murganheira | 1800
Don Pérignon Vintage 2013 | 20000
Moët & Chandon Impérial Rosé | 7000
Bar Royal Melon | 750

CATEGORIA: Vinhos
  SUBCATEGORIA: Tinto
  Cabriz Reserva | 1800
  Casar do Bispo | 1500
  Ethos | 1700
  Portada Tinto | 1200
  Gran Appassos | 2200
  Quinta do Ministro Tinto | 1800
  Rupert | 1600
  Segredos de São Miguel | 2000
  Segredos do Valentim | 1600
  Silk & Spice | 1800
  Terra Linda | 2500
  Anthonij Rupert Optima | 1800
  Duas Quintas Reserva | 4800
  Esporão | 3500
  Esteva Douro | 1800
  Kleine Zalze Cabernet | 1800
  Nicolas Catena Zapata | 10000
  Regateiro Vinha do Forno | 3000
  Fat Bastard | 1800
  Muchu Más | 2500
  Quinta Nova | 5500

  SUBCATEGORIA: Branco
  Cabriz Branco | 1700
  Fat Bastard Chardonnay | 1700
  Fleur Ducap | 1200
  Portada Branco | 1700
  Quinta do Ministro Branco | 1500
  Boschendal White | 1500
  Defesa do Esporão Branco | 1800
  Dona Ermelinda Palmela | 1800
  Duas Quintas Reserva | 3800
  Fado Portugal Branco | 1000
  Planalto Reserva Douro | 2000
  Aveleda Branco | 1200
  Vinhas de Fridão | 1200

  SUBCATEGORIA: Vinhos Verdes
  Aveleda Verde | 1500
  Quinta da Calçada Loureiro Verde | 1300
  Portal da Calçada Loureiro Verde | 1500
  Gatão Verde | 1000
  Gazela | 900
  Casal Garcia | 1000

  SUBCATEGORIA: Rosé
  Quinta do Ministro Rosé | 1700
  Robertson Rosé | 1000
  Vinho Nederburg Rosé | 900
  Mateus Rosé | 1300
  Riesling Vintage 2022 | 1500

  SUBCATEGORIA: Vinhos do Porto
  Kopke Fine Tawny Porto | 1800
  Pacheca Porto Tawny | 2000
  Quinta dos Murças 10 Anos Tawny Porto | 3500
  Pacheca Reserva | 2200

  SUBCATEGORIA: Vinhos à Taça
  Branco | 180
  Tinto | 200

CATEGORIA: Dose Simples
  SUBCATEGORIA: Whisky
  Jameson | 150
  Black Label | 180
  Red Label | 150
  Gold Label | 300
  Chivas Regal | 150
  Glenfiddich 12 | 200
  Glenfiddich 15 | 250
  J&B | 150

  SUBCATEGORIA: Gin
  Bombay | 180
  Gordon's | 150
  Beefeater | 150
  Tanqueray | 200
  Hendrick's | 200
  Star of Bombay | 200

  SUBCATEGORIA: Licor e Aperitivos
  Amarula | 150
  Drambuie Licor | 200
  Kahlúa Coffee Liqueur | 150
  Licor Beirão | 200
  Amarguinha | 200
  Bottega Limoncino | 200
  Martini Branco / Rosa | 200

  SUBCATEGORIA: Aguardente
  São Domingos | 150
  Macieira | 150
  Brandy 1920 | 150
  CR&F Old Brandy | 250
  Pitú | 150
  Antiqua | 200

  SUBCATEGORIA: Shots
  Olmeca Tequila | 150
  Jägermeister | 150
  Tequila Jose Cuervo | 200
  Samboca | 200
  Blow Job | 200
  Tequila Patrón | 200

  SUBCATEGORIA: Vodka
  Absolut Vodka | 180
  Cîroc | 150
  Smirnoff 1818 | 150

  SUBCATEGORIA: Conhaque / Brandy
  Rémy Martin | 350
  Hennessy | 250
  Hennessy XO | 500
  Courvoisier VS Cognac | 200

  SUBCATEGORIA: Rum
  Bacardi | 180
  Captain Morgan | 150

==================================================
7. CRITÉRIOS DE ACEITAÇÃO
==================================================
- O menu público mostra todas as categorias e itens acima, com preços correctos, em PT e EN
- Ao alterar um preço no admin, o menu público reflete a mudança sem precisar de redeploy
- Um utilizador sem login NÃO consegue aceder a /admin nem escrever na base de dados (testar RLS)
- Funciona perfeitamente em telemóvel (360px) e é agradável em desktop
- Posso adicionar uma nova categoria (ex.: "Cafetaria da Manhã") e novos itens (ex.: um novo sumo) sem tocar no código
- Antes de terminar, faz uma revisão de segurança (RLS, roles, storage) e corrige o que faltar

This project was built with [Lovable](https://lovable.dev).

## Build with Lovable

Continue developing this project in the [Lovable editor](https://lovable.dev/projects/4d550b58-de26-4110-8a3a-cc24a59069ed).

- **Ship faster**: describe what you want to build and Lovable handles the code.
- **Stay in sync**: every change made in Lovable is committed straight to this repository.
- **Full ownership**: this code is yours. Push to `main` on GitHub and your changes sync back into Lovable, ready for your next prompt.

## Development

Prefer working locally? You need Node.js and npm — [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating).

```sh
git clone <this-repository-url>
cd <repository-name>
npm i
npm run dev
```
