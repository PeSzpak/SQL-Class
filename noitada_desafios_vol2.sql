-- ============================================================
-- NOITADA DE DESAFIOS VOL.2 — TechVendas S/A
-- Base: mesmas 5 tabelas dos exercícios anteriores (clientes,
-- vendedores, produtos, vendas, itens_venda).
-- Sintaxe: MySQL 8+ (compatível com PostgreSQL 12+, com pequenos
-- ajustes de sintaxe onde indicado nos comentários).
-- Todas as consultas foram testadas contra a base real.
-- ============================================================

USE db_aula_innerjoin;


-- ============================================================
-- Tabelas adicionais para os Exercícios 12 e 13 (fusão de empresas)
-- ------------------------------------------------------------
-- clientes_techvendas é uma cópia da tabela clientes já existente.
-- clientes_empresa_adquirida é uma base fictícia da empresa
-- comprada pela TechVendas, com 15 clientes que já existiam na
-- TechVendas (mesmo nome) e 15 clientes exclusivos dela — o
-- suficiente para demonstrar as três situações de uma fusão real:
-- só na base antiga, só na base nova, ou em ambas.
-- ============================================================

DROP TABLE IF EXISTS clientes_techvendas;
DROP TABLE IF EXISTS clientes_empresa_adquirida;

CREATE TABLE clientes_techvendas (
    id_cliente      INT           PRIMARY KEY,
    nome_cliente    VARCHAR(100)  NOT NULL,
    cidade          VARCHAR(80)   NOT NULL,
    estado          CHAR(2)       NOT NULL
);

INSERT INTO clientes_techvendas (id_cliente, nome_cliente, cidade, estado)
SELECT id_cliente, nome_cliente, cidade, estado FROM clientes;

CREATE TABLE clientes_empresa_adquirida (
    id_cliente_adq  INT           PRIMARY KEY,
    nome_cliente    VARCHAR(100)  NOT NULL,
    cidade          VARCHAR(80)   NOT NULL,
    estado          CHAR(2)       NOT NULL
);

INSERT INTO clientes_empresa_adquirida (id_cliente_adq, nome_cliente, cidade, estado) VALUES
    -- 15 clientes que também existem na TechVendas (mesmo nome)
    (1, 'Gabriela Costa', 'Araucária', 'PR'),
    (2, 'Nicolas Santos', 'Curitiba', 'PR'),
    (3, 'Úrsula Freitas', 'Mandirituba', 'PR'),
    (4, 'Daniela Reis', 'Itajaí', 'SC'),
    (5, 'Kaique Batista', 'Belo Horizonte', 'MG'),
    (6, 'Ana Souza', 'Curitiba', 'PR'),
    (7, 'Bruno Lima', 'São José dos Pinhais', 'PR'),
    (8, 'Carla Mendes', 'Curitiba', 'PR'),
    (9, 'Diego Martins', 'Colombo', 'PR'),
    (10, 'Eduarda Alves', 'Pinhais', 'PR'),
    (11, 'Felipe Rocha', 'Curitiba', 'PR'),
    (12, 'Henrique Silva', 'Curitiba', 'PR'),
    (13, 'Isabela Nunes', 'Campo Largo', 'PR'),
    (14, 'João Ribeiro', 'Curitiba', 'PR'),
    (15, 'Karen Oliveira', 'Piraquara', 'PR'),
    -- 15 clientes exclusivos da empresa adquirida
    (16, 'Rogerio Nascimento', 'São Paulo', 'SP'),
    (17, 'Patricia Andrade', 'Campinas', 'SP'),
    (18, 'Leonardo Farias', 'Ribeirão Preto', 'SP'),
    (19, 'Camila Bezerra', 'Santo André', 'SP'),
    (20, 'Vitor Hugo Sales', 'Osasco', 'SP'),
    (21, 'Beatriz Coutinho', 'Guarulhos', 'SP'),
    (22, 'Rafaela Nogueira', 'Sorocaba', 'SP'),
    (23, 'Eduardo Barreto', 'São Bernardo do Campo', 'SP'),
    (24, 'Michele Cavalcante', 'Santo Amaro', 'SP'),
    (25, 'Anderson Prado', 'Diadema', 'SP'),
    (26, 'Luciana Bittencourt', 'Jundiaí', 'SP'),
    (27, 'Rodrigo Esteves', 'Barueri', 'SP'),
    (28, 'Tatiane Guedes', 'Taboão da Serra', 'SP'),
    (29, 'Fabio Cunha Ramos', 'Mauá', 'SP'),
    (30, 'Vanessa Tavares', 'Cotia', 'SP');


-- ============================================================
-- Exercício 01 — Clientes e Compras
-- ============================================================

SELECT
    c.nome_cliente,
    c.cidade,
    COUNT(v.id_venda) AS quantidade_compras,
    COALESCE(SUM(v.valor_total), 0) AS valor_total_comprado
FROM clientes AS c
LEFT JOIN vendas AS v
    ON c.id_cliente = v.id_cliente
GROUP BY
    c.id_cliente,
    c.nome_cliente,
    c.cidade
ORDER BY valor_total_comprado DESC;

-- Resultado: 50 clientes. Os 5 que já compraram aparecem no topo
-- (Daniela Reis lidera com R$ 23.824,25); os outros 45 aparecem com
-- quantidade_compras = 0 e valor_total_comprado = 0, graças ao
-- LEFT JOIN + COALESCE.


-- ============================================================
-- Exercício 02 — Produtos Comercializados
-- ============================================================

SELECT
    p.nome_produto,
    p.categoria,
    COALESCE(SUM(iv.quantidade), 0) AS quantidade_vendida,
    COALESCE(SUM(iv.quantidade * iv.valor_unitario * (1 - iv.desconto / 100)), 0) AS faturamento
FROM produtos AS p
LEFT JOIN itens_venda AS iv
    ON p.id_produto = iv.id_produto
GROUP BY
    p.id_produto,
    p.nome_produto,
    p.categoria
ORDER BY faturamento DESC;

-- Resultado: 50 produtos. O Notebook Pro 14 lidera o faturamento
-- (R$ 17.479,60); os 10 produtos nunca vendidos aparecem com
-- quantidade_vendida = 0 e faturamento = 0.


-- ============================================================
-- Exercício 03 — Desempenho dos Vendedores
-- ============================================================

SELECT
    vd.nome_vendedor,
    vd.setor,
    COUNT(v.id_venda) AS quantidade_vendas,
    COALESCE(SUM(v.valor_total), 0) AS faturamento
FROM vendedores AS vd
LEFT JOIN vendas AS v
    ON vd.id_vendedor = v.id_vendedor
GROUP BY
    vd.id_vendedor,
    vd.nome_vendedor,
    vd.setor
ORDER BY faturamento DESC;

-- Resultado: 50 vendedores. Jorge Cunha lidera (R$ 8.110,50); os
-- 30 vendedores sem vendas aparecem com quantidade_vendas = 0 e
-- faturamento = 0.


-- ============================================================
-- Exercício 04 — Auditoria de Clientes
-- ============================================================

WITH clientes_compradores AS (
    SELECT DISTINCT id_cliente
    FROM vendas
)
SELECT
    c.id_cliente,
    c.nome_cliente,
    c.cidade
FROM clientes AS c
LEFT JOIN clientes_compradores AS cc
    ON c.id_cliente = cc.id_cliente
WHERE cc.id_cliente IS NULL;

-- Resultado: 45 clientes cadastrados que nunca aparecem na CTE de
-- compradores — ou seja, nunca compraram.


-- ============================================================
-- Exercício 05 — Auditoria de Produtos
-- ============================================================

WITH produtos_vendidos AS (
    SELECT DISTINCT id_produto
    FROM itens_venda
)
SELECT
    p.id_produto,
    p.nome_produto,
    p.categoria
FROM produtos AS p
LEFT JOIN produtos_vendidos AS pv
    ON p.id_produto = pv.id_produto
WHERE pv.id_produto IS NULL;

-- Resultado: 10 produtos que nunca apareceram na CTE de vendidos,
-- concentrados nas categorias Segurança, Casa Inteligente,
-- Acessórios e um item de TV e Vídeo.


-- ============================================================
-- Exercício 06 — Ranking Comercial
-- ============================================================

WITH faturamento_vendedor AS (
    SELECT
        vd.id_vendedor,
        vd.nome_vendedor,
        COALESCE(SUM(v.valor_total), 0) AS faturamento
    FROM vendedores AS vd
    LEFT JOIN vendas AS v
        ON vd.id_vendedor = v.id_vendedor
    GROUP BY
        vd.id_vendedor,
        vd.nome_vendedor
)
SELECT
    nome_vendedor,
    faturamento,
    CASE
        WHEN faturamento = 0 THEN 'Sem vendas'
        WHEN faturamento >= 6000 THEN 'Excelente'
        WHEN faturamento >= 4000 THEN 'Bom'
        ELSE 'Regular'
    END AS classificacao
FROM faturamento_vendedor
ORDER BY faturamento DESC;

-- Resultado: 10 vendedores Excelente (>= R$ 6.000), 4 Bom
-- (R$ 4.000–5.999), 6 Regular (> R$ 0 e < R$ 4.000) e 30 Sem vendas.


-- ============================================================
-- Exercício 07 — Produtos acima da Média
-- ============================================================

WITH faturamento_produto AS (
    SELECT
        p.id_produto,
        p.nome_produto,
        COALESCE(SUM(iv.quantidade * iv.valor_unitario * (1 - iv.desconto / 100)), 0) AS faturamento
    FROM produtos AS p
    LEFT JOIN itens_venda AS iv
        ON p.id_produto = iv.id_produto
    GROUP BY
        p.id_produto,
        p.nome_produto
),
media_geral AS (
    SELECT AVG(faturamento) AS media
    FROM faturamento_produto
)
SELECT
    fp.nome_produto,
    fp.faturamento,
    mg.media
FROM faturamento_produto AS fp
CROSS JOIN media_geral AS mg
WHERE fp.faturamento > mg.media
ORDER BY fp.faturamento DESC;

-- Resultado: a média de faturamento por produto (considerando os
-- 50 cadastrados, inclusive os nunca vendidos) é de R$ 2.225,31.
-- Apenas 13 produtos ficam acima dessa média — os mais vendidos
-- puxam a média para cima, deixando a maioria abaixo dela.


-- ============================================================
-- Exercício 08 — Categorias Estratégicas
-- ============================================================

WITH produtos_categoria AS (
    SELECT
        p.id_produto,
        p.categoria,
        COALESCE(SUM(iv.quantidade), 0) AS quantidade_vendida,
        COALESCE(SUM(iv.quantidade * iv.valor_unitario * (1 - iv.desconto / 100)), 0) AS faturamento
    FROM produtos AS p
    LEFT JOIN itens_venda AS iv
        ON p.id_produto = iv.id_produto
    GROUP BY
        p.id_produto,
        p.categoria
)
SELECT
    categoria,
    COUNT(*) AS quantidade_produtos,
    SUM(CASE WHEN quantidade_vendida > 0 THEN 1 ELSE 0 END) AS produtos_vendidos,
    SUM(CASE WHEN quantidade_vendida = 0 THEN 1 ELSE 0 END) AS produtos_nunca_vendidos,
    SUM(faturamento) AS faturamento
FROM produtos_categoria
GROUP BY categoria
ORDER BY faturamento DESC;

-- Resultado: 12 categorias no total. Três delas — Segurança, Casa
-- Inteligente e Acessórios — aparecem com faturamento = 0, pois
-- nenhum produto dessas categorias foi vendido ainda.


-- ============================================================
-- Exercício 09 — Dashboard de Clientes
-- ============================================================

WITH resumo_cliente AS (
    SELECT
        c.id_cliente,
        c.nome_cliente,
        COUNT(v.id_venda) AS quantidade_compras,
        COALESCE(SUM(v.valor_total), 0) AS valor_total
    FROM clientes AS c
    LEFT JOIN vendas AS v
        ON c.id_cliente = v.id_cliente
    GROUP BY
        c.id_cliente,
        c.nome_cliente
)
SELECT
    nome_cliente,
    quantidade_compras,
    valor_total,
    CASE
        WHEN quantidade_compras = 0 THEN 0
        ELSE valor_total / quantidade_compras
    END AS ticket_medio,
    CASE
        WHEN quantidade_compras = 0 THEN 'Sem compras'
        WHEN valor_total >= 20000 THEN 'Cliente VIP'
        WHEN valor_total >= 10000 THEN 'Cliente Regular'
        ELSE 'Cliente Ocasional'
    END AS classificacao
FROM resumo_cliente
ORDER BY valor_total DESC;

-- Resultado: 4 clientes VIP (>= R$ 20.000), 1 Regular
-- (R$ 10.000–19.999) e 45 Sem compras. Nenhum caiu em "Ocasional"
-- neste recorte, porque os 5 clientes ativos compram com bastante
-- frequência (10 vendas cada).


-- ============================================================
-- Exercício 10 — Dashboard de Produtos
-- ============================================================

WITH faturamento_produto AS (
    SELECT
        p.id_produto,
        p.nome_produto,
        COALESCE(SUM(iv.quantidade), 0) AS quantidade_vendida,
        COALESCE(SUM(iv.quantidade * iv.valor_unitario * (1 - iv.desconto / 100)), 0) AS valor_vendido
    FROM produtos AS p
    LEFT JOIN itens_venda AS iv
        ON p.id_produto = iv.id_produto
    GROUP BY
        p.id_produto,
        p.nome_produto
),
total_geral AS (
    SELECT SUM(valor_vendido) AS total
    FROM faturamento_produto
)
SELECT
    fp.nome_produto,
    fp.quantidade_vendida,
    fp.valor_vendido,
    ROUND(fp.valor_vendido * 100.0 / tg.total, 2) AS percentual_participacao
FROM faturamento_produto AS fp
CROSS JOIN total_geral AS tg
ORDER BY fp.valor_vendido DESC;

-- Resultado: o Notebook Pro 14 sozinho representa 15,71% de todo o
-- faturamento de produtos; os 10 produtos nunca vendidos aparecem
-- com 0,00% de participação.


-- ============================================================
-- Exercício 11 — Auditoria Completa
-- ============================================================

SELECT
    p.nome_produto,
    p.categoria,
    CASE
        WHEN iv.id_item IS NULL THEN 'Nunca vendido'
        ELSE 'Vendido'
    END AS situacao
FROM produtos AS p
LEFT JOIN itens_venda AS iv
    ON p.id_produto = iv.id_produto
GROUP BY
    p.id_produto,
    p.nome_produto,
    p.categoria,
    situacao
ORDER BY situacao, p.nome_produto;

-- JOIN utilizado: LEFT JOIN, partindo de produtos (tabela "âncora")
-- em direção a itens_venda. Um INNER JOIN aqui eliminaria da consulta
-- justamente os produtos que nunca foram vendidos — que é a
-- informação que este relatório de auditoria precisa mostrar. O
-- LEFT JOIN preserva todos os produtos e usa IS NULL para identificar
-- quem não tem correspondência.


-- ============================================================
-- Exercício 12 — Integração de Sistemas
-- ------------------------------------------------------------
-- MySQL não possui FULL OUTER JOIN nativo. Simulamos com
-- LEFT JOIN + RIGHT JOIN + UNION, como sugerido no enunciado:
-- a primeira metade traz tudo de clientes_techvendas (com o que
-- houver de correspondência) e a segunda traz tudo de
-- clientes_empresa_adquirida; o UNION remove a linha duplicada de
-- quem está nas duas bases.
-- ============================================================

SELECT
    ct.nome_cliente AS cliente_techvendas,
    ca.nome_cliente AS cliente_empresa_adquirida,
    CASE
        WHEN ct.nome_cliente IS NOT NULL AND ca.nome_cliente IS NOT NULL THEN 'Presente em ambas'
        WHEN ct.nome_cliente IS NOT NULL THEN 'Somente TechVendas'
        ELSE 'Somente empresa adquirida'
    END AS situacao
FROM clientes_techvendas AS ct
LEFT JOIN clientes_empresa_adquirida AS ca
    ON ct.nome_cliente = ca.nome_cliente

UNION

SELECT
    ct.nome_cliente AS cliente_techvendas,
    ca.nome_cliente AS cliente_empresa_adquirida,
    CASE
        WHEN ct.nome_cliente IS NOT NULL AND ca.nome_cliente IS NOT NULL THEN 'Presente em ambas'
        WHEN ct.nome_cliente IS NOT NULL THEN 'Somente TechVendas'
        ELSE 'Somente empresa adquirida'
    END AS situacao
FROM clientes_techvendas AS ct
RIGHT JOIN clientes_empresa_adquirida AS ca
    ON ct.nome_cliente = ca.nome_cliente

ORDER BY situacao;

-- Resultado: 65 linhas no total — 35 clientes só na TechVendas, 15
-- só na empresa adquirida e 15 presentes nas duas bases (os mesmos
-- 15 nomes cadastrados propositalmente em ambas as tabelas).


-- ============================================================
-- Exercício 13 — Auditoria de Cadastros
-- ============================================================

WITH integracao AS (
    SELECT
        ct.nome_cliente AS cliente_techvendas,
        ca.nome_cliente AS cliente_empresa_adquirida
    FROM clientes_techvendas AS ct
    LEFT JOIN clientes_empresa_adquirida AS ca
        ON ct.nome_cliente = ca.nome_cliente

    UNION

    SELECT
        ct.nome_cliente AS cliente_techvendas,
        ca.nome_cliente AS cliente_empresa_adquirida
    FROM clientes_techvendas AS ct
    RIGHT JOIN clientes_empresa_adquirida AS ca
        ON ct.nome_cliente = ca.nome_cliente
)
SELECT
    SUM(CASE WHEN cliente_techvendas IS NOT NULL AND cliente_empresa_adquirida IS NULL THEN 1 ELSE 0 END) AS somente_base_antiga,
    SUM(CASE WHEN cliente_techvendas IS NULL AND cliente_empresa_adquirida IS NOT NULL THEN 1 ELSE 0 END) AS somente_base_nova,
    SUM(CASE WHEN cliente_techvendas IS NOT NULL AND cliente_empresa_adquirida IS NOT NULL THEN 1 ELSE 0 END) AS presentes_nas_duas
FROM integracao;

-- Resultado: 35 clientes somente na base antiga, 15 somente na base
-- nova e 15 presentes nas duas — a mesma distribuição do Exercício
-- 12, agora resumida em números com funções de agregação (SUM +
-- CASE fazendo o papel de COUNT condicional).


-- ============================================================
-- Exercício 14 — Dashboard Executivo
-- ------------------------------------------------------------
-- Usa 4 CTEs encadeadas: uma para o resumo de cada vendedor e três
-- de ranking (melhor cliente, melhor categoria, melhor produto),
-- cada uma usando ROW_NUMBER() OVER (PARTITION BY vendedor) para
-- descobrir o item de maior valor de cada vendedor.
-- ============================================================

WITH resumo_vendedor AS (
    SELECT
        vd.id_vendedor,
        vd.nome_vendedor,
        COUNT(DISTINCT v.id_cliente) AS quantidade_clientes,
        COUNT(v.id_venda) AS quantidade_vendas,
        COALESCE(AVG(v.valor_total), 0) AS ticket_medio
    FROM vendedores AS vd
    LEFT JOIN vendas AS v
        ON vd.id_vendedor = v.id_vendedor
    GROUP BY
        vd.id_vendedor,
        vd.nome_vendedor
),
ranking_cliente AS (
    SELECT
        v.id_vendedor,
        c.nome_cliente,
        SUM(v.valor_total) AS valor_cliente,
        ROW_NUMBER() OVER (
            PARTITION BY v.id_vendedor
            ORDER BY SUM(v.valor_total) DESC
        ) AS posicao
    FROM vendas AS v
    INNER JOIN clientes AS c
        ON v.id_cliente = c.id_cliente
    GROUP BY
        v.id_vendedor,
        c.nome_cliente
),
ranking_categoria AS (
    SELECT
        v.id_vendedor,
        p.categoria,
        SUM(iv.quantidade * iv.valor_unitario * (1 - iv.desconto / 100)) AS valor_categoria,
        ROW_NUMBER() OVER (
            PARTITION BY v.id_vendedor
            ORDER BY SUM(iv.quantidade * iv.valor_unitario * (1 - iv.desconto / 100)) DESC
        ) AS posicao
    FROM vendas AS v
    INNER JOIN itens_venda AS iv
        ON v.id_venda = iv.id_venda
    INNER JOIN produtos AS p
        ON iv.id_produto = p.id_produto
    GROUP BY
        v.id_vendedor,
        p.categoria
),
ranking_produto AS (
    SELECT
        v.id_vendedor,
        p.nome_produto,
        SUM(iv.quantidade * iv.valor_unitario * (1 - iv.desconto / 100)) AS valor_produto,
        ROW_NUMBER() OVER (
            PARTITION BY v.id_vendedor
            ORDER BY SUM(iv.quantidade * iv.valor_unitario * (1 - iv.desconto / 100)) DESC
        ) AS posicao
    FROM vendas AS v
    INNER JOIN itens_venda AS iv
        ON v.id_venda = iv.id_venda
    INNER JOIN produtos AS p
        ON iv.id_produto = p.id_produto
    GROUP BY
        v.id_vendedor,
        p.nome_produto
)
SELECT
    rv.nome_vendedor,
    rv.quantidade_clientes,
    rv.quantidade_vendas,
    rv.ticket_medio,
    rc.nome_cliente AS melhor_cliente,
    rcat.categoria AS melhor_categoria,
    rp.nome_produto AS melhor_produto
FROM resumo_vendedor AS rv
LEFT JOIN ranking_cliente AS rc
    ON rv.id_vendedor = rc.id_vendedor AND rc.posicao = 1
LEFT JOIN ranking_categoria AS rcat
    ON rv.id_vendedor = rcat.id_vendedor AND rcat.posicao = 1
LEFT JOIN ranking_produto AS rp
    ON rv.id_vendedor = rp.id_vendedor AND rp.posicao = 1
ORDER BY rv.ticket_medio DESC;

-- JOINs utilizados: LEFT JOIN de vendedores para vendas (para manter
-- os 30 vendedores sem vendas no relatório) e INNER JOIN dentro de
-- cada CTE de ranking (ali só interessam vendas que de fato
-- aconteceram, então não há motivo para preservar linhas nulas).
-- Resultado: cada um dos 20 vendedores ativos aparece com um único
-- melhor cliente, categoria e produto; os 30 sem vendas aparecem com
-- esses três campos em NULL.


-- ============================================================
-- Exercício 15 — Painel de Auditoria Geral
-- ------------------------------------------------------------
-- 5 CTEs, agregações, COALESCE, CASE, HAVING e os três tipos de
-- junção pedidos (LEFT, RIGHT e a simulação de FULL OUTER via
-- LEFT + RIGHT + UNION).
-- ============================================================

WITH compras_por_cliente AS (
    SELECT
        c.id_cliente,
        COUNT(v.id_venda) AS quantidade_compras
    FROM clientes AS c
    LEFT JOIN vendas AS v
        ON c.id_cliente = v.id_cliente
    GROUP BY c.id_cliente
),
vendas_por_produto AS (
    SELECT
        p.id_produto,
        COALESCE(SUM(iv.quantidade), 0) AS quantidade_vendida
    FROM produtos AS p
    LEFT JOIN itens_venda AS iv
        ON p.id_produto = iv.id_produto
    GROUP BY p.id_produto
),
vendedores_ativos AS (
    SELECT
        vd.id_vendedor
    FROM vendedores AS vd
    INNER JOIN vendas AS v
        ON vd.id_vendedor = v.id_vendedor
    GROUP BY vd.id_vendedor
    HAVING COUNT(v.id_venda) > 0
),
integracao_cadastros AS (
    SELECT
        ct.nome_cliente AS cliente_techvendas,
        ca.nome_cliente AS cliente_empresa_adquirida
    FROM clientes_techvendas AS ct
    LEFT JOIN clientes_empresa_adquirida AS ca
        ON ct.nome_cliente = ca.nome_cliente

    UNION

    SELECT
        ct.nome_cliente AS cliente_techvendas,
        ca.nome_cliente AS cliente_empresa_adquirida
    FROM clientes_techvendas AS ct
    RIGHT JOIN clientes_empresa_adquirida AS ca
        ON ct.nome_cliente = ca.nome_cliente
),
totais_cadastro AS (
    SELECT
        (SELECT COUNT(*) FROM clientes) AS clientes_cadastrados,
        (SELECT COUNT(*) FROM produtos) AS produtos_cadastrados,
        (SELECT COUNT(*) FROM vendedores) AS vendedores_cadastrados
)
SELECT
    tc.clientes_cadastrados,
    (SELECT COUNT(*) FROM compras_por_cliente WHERE quantidade_compras > 0) AS clientes_ativos,
    (SELECT COUNT(*) FROM compras_por_cliente WHERE quantidade_compras = 0) AS clientes_sem_compras,
    tc.produtos_cadastrados,
    (SELECT COUNT(*) FROM vendas_por_produto WHERE quantidade_vendida > 0) AS produtos_vendidos,
    (SELECT COUNT(*) FROM vendas_por_produto WHERE quantidade_vendida = 0) AS produtos_sem_vendas,
    tc.vendedores_cadastrados,
    (SELECT COUNT(*) FROM vendedores_ativos) AS vendedores_ativos,
    tc.vendedores_cadastrados - (SELECT COUNT(*) FROM vendedores_ativos) AS vendedores_sem_vendas,
    (SELECT COUNT(*) FROM integracao_cadastros WHERE cliente_techvendas IS NOT NULL AND cliente_empresa_adquirida IS NULL) AS clientes_somente_techvendas,
    (SELECT COUNT(*) FROM integracao_cadastros WHERE cliente_techvendas IS NULL AND cliente_empresa_adquirida IS NOT NULL) AS clientes_somente_adquirida,
    (SELECT COUNT(*) FROM integracao_cadastros WHERE cliente_techvendas IS NOT NULL AND cliente_empresa_adquirida IS NOT NULL) AS clientes_em_ambas_as_bases,
    CASE
        WHEN (SELECT COUNT(*) FROM compras_por_cliente WHERE quantidade_compras > 0) * 100.0 / tc.clientes_cadastrados >= 50 THEN 'Saudavel'
        WHEN (SELECT COUNT(*) FROM compras_por_cliente WHERE quantidade_compras > 0) * 100.0 / tc.clientes_cadastrados >= 20 THEN 'Atencao'
        ELSE 'Critico'
    END AS saude_da_carteira_de_clientes
FROM totais_cadastro AS tc;

-- Resultado: clientes 50/5/45, produtos 50/40/10, vendedores
-- 50/20/30, integração 35/15/15 e saúde da carteira "Critico" (só
-- 10% dos clientes cadastrados já compraram) — um retrato completo
-- da base em uma única linha, pronto para virar o topo de um
-- dashboard executivo.
