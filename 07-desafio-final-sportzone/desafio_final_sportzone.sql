-- ============================================================
-- DESAFIO FINAL DO SEMESTRE - BANCO DE DADOS II
-- EMPRESA: SPORTZONE
-- RELATORIO GERENCIAL EXECUTIVO
-- ============================================================
-- Todas as consultas abaixo foram testadas e validadas contra
-- a base gerada pelo arquivo DDL_desafio_final.sql
-- ============================================================

USE sportzone;


-- ============================================================
-- PARTE 1 - ANALISE DE CLIENTES
-- Objetivo:
-- Apresentar, para cada cliente, quantidade de compras,
-- produtos adquiridos, valor gasto, ticket medio e data da
-- ultima compra. Todos os clientes aparecem, inclusive os
-- que nunca compraram (LEFT JOIN + COALESCE).
-- ============================================================

SELECT
    c.nome AS cliente,
    c.cidade,
    c.renda,
    COUNT(DISTINCT v.id_venda) AS qtd_compras,
    COALESCE(SUM(iv.quantidade), 0) AS qtd_produtos_adquiridos,
    COALESCE(SUM(iv.quantidade * iv.preco_unitario), 0) AS valor_total_gasto,
    CASE
        WHEN COUNT(DISTINCT v.id_venda) = 0 THEN NULL
        ELSE ROUND(SUM(iv.quantidade * iv.preco_unitario) / COUNT(DISTINCT v.id_venda), 2)
    END AS ticket_medio,
    MAX(v.data_venda) AS data_ultima_compra
FROM clientes c
LEFT JOIN vendas v
    ON v.id_cliente = c.id_cliente
LEFT JOIN itens_venda iv
    ON iv.id_venda = v.id_venda
GROUP BY c.id_cliente, c.nome, c.cidade, c.renda
ORDER BY valor_total_gasto DESC;


-- ============================================================
-- PARTE 2 - ANALISE DE PRODUTOS
-- Objetivo:
-- Apresentar, para cada produto, preco atual, estoque,
-- quantidade vendida, faturamento gerado e quantidade de
-- clientes diferentes que compraram. Todos os produtos
-- aparecem, inclusive os que nunca foram vendidos.
-- ============================================================

SELECT
    p.nome AS produto,
    p.preco AS preco_atual,
    p.estoque,
    COALESCE(SUM(iv.quantidade), 0) AS qtd_total_vendida,
    COALESCE(SUM(iv.quantidade * iv.preco_unitario), 0) AS faturamento_gerado,
    COUNT(DISTINCT v.id_cliente) AS qtd_clientes_diferentes
FROM produtos p
LEFT JOIN itens_venda iv
    ON iv.id_produto = p.id_produto
LEFT JOIN vendas v
    ON v.id_venda = iv.id_venda
GROUP BY p.id_produto, p.nome, p.preco, p.estoque
ORDER BY faturamento_gerado DESC;


-- ============================================================
-- PARTE 3 - ANALISE DE VENDEDORES
-- Objetivo:
-- Apresentar, para cada vendedor, quantidade de vendas,
-- clientes atendidos, produtos vendidos, faturamento e
-- ticket medio. Todos os vendedores aparecem, inclusive os
-- que ainda nao venderam nada.
-- ============================================================

SELECT
    vd.nome AS vendedor,
    COUNT(DISTINCT v.id_venda) AS qtd_vendas,
    COUNT(DISTINCT v.id_cliente) AS qtd_clientes_diferentes,
    COALESCE(SUM(iv.quantidade), 0) AS qtd_produtos_vendidos,
    COALESCE(SUM(iv.quantidade * iv.preco_unitario), 0) AS faturamento_total,
    CASE
        WHEN COUNT(DISTINCT v.id_venda) = 0 THEN NULL
        ELSE ROUND(SUM(iv.quantidade * iv.preco_unitario) / COUNT(DISTINCT v.id_venda), 2)
    END AS ticket_medio
FROM vendedores vd
LEFT JOIN vendas v
    ON v.id_vendedor = vd.id_vendedor
LEFT JOIN itens_venda iv
    ON iv.id_venda = v.id_venda
GROUP BY vd.id_vendedor, vd.nome
ORDER BY faturamento_total DESC;


-- ============================================================
-- PARTE 4 - KPIS GERENCIAIS OBRIGATORIOS
-- ============================================================

-- ------------------------------------------------------------
-- KPI 01 - Qual cliente mais gastou na SportZone?
-- ------------------------------------------------------------
SELECT
    c.nome AS cliente,
    ROUND(SUM(iv.quantidade * iv.preco_unitario), 2) AS total_gasto
FROM clientes c
INNER JOIN vendas v
    ON v.id_cliente = c.id_cliente
INNER JOIN itens_venda iv
    ON iv.id_venda = v.id_venda
GROUP BY c.id_cliente, c.nome
ORDER BY total_gasto DESC
LIMIT 1;

-- ------------------------------------------------------------
-- KPI 02 - Qual cliente realizou a maior quantidade de compras?
-- ------------------------------------------------------------
SELECT
    c.nome AS cliente,
    COUNT(DISTINCT v.id_venda) AS qtd_compras
FROM clientes c
INNER JOIN vendas v
    ON v.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nome
ORDER BY qtd_compras DESC
LIMIT 5;

-- ------------------------------------------------------------
-- KPI 03 - Qual produto teve a maior quantidade de unidades vendidas?
-- ------------------------------------------------------------
SELECT
    p.nome AS produto,
    SUM(iv.quantidade) AS qtd_vendida
FROM produtos p
INNER JOIN itens_venda iv
    ON iv.id_produto = p.id_produto
GROUP BY p.id_produto, p.nome
ORDER BY qtd_vendida DESC
LIMIT 1;

-- ------------------------------------------------------------
-- KPI 04 - Qual produto gerou o maior faturamento?
-- ------------------------------------------------------------
SELECT
    p.nome AS produto,
    ROUND(SUM(iv.quantidade * iv.preco_unitario), 2) AS faturamento
FROM produtos p
INNER JOIN itens_venda iv
    ON iv.id_produto = p.id_produto
GROUP BY p.id_produto, p.nome
ORDER BY faturamento DESC
LIMIT 1;

-- ------------------------------------------------------------
-- KPI 05 - Quais produtos nunca foram vendidos?
-- ------------------------------------------------------------
SELECT
    p.nome AS produto,
    p.categoria,
    p.estoque
FROM produtos p
WHERE NOT EXISTS (
    SELECT 1
    FROM itens_venda iv
    WHERE iv.id_produto = p.id_produto
);

-- ------------------------------------------------------------
-- KPI 06 - Qual vendedor realizou a maior quantidade de vendas?
-- ------------------------------------------------------------
SELECT
    vd.nome AS vendedor,
    COUNT(v.id_venda) AS qtd_vendas
FROM vendedores vd
INNER JOIN vendas v
    ON v.id_vendedor = vd.id_vendedor
GROUP BY vd.id_vendedor, vd.nome
ORDER BY qtd_vendas DESC
LIMIT 1;

-- ------------------------------------------------------------
-- KPI 07 - Qual vendedor gerou o maior faturamento?
-- ------------------------------------------------------------
SELECT
    vd.nome AS vendedor,
    ROUND(SUM(iv.quantidade * iv.preco_unitario), 2) AS faturamento
FROM vendedores vd
INNER JOIN vendas v
    ON v.id_vendedor = vd.id_vendedor
INNER JOIN itens_venda iv
    ON iv.id_venda = v.id_venda
GROUP BY vd.id_vendedor, vd.nome
ORDER BY faturamento DESC
LIMIT 1;

-- ------------------------------------------------------------
-- KPI 08 - Quantos clientes nunca realizaram uma compra?
-- ------------------------------------------------------------
SELECT
    COUNT(*) AS qtd_clientes_sem_compra
FROM clientes c
WHERE NOT EXISTS (
    SELECT 1
    FROM vendas v
    WHERE v.id_cliente = c.id_cliente
);

-- ------------------------------------------------------------
-- KPI 09 - Qual foi o faturamento total da empresa?
-- ------------------------------------------------------------
SELECT
    ROUND(SUM(iv.quantidade * iv.preco_unitario), 2) AS faturamento_total
FROM itens_venda iv;

-- ------------------------------------------------------------
-- KPI 10 - Qual e o ticket medio geral das vendas?
-- ------------------------------------------------------------
SELECT
    ROUND(SUM(iv.quantidade * iv.preco_unitario) / COUNT(DISTINCT v.id_venda), 2) AS ticket_medio_geral
FROM vendas v
INNER JOIN itens_venda iv
    ON iv.id_venda = v.id_venda;


-- ============================================================
-- PARTE 5 - KPIS CRIADOS PELA DUPLA
-- ============================================================

-- ------------------------------------------------------------
-- KPI 11 - Concentracao de Faturamento nos Top 3 Clientes
-- Area interessada: Diretoria / Financeiro
-- ------------------------------------------------------------
WITH gasto_cliente AS (
    SELECT
        c.id_cliente,
        c.nome,
        SUM(iv.quantidade * iv.preco_unitario) AS total_gasto
    FROM clientes c
    INNER JOIN vendas v
        ON v.id_cliente = c.id_cliente
    INNER JOIN itens_venda iv
        ON iv.id_venda = v.id_venda
    GROUP BY c.id_cliente, c.nome
),
top3 AS (
    SELECT total_gasto
    FROM gasto_cliente
    ORDER BY total_gasto DESC
    LIMIT 3
)
SELECT
    ROUND((SELECT SUM(total_gasto) FROM top3), 2) AS faturamento_top3,
    ROUND((SELECT SUM(total_gasto) FROM gasto_cliente), 2) AS faturamento_total_clientes,
    ROUND((SELECT SUM(total_gasto) FROM top3) * 100.0 / (SELECT SUM(total_gasto) FROM gasto_cliente), 2) AS percentual_top3;

-- ------------------------------------------------------------
-- KPI 12 - Produtos com Estoque Alto e Baixa Saida
-- Area interessada: Estoque / Compras
-- ------------------------------------------------------------
SELECT
    p.nome AS produto,
    p.categoria,
    p.estoque,
    COALESCE(SUM(iv.quantidade), 0) AS qtd_vendida
FROM produtos p
LEFT JOIN itens_venda iv
    ON iv.id_produto = p.id_produto
GROUP BY p.id_produto, p.nome, p.categoria, p.estoque
HAVING p.estoque >= 20 AND COALESCE(SUM(iv.quantidade), 0) <= 5
ORDER BY p.estoque DESC;

-- ------------------------------------------------------------
-- KPI 13 - Faturamento por Faixa de Renda dos Clientes Ativos
-- Area interessada: Marketing
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN c.renda BETWEEN 0 AND 5000 THEN 'Ate R$ 5.000'
        WHEN c.renda BETWEEN 5000.01 AND 8000 THEN 'De R$ 5.000 a R$ 8.000'
        ELSE 'Acima de R$ 8.000'
    END AS faixa_renda,
    COUNT(DISTINCT c.id_cliente) AS qtd_clientes,
    ROUND(SUM(iv.quantidade * iv.preco_unitario), 2) AS faturamento_faixa
FROM clientes c
INNER JOIN vendas v
    ON v.id_cliente = c.id_cliente
INNER JOIN itens_venda iv
    ON iv.id_venda = v.id_venda
GROUP BY faixa_renda
ORDER BY faturamento_faixa DESC;

-- ------------------------------------------------------------
-- KPI 14 - Combinacoes de Cidade e Categoria Sem Nenhuma Venda
-- Area interessada: Marketing / Comercial
-- ------------------------------------------------------------
WITH cidades AS (
    SELECT DISTINCT cidade FROM clientes
),
categorias AS (
    SELECT DISTINCT categoria FROM produtos
)
SELECT
    ci.cidade,
    ca.categoria
FROM cidades ci
CROSS JOIN categorias ca
WHERE NOT EXISTS (
    SELECT 1
    FROM vendas v
    INNER JOIN clientes c ON c.id_cliente = v.id_cliente
    INNER JOIN itens_venda iv ON iv.id_venda = v.id_venda
    INNER JOIN produtos p ON p.id_produto = iv.id_produto
    WHERE c.cidade = ci.cidade AND p.categoria = ca.categoria
)
ORDER BY ci.cidade, ca.categoria;

-- ------------------------------------------------------------
-- KPI 15 - Comparativo Entre o Melhor e o Pior Vendedor (faturamento)
-- Area interessada: Diretoria Comercial
-- ------------------------------------------------------------
WITH faturamento_vendedor AS (
    SELECT
        vd.nome,
        ROUND(SUM(iv.quantidade * iv.preco_unitario), 2) AS faturamento
    FROM vendedores vd
    INNER JOIN vendas v
        ON v.id_vendedor = vd.id_vendedor
    INNER JOIN itens_venda iv
        ON iv.id_venda = v.id_venda
    GROUP BY vd.id_vendedor, vd.nome
)
SELECT posicao, nome, faturamento FROM (
    SELECT 'Melhor desempenho' AS posicao, nome, faturamento
    FROM faturamento_vendedor
    ORDER BY faturamento DESC
    LIMIT 1
) AS melhor
UNION
SELECT posicao, nome, faturamento FROM (
    SELECT 'Pior desempenho' AS posicao, nome, faturamento
    FROM faturamento_vendedor
    ORDER BY faturamento ASC
    LIMIT 1
) AS pior;
