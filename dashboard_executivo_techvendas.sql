-- CHALLENGE NIGHT - DASHBOARD EXECUTIVO DA TECHVENDAS S/A
-- 15 KPIs para apoiar decisões estratégicas da diretoria
-- Cenário: TechVendas S/A (mesmas 5 tabelas dos exercícios
-- anteriores: clientes, vendedores, produtos, vendas, itens_venda)

USE db_aula_innerjoin;


-- ============================================================
-- KPI 01 - Clientes Inativos
-- ------------------------------------------------------------
-- Objetivo: medir quantos clientes cadastrados nunca fizeram
-- nenhuma compra, para dimensionar o público-alvo de campanhas
-- de reativação.
-- Requisitos usados: CTE, LEFT JOIN, COUNT.
-- ============================================================

WITH clientes_sem_compra AS (
    SELECT
        c.id_cliente
    FROM clientes AS c
    LEFT JOIN vendas AS v
        ON c.id_cliente = v.id_cliente
    WHERE v.id_venda IS NULL
)
SELECT
    COUNT(*) AS quantidade_clientes_inativos
FROM clientes_sem_compra;

-- Interpretação: 45 dos 50 clientes cadastrados (90%) nunca compraram.
-- É um volume alto de contatos "frios" — a diretoria pode priorizar
-- uma campanha de reativação antes de investir em captação de clientes
-- totalmente novos.


-- ============================================================
-- KPI 02 - Taxa de Conversão de Clientes
-- ------------------------------------------------------------
-- Objetivo: comparar a base total de clientes cadastrados com a
-- base que efetivamente já comprou, revelando o quanto do
-- cadastro está sendo aproveitado comercialmente.
-- Requisitos usados: CTE (duas encadeadas), COUNT, COUNT(DISTINCT).
-- ============================================================

WITH total_clientes AS (
    SELECT COUNT(*) AS qtd_total
    FROM clientes
),
clientes_compradores AS (
    SELECT COUNT(DISTINCT id_cliente) AS qtd_compradores
    FROM vendas
)
SELECT
    tc.qtd_total AS total_clientes_cadastrados,
    cc.qtd_compradores AS total_clientes_compradores,
    ROUND(cc.qtd_compradores * 100.0 / tc.qtd_total, 2) AS taxa_conversao_percentual
FROM total_clientes AS tc
CROSS JOIN clientes_compradores AS cc;

-- Interpretação: apenas 10% da base (5 de 50 clientes) já comprou.
-- Esse número, junto ao KPI 01, confirma que o funil de conversão é o
-- principal gargalo comercial da empresa, não a captação de cadastros.


-- ============================================================
-- KPI 03 - Vendedores sem Vendas Registradas
-- ------------------------------------------------------------
-- Objetivo: identificar quantos vendedores do time comercial
-- ainda não fecharam nenhuma venda, para direcionar treinamento
-- ou redistribuição de carteira.
-- Requisitos usados: CTE, LEFT JOIN, COUNT.
-- ============================================================

WITH vendedores_sem_venda AS (
    SELECT
        vd.id_vendedor
    FROM vendedores AS vd
    LEFT JOIN vendas AS v
        ON vd.id_vendedor = v.id_vendedor
    WHERE v.id_venda IS NULL
)
SELECT
    COUNT(*) AS quantidade_vendedores_sem_vendas
FROM vendedores_sem_venda;

-- Interpretação: 30 dos 50 vendedores cadastrados (60%) nunca venderam.
-- Isso pode indicar equipe superdimensionada, vendedores recém-
-- contratados ainda sem carteira, ou setores/canais pouco ativos.


-- ============================================================
-- KPI 04 - Produtos sem Giro
-- ------------------------------------------------------------
-- Objetivo: apontar quantos produtos do catálogo nunca foram
-- vendidos, sinalizando itens parados no estoque.
-- Requisitos usados: CTE, LEFT JOIN, COUNT.
-- ============================================================

WITH produtos_sem_giro AS (
    SELECT
        p.id_produto
    FROM produtos AS p
    LEFT JOIN itens_venda AS iv
        ON p.id_produto = iv.id_produto
    WHERE iv.id_item IS NULL
)
SELECT
    COUNT(*) AS quantidade_produtos_sem_giro
FROM produtos_sem_giro;

-- Interpretação: 10 dos 50 produtos cadastrados (20% do catálogo)
-- nunca tiveram uma única venda registrada. São candidatos a revisão
-- de preço, campanha promocional ou até descontinuação.


-- ============================================================
-- KPI 05 - Concentração de Receita nos Top 5 Clientes
-- ------------------------------------------------------------
-- Objetivo: medir o quanto do faturamento total depende dos
-- clientes mais importantes, avaliando o risco de concentração
-- de receita.
-- Requisitos usados: CTE (duas encadeadas), INNER JOIN, SUM,
-- ORDER BY.
-- ============================================================

WITH faturamento_por_cliente AS (
    SELECT
        c.id_cliente,
        c.nome_cliente,
        SUM(v.valor_total) AS faturamento_cliente
    FROM clientes AS c
    INNER JOIN vendas AS v
        ON c.id_cliente = v.id_cliente
    GROUP BY
        c.id_cliente,
        c.nome_cliente
),
total_geral AS (
    SELECT
        SUM(faturamento_cliente) AS faturamento_total
    FROM faturamento_por_cliente
)
SELECT
    fc.nome_cliente,
    fc.faturamento_cliente,
    ROUND(fc.faturamento_cliente * 100.0 / tg.faturamento_total, 2) AS percentual_do_faturamento
FROM faturamento_por_cliente AS fc
CROSS JOIN total_geral AS tg
ORDER BY fc.faturamento_cliente DESC
LIMIT 5;

-- Interpretação: como só 5 clientes compraram até hoje, o Top 5 concentra
-- 100% do faturamento — liderado por Daniela Reis (22,17%). Perder
-- qualquer um desses clientes tem impacto direto e imediato na receita
-- total da empresa.


-- ============================================================
-- KPI 06 - Ticket Médio por Forma de Pagamento
-- ------------------------------------------------------------
-- Objetivo: comparar o valor médio das vendas conforme a forma de
-- pagamento utilizada, apoiando decisões sobre taxas e incentivos
-- de pagamento.
-- Requisitos usados: AVG, COUNT, GROUP BY, ORDER BY.
-- ============================================================

SELECT
    v.forma_pagamento,
    COUNT(*) AS quantidade_vendas,
    AVG(v.valor_total) AS ticket_medio
FROM vendas AS v
GROUP BY v.forma_pagamento
ORDER BY ticket_medio DESC;

-- Interpretação: "Dinheiro" tem o maior ticket médio (R$ 2.382,42) e
-- "Pix" o menor (R$ 1.970,08). A diferença é pequena entre as formas,
-- então a forma de pagamento não parece influenciar fortemente o
-- valor da compra neste recorte.


-- ============================================================
-- KPI 07 - Amplitude de Valor de Venda por Vendedor
-- ------------------------------------------------------------
-- Objetivo: entender a variação entre a menor e a maior venda de
-- cada vendedor, revelando consistência (ou inconsistência) de
-- desempenho individual.
-- Requisitos usados: INNER JOIN, MIN, MAX, COUNT, GROUP BY,
-- ORDER BY.
-- ============================================================

SELECT
    vd.nome_vendedor,
    COUNT(v.id_venda) AS quantidade_vendas,
    MIN(v.valor_total) AS menor_venda,
    MAX(v.valor_total) AS maior_venda
FROM vendedores AS vd
INNER JOIN vendas AS v
    ON vd.id_vendedor = v.id_vendedor
GROUP BY
    vd.id_vendedor,
    vd.nome_vendedor
ORDER BY maior_venda DESC;

-- Interpretação: Breno Paiva tem a maior venda individual do time
-- (R$ 4.853,30) mas apenas 2 vendas no total. Vendedores com grande
-- amplitude entre menor e maior venda podem se beneficiar de
-- estratégias de upsell para elevar o piso, não só o teto.


-- ============================================================
-- KPI 08 - Diversidade de Categorias Vendidas por Vendedor
-- ------------------------------------------------------------
-- Objetivo: medir em quantas categorias de produto diferentes
-- cada vendedor já vendeu, indicando quão generalista ou
-- especializado é o seu portfólio de vendas.
-- Requisitos usados: INNER JOIN (múltiplo), COUNT(DISTINCT),
-- GROUP BY, ORDER BY.
-- ============================================================

SELECT
    vd.nome_vendedor,
    COUNT(DISTINCT p.categoria) AS categorias_distintas_vendidas
FROM vendedores AS vd
INNER JOIN vendas AS v
    ON vd.id_vendedor = v.id_vendedor
INNER JOIN itens_venda AS iv
    ON v.id_venda = iv.id_venda
INNER JOIN produtos AS p
    ON iv.id_produto = p.id_produto
GROUP BY
    vd.id_vendedor,
    vd.nome_vendedor
ORDER BY categorias_distintas_vendidas DESC;

-- Interpretação: todos os 20 vendedores ativos venderam produtos de
-- exatamente 2 categorias diferentes. O padrão uniforme sugere que,
-- hoje, a distribuição de produtos entre vendedores segue um rodízio
-- fixo em vez de especialização por categoria.


-- ============================================================
-- KPI 09 - Taxa de Cancelamento por Vendedor
-- ------------------------------------------------------------
-- Objetivo: apontar o percentual de vendas canceladas de cada
-- vendedor, ajudando a identificar processos de venda com
-- problemas de qualidade ou de fechamento.
-- Requisitos usados: CTE, INNER JOIN, COUNT, GROUP BY, ORDER BY.
-- ============================================================

WITH vendas_por_vendedor AS (
    SELECT
        vd.id_vendedor,
        vd.nome_vendedor,
        COUNT(v.id_venda) AS total_vendas,
        SUM(CASE WHEN v.status = 'Cancelada' THEN 1 ELSE 0 END) AS vendas_canceladas
    FROM vendedores AS vd
    INNER JOIN vendas AS v
        ON vd.id_vendedor = v.id_vendedor
    GROUP BY
        vd.id_vendedor,
        vd.nome_vendedor
)
SELECT
    nome_vendedor,
    total_vendas,
    vendas_canceladas,
    ROUND(vendas_canceladas * 100.0 / total_vendas, 2) AS taxa_cancelamento_percentual
FROM vendas_por_vendedor
ORDER BY taxa_cancelamento_percentual DESC;

-- Interpretação: 4 vendedores (Elaine Braga, Jorge Cunha, Patrícia
-- Alves e Yuri Bastos) têm 100% de cancelamento — todas as vendas que
-- fizeram foram canceladas. Vale investigar se há um problema comum
-- (canal, forma de pagamento ou script de venda) associado a esses
-- vendedores.


-- ============================================================
-- KPI 10 - Recência de Compra por Cliente
-- ------------------------------------------------------------
-- Objetivo: calcular há quantos dias cada cliente fez sua última
-- compra, apoiando ações de retenção antes que o cliente se torne
-- inativo.
-- Requisitos usados: CTE, LEFT JOIN, MAX.
-- ============================================================

WITH ultima_compra AS (
    SELECT
        c.id_cliente,
        c.nome_cliente,
        MAX(v.data_venda) AS data_ultima_compra
    FROM clientes AS c
    LEFT JOIN vendas AS v
        ON c.id_cliente = v.id_cliente
    GROUP BY
        c.id_cliente,
        c.nome_cliente
)
SELECT
    nome_cliente,
    data_ultima_compra,
    DATEDIFF(CURDATE(), data_ultima_compra) AS dias_desde_ultima_compra
FROM ultima_compra
ORDER BY data_ultima_compra DESC;

-- Interpretação: entre os 5 clientes que já compraram, a recência varia
-- de 58 a 74 dias desde a última compra (base em 27/08/2026). Os demais
-- 45 clientes aparecem com data e recência em branco (NULL), o que
-- identifica visualmente, no próprio relatório, quem nunca comprou.


-- ============================================================
-- KPI 11 - Vendedores Acima da Média de Faturamento da Equipe
-- ------------------------------------------------------------
-- Objetivo: comparar o faturamento de cada vendedor ativo com a
-- média da equipe, destacando quem está performando acima do
-- esperado.
-- Requisitos usados: CTE (duas encadeadas), INNER JOIN, SUM, AVG,
-- GROUP BY, ORDER BY.
-- ============================================================

WITH faturamento_vendedor AS (
    SELECT
        vd.id_vendedor,
        vd.nome_vendedor,
        SUM(v.valor_total) AS faturamento_total
    FROM vendedores AS vd
    INNER JOIN vendas AS v
        ON vd.id_vendedor = v.id_vendedor
    GROUP BY
        vd.id_vendedor,
        vd.nome_vendedor
),
media_equipe AS (
    SELECT
        AVG(faturamento_total) AS media_faturamento
    FROM faturamento_vendedor
)
SELECT
    fv.nome_vendedor,
    fv.faturamento_total,
    me.media_faturamento,
    fv.faturamento_total - me.media_faturamento AS diferenca_para_media
FROM faturamento_vendedor AS fv
CROSS JOIN media_equipe AS me
WHERE fv.faturamento_total > me.media_faturamento
ORDER BY fv.faturamento_total DESC;

-- Interpretação: a média de faturamento entre os 20 vendedores ativos é
-- de R$ 5.372,44. Onze deles (mais da metade dos ativos) estão acima
-- dessa média, com destaque para Jorge Cunha (R$ 8.110,50) — um bom
-- candidato a mentor de vendas para o restante do time.


-- ============================================================
-- KPI 12 - Abrangência de Carteira por Vendedor
-- ------------------------------------------------------------
-- Objetivo: verificar quantos clientes distintos cada vendedor
-- atende, identificando dependência de poucos clientes por
-- vendedor.
-- Requisitos usados: INNER JOIN, COUNT, COUNT(DISTINCT),
-- GROUP BY, ORDER BY.
-- ============================================================

SELECT
    vd.nome_vendedor,
    COUNT(v.id_venda) AS quantidade_vendas,
    COUNT(DISTINCT v.id_cliente) AS clientes_distintos_atendidos
FROM vendedores AS vd
INNER JOIN vendas AS v
    ON vd.id_vendedor = v.id_vendedor
GROUP BY
    vd.id_vendedor,
    vd.nome_vendedor
ORDER BY clientes_distintos_atendidos DESC;

-- Interpretação: todos os 20 vendedores ativos atendem a apenas 1
-- cliente distinto cada, mesmo alguns tendo 2 ou 3 vendas. Isso mostra
-- que a carteira de clientes está extremamente concentrada por
-- vendedor — um risco caso esse cliente único deixe de comprar.


-- ============================================================
-- KPI 13 - Faturamento Líquido por Categoria
-- ------------------------------------------------------------
-- Objetivo: calcular a receita líquida (já descontados os
-- descontos aplicados) gerada por cada categoria de produto,
-- apoiando decisões de sortimento e precificação.
-- Requisitos usados: INNER JOIN, SUM, GROUP BY, ORDER BY.
-- ============================================================

SELECT
    p.categoria,
    SUM(iv.quantidade * iv.valor_unitario * (1 - iv.desconto / 100)) AS faturamento_liquido
FROM produtos AS p
INNER JOIN itens_venda AS iv
    ON p.id_produto = iv.id_produto
GROUP BY p.categoria
ORDER BY faturamento_liquido DESC;

-- Interpretação: "Eletrodomésticos" (R$ 38.451,49) e "Informática"
-- (R$ 27.939,64) concentram a maior parte da receita líquida, juntas
-- somando mais de 65% do faturamento das categorias com venda. Isso
-- reforça onde a empresa deveria focar reposição de estoque e
-- campanhas de marketing.


-- ============================================================
-- KPI 14 - Percentual de Itens Vendidos com Desconto Aplicado
-- ------------------------------------------------------------
-- Objetivo: medir a proporção de itens vendidos que saíram com
-- algum desconto, apoiando a política comercial de descontos.
-- Requisitos usados: CTE, COUNT, SUM.
-- ============================================================

WITH itens_classificados AS (
    SELECT
        id_item,
        CASE WHEN desconto > 0 THEN 1 ELSE 0 END AS com_desconto
    FROM itens_venda
)
SELECT
    COUNT(*) AS total_itens,
    SUM(com_desconto) AS itens_com_desconto,
    ROUND(SUM(com_desconto) * 100.0 / COUNT(*), 2) AS percentual_com_desconto
FROM itens_classificados;

-- Interpretação: 80% dos itens vendidos (40 de 50) saíram com algum
-- percentual de desconto. Esse volume alto merece uma análise de
-- margem: a empresa pode estar concedendo desconto além do necessário
-- para fechar vendas.


-- ============================================================
-- KPI 15 - Produtos com Maior Ticket Médio por Item Vendido
-- ------------------------------------------------------------
-- Objetivo: destacar os produtos com maior valor médio por item
-- vendido, apoiando decisões sobre quais itens priorizar em
-- vitrines e campanhas de maior margem.
-- Requisitos usados: INNER JOIN, AVG, COUNT, GROUP BY, ORDER BY.
-- ============================================================

SELECT
    p.nome_produto,
    p.categoria,
    COUNT(iv.id_item) AS vezes_vendido,
    AVG(iv.valor_unitario) AS ticket_medio_item
FROM produtos AS p
INNER JOIN itens_venda AS iv
    ON p.id_produto = iv.id_produto
GROUP BY
    p.id_produto,
    p.nome_produto,
    p.categoria
ORDER BY ticket_medio_item DESC
LIMIT 10;

-- Interpretação: o "Notebook Pro 14" lidera com ticket médio de
-- R$ 4.369,90 por item e já foi vendido 2 vezes — é o produto de maior
-- valor agregado por unidade entre os que giram, um bom candidato a
-- destaque em campanhas de alto ticket.
