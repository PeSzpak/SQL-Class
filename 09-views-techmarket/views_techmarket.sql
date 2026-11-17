USE db_techmarket;


-- ETAPA 1 - PREPARACAO DO AMBIENTE
-- Relacionamentos:
--   clientes   1:N pedidos       (pedidos.id_cliente)
--   vendedores 1:N pedidos       (pedidos.id_vendedor)
--   pedidos    1:N itens_pedido  (itens_pedido.id_pedido)
--   produtos   1:N itens_pedido  (itens_pedido.id_produto)
-- Um pedido pode ter varios itens: contar pedidos sempre com COUNT(DISTINCT id_pedido).
-- Apenas status 'Faturado' conta como faturamento (Cancelado e Pendente ficam de fora).

SELECT status_pedido, COUNT(*) AS qtd_pedidos
FROM pedidos
GROUP BY status_pedido;


-- MISSAO 1 - VISAO CONSOLIDADA DAS VENDAS

CREATE OR REPLACE VIEW vw_vendas_detalhadas AS
SELECT
    p.id_pedido,
    p.data_pedido,
    c.id_cliente,
    c.nome   AS cliente,
    c.cidade,
    c.estado,
    v.id_vendedor,
    v.nome   AS vendedor,
    v.equipe,
    pr.id_produto,
    pr.descricao AS produto,
    pr.categoria,
    i.id_item,
    i.quantidade,
    i.preco_unitario,
    i.desconto_percentual,
    ROUND(i.quantidade * i.preco_unitario, 2)                                       AS valor_bruto,
    ROUND(i.quantidade * i.preco_unitario * i.desconto_percentual / 100, 2)         AS valor_desconto,
    ROUND(i.quantidade * i.preco_unitario * (1 - i.desconto_percentual / 100), 2)   AS valor_faturado
FROM pedidos p
INNER JOIN clientes     c  ON c.id_cliente  = p.id_cliente
INNER JOIN vendedores   v  ON v.id_vendedor = p.id_vendedor
INNER JOIN itens_pedido i  ON i.id_pedido   = p.id_pedido
INNER JOIN produtos     pr ON pr.id_produto = i.id_produto
WHERE p.status_pedido = 'Faturado';

-- 1.1 Todas as vendas, do maior para o menor valor faturado
SELECT *
FROM vw_vendas_detalhadas
ORDER BY valor_faturado DESC;

-- 1.2 Top 5 itens de venda por valor faturado
SELECT id_pedido, cliente, produto, quantidade, valor_faturado
FROM vw_vendas_detalhadas
ORDER BY valor_faturado DESC
LIMIT 5;

-- 1.3 Vendas para clientes do Parana, por data
SELECT id_pedido, data_pedido, cliente, cidade, produto, quantidade, valor_faturado
FROM vw_vendas_detalhadas
WHERE estado = 'PR'
ORDER BY data_pedido, id_pedido;


-- MISSAO 2 - DESEMPENHO DOS VENDEDORES
-- Construida sobre vw_vendas_detalhadas: o calculo do desconto fica em um unico lugar.
-- LEFT JOIN garante que vendedores sem vendas faturadas aparecam com zero.

CREATE OR REPLACE VIEW vw_desempenho_vendedores AS
SELECT
    ve.id_vendedor,
    ve.nome   AS vendedor,
    ve.equipe,
    COUNT(DISTINCT vd.id_pedido)        AS qtd_pedidos,
    COALESCE(SUM(vd.quantidade), 0)     AS qtd_unidades,
    COALESCE(SUM(vd.valor_faturado), 0) AS faturamento
FROM vendedores ve
LEFT JOIN vw_vendas_detalhadas vd ON vd.id_vendedor = ve.id_vendedor
GROUP BY ve.id_vendedor, ve.nome, ve.equipe;

-- 2.1 Ranking de vendedores com ticket medio por pedido
SELECT
    vendedor,
    equipe,
    qtd_pedidos,
    faturamento,
    COALESCE(ROUND(faturamento / NULLIF(qtd_pedidos, 0), 2), 0) AS ticket_medio
FROM vw_desempenho_vendedores
ORDER BY faturamento DESC;

-- 2.2 Faturamento e pedidos por equipe
-- Cada pedido pertence a um unico vendedor, entao somar qtd_pedidos por equipe nao duplica.
SELECT
    equipe,
    SUM(qtd_pedidos) AS qtd_pedidos,
    SUM(faturamento) AS faturamento
FROM vw_desempenho_vendedores
GROUP BY equipe
ORDER BY faturamento DESC;


-- MISSAO 3 - DESEMPENHO DOS PRODUTOS

CREATE OR REPLACE VIEW vw_desempenho_produtos AS
SELECT
    pr.id_produto,
    pr.descricao AS produto,
    pr.categoria,
    COALESCE(SUM(vd.quantidade), 0)     AS qtd_unidades,
    COUNT(DISTINCT vd.id_pedido)        AS qtd_pedidos,
    COALESCE(SUM(vd.valor_faturado), 0) AS receita
FROM produtos pr
LEFT JOIN vw_vendas_detalhadas vd ON vd.id_produto = pr.id_produto
GROUP BY pr.id_produto, pr.descricao, pr.categoria;

-- 3.1 Produtos com maior receita
SELECT produto, categoria, qtd_unidades, receita
FROM vw_desempenho_produtos
ORDER BY receita DESC;

-- 3.2 Categorias com faturamento acima de R$ 2.000,00
SELECT
    categoria,
    SUM(qtd_unidades) AS qtd_unidades,
    SUM(receita)      AS faturamento
FROM vw_desempenho_produtos
GROUP BY categoria
HAVING SUM(receita) > 2000
ORDER BY faturamento DESC;

-- 3.3 Top 3 produtos por valor medio faturado por unidade (ja liquido de desconto)
SELECT
    produto,
    categoria,
    qtd_unidades,
    receita,
    ROUND(receita / NULLIF(qtd_unidades, 0), 2) AS valor_medio_unidade
FROM vw_desempenho_produtos
WHERE qtd_unidades > 0
ORDER BY valor_medio_unidade DESC
LIMIT 3;


-- MISSAO 4 - COMPORTAMENTO DOS CLIENTES
-- LEFT JOIN mantem clientes sem compras faturadas, com indicadores zerados.

CREATE OR REPLACE VIEW vw_resumo_clientes AS
SELECT
    c.id_cliente,
    c.nome AS cliente,
    c.cidade,
    c.estado,
    COUNT(DISTINCT vd.id_pedido)        AS qtd_pedidos,
    COALESCE(SUM(vd.valor_faturado), 0) AS total_gasto
FROM clientes c
LEFT JOIN vw_vendas_detalhadas vd ON vd.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nome, c.cidade, c.estado;

-- 4.1 Ranking de clientes com ticket medio
SELECT
    cliente,
    estado,
    qtd_pedidos,
    total_gasto,
    COALESCE(ROUND(total_gasto / NULLIF(qtd_pedidos, 0), 2), 0) AS ticket_medio
FROM vw_resumo_clientes
ORDER BY total_gasto DESC;

-- 4.2 Classificacao dos clientes
SELECT
    cliente,
    estado,
    total_gasto,
    CASE
        WHEN total_gasto >= 5000 THEN 'VIP'
        WHEN total_gasto >  0    THEN 'Regular'
        ELSE 'Sem compras'
    END AS grupo
FROM vw_resumo_clientes
ORDER BY total_gasto DESC;

-- 4.3 Faturamento, clientes cadastrados e media por cliente, por estado
SELECT
    estado,
    SUM(total_gasto)           AS faturamento,
    COUNT(*)                   AS qtd_clientes,
    ROUND(AVG(total_gasto), 2) AS media_por_cliente
FROM vw_resumo_clientes
GROUP BY estado
ORDER BY faturamento DESC;


-- MISSAO 5 - PAINEL EXECUTIVO

-- 5.1 Desempenho por equipe + categoria que mais fatura em cada equipe
-- Metricas vem de vw_desempenho_vendedores (pedidos ja contados sem duplicidade por vendedor);
-- a categoria lider vem de vw_vendas_detalhadas.
SELECT
    eq.equipe,
    eq.qtd_pedidos,
    eq.faturamento,
    ROUND(eq.faturamento / NULLIF(eq.qtd_pedidos, 0), 2) AS ticket_medio,
    cat.categoria         AS categoria_lider,
    cat.faturamento_cat   AS faturamento_categoria_lider
FROM (
    SELECT equipe, SUM(qtd_pedidos) AS qtd_pedidos, SUM(faturamento) AS faturamento
    FROM vw_desempenho_vendedores
    GROUP BY equipe
) AS eq
LEFT JOIN (
    SELECT
        equipe,
        categoria,
        SUM(valor_faturado) AS faturamento_cat,
        RANK() OVER (PARTITION BY equipe ORDER BY SUM(valor_faturado) DESC) AS posicao
    FROM vw_vendas_detalhadas
    GROUP BY equipe, categoria
) AS cat ON cat.equipe = eq.equipe AND cat.posicao = 1
ORDER BY eq.faturamento DESC;

-- 5.2 Participacao de cada categoria no faturamento total
-- O total da empresa vem de vw_desempenho_vendedores, servindo tambem como conferencia
-- de que as duas views fecham o mesmo valor (soma dos percentuais = 100,00).
SELECT
    p.categoria,
    SUM(p.receita) AS faturamento,
    ROUND(SUM(p.receita) * 100 / (SELECT SUM(faturamento) FROM vw_desempenho_vendedores), 2) AS percentual
FROM vw_desempenho_produtos p
GROUP BY p.categoria
ORDER BY faturamento DESC;

-- 5.3 Clientes acima da media dos clientes com compras efetivadas
SELECT
    rc.cliente,
    rc.estado,
    rc.total_gasto,
    ROUND(rc.total_gasto - m.media, 2) AS diferenca_media
FROM vw_resumo_clientes rc
CROSS JOIN (
    SELECT ROUND(AVG(total_gasto), 2) AS media
    FROM vw_resumo_clientes
    WHERE qtd_pedidos > 0
) AS m
WHERE rc.total_gasto > m.media
ORDER BY rc.total_gasto DESC;


-- MISSAO 6 - DESCONTO TOTAL POR VENDEDOR
-- Mantem todos os campos anteriores (mesmos nomes e ordem) e acrescenta desconto_total no final,
-- para que os relatorios existentes continuem funcionando sem alteracao.

CREATE OR REPLACE VIEW vw_desempenho_vendedores AS
SELECT
    ve.id_vendedor,
    ve.nome   AS vendedor,
    ve.equipe,
    COUNT(DISTINCT vd.id_pedido)        AS qtd_pedidos,
    COALESCE(SUM(vd.quantidade), 0)     AS qtd_unidades,
    COALESCE(SUM(vd.valor_faturado), 0) AS faturamento,
    COALESCE(SUM(vd.valor_desconto), 0) AS desconto_total
FROM vendedores ve
LEFT JOIN vw_vendas_detalhadas vd ON vd.id_vendedor = ve.id_vendedor
GROUP BY ve.id_vendedor, ve.nome, ve.equipe;

-- 6.1 Novo indicador
SELECT vendedor, equipe, faturamento, desconto_total
FROM vw_desempenho_vendedores
ORDER BY desconto_total DESC;

-- 6.2 Reexecucao dos relatorios que dependem da view alterada

-- (2.1)
SELECT
    vendedor,
    equipe,
    qtd_pedidos,
    faturamento,
    COALESCE(ROUND(faturamento / NULLIF(qtd_pedidos, 0), 2), 0) AS ticket_medio
FROM vw_desempenho_vendedores
ORDER BY faturamento DESC;

-- (2.2)
SELECT
    equipe,
    SUM(qtd_pedidos) AS qtd_pedidos,
    SUM(faturamento) AS faturamento
FROM vw_desempenho_vendedores
GROUP BY equipe
ORDER BY faturamento DESC;

-- (5.1)
SELECT
    eq.equipe,
    eq.qtd_pedidos,
    eq.faturamento,
    ROUND(eq.faturamento / NULLIF(eq.qtd_pedidos, 0), 2) AS ticket_medio,
    cat.categoria         AS categoria_lider,
    cat.faturamento_cat   AS faturamento_categoria_lider
FROM (
    SELECT equipe, SUM(qtd_pedidos) AS qtd_pedidos, SUM(faturamento) AS faturamento
    FROM vw_desempenho_vendedores
    GROUP BY equipe
) AS eq
LEFT JOIN (
    SELECT
        equipe,
        categoria,
        SUM(valor_faturado) AS faturamento_cat,
        RANK() OVER (PARTITION BY equipe ORDER BY SUM(valor_faturado) DESC) AS posicao
    FROM vw_vendas_detalhadas
    GROUP BY equipe, categoria
) AS cat ON cat.equipe = eq.equipe AND cat.posicao = 1
ORDER BY eq.faturamento DESC;

-- (5.2)
SELECT
    p.categoria,
    SUM(p.receita) AS faturamento,
    ROUND(SUM(p.receita) * 100 / (SELECT SUM(faturamento) FROM vw_desempenho_vendedores), 2) AS percentual
FROM vw_desempenho_produtos p
GROUP BY p.categoria
ORDER BY faturamento DESC;


-- QUESTOES DE ANALISE
--
-- 1) Vantagem de modificar a VIEW em vez de cada relatorio:
--    A regra de negocio fica centralizada em um unico ponto. Na Missao 6 bastou um
--    CREATE OR REPLACE VIEW para todos os relatorios passarem a ter o desconto disponivel,
--    sem editar nenhuma consulta. Menos retrabalho, menos risco de um relatorio ficar com
--    regra diferente do outro e uma unica definicao oficial de "faturamento".
--
-- 2) Diferenca entre consultar a tabela original e a VIEW:
--    A tabela guarda os dados brutos, com todos os registros e sem regras aplicadas
--    (inclui pedidos cancelados/pendentes, sem calculo de desconto). A VIEW e uma consulta
--    salva: entrega os dados ja filtrados, relacionados e calculados, com nomes amigaveis.
--    Para quem consulta, ela se comporta como uma tabela, mas esconde a complexidade dos JOINs.
--
-- 3) A VIEW tradicional armazena os resultados?
--    Nao. Ela armazena apenas a definicao (o SELECT). A cada consulta o banco executa
--    essa definicao sobre as tabelas de origem, entao qualquer INSERT, UPDATE ou DELETE
--    nas tabelas aparece imediatamente na VIEW. Ex.: se o pedido 108 passar de 'Pendente'
--    para 'Faturado', ele entra automaticamente em todas as views e relatorios.
--    (Quem armazena fisicamente e a view materializada, que o MySQL nao possui nativamente.)
--
-- 4) Se uma VIEW usada pelos relatorios for excluida:
--    Os relatorios que a consultam passam a falhar com erro de objeto inexistente, e as
--    views construidas sobre ela ficam invalidas. Aqui, um DROP em vw_vendas_detalhadas
--    quebraria as outras tres views e praticamente todos os relatorios. Os dados das
--    tabelas nao sao perdidos, apenas a camada de consulta.
--
-- 5) Quando o excesso de VIEWS atrapalha:
--    - Views empilhadas em muitos niveis dificultam entender de onde vem cada numero
--      e rastrear erros;
--    - Alterar uma view base pode quebrar ou mudar silenciosamente varias dependentes;
--    - Views com agregacoes (GROUP BY, DISTINCT) nao aproveitam bem indices quando filtradas
--      por fora e podem obrigar o banco a processar toda a base a cada consulta;
--    - Views muito parecidas, criadas para cada relatorio, geram duplicidade de regra
--      e voltam ao problema que se queria resolver;
--    - Relatorios que precisam de poucas colunas acabam executando JOINs desnecessarios.


-- PARECER GERENCIAL
--
-- A TechMarket faturou R$ 27.452,00 em 10 pedidos efetivados em setembro/2026. A receita e
-- muito concentrada: o Notebook Pro sozinho gera 59,83% do faturamento, enquanto perifericos
-- e acessorios vendem mais unidades mas pesam pouco no resultado. A equipe Sudeste fatura mais
-- (R$ 16.541,00) com menos pedidos e ticket medio de R$ 4.135,25, mais que o dobro do Sul
-- (R$ 1.818,50), mas depende de um unico vendedor: Juliana Ferreira nao possui vendas faturadas.
-- Ricardo Oliveira lidera em faturamento e tambem em desconto concedido (R$ 1.459,00), o que
-- merece acompanhamento da politica comercial. Na carteira, Felipe Costa e Ana Souza sao VIP e
-- estao acima da media; tres clientes do cadastro ainda nao compraram, e dois deles possuem
-- pedidos cancelado (R$ 4.500,00) e pendente (R$ 720,00), oportunidades claras para a campanha
-- de fidelizacao, especialmente no Parana, onde metade dos 4 clientes ainda nao comprou.
