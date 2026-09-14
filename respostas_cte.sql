-- ============================================================
-- Exercício Prático — Common Table Expressions (CTE) e Subqueries
-- Tabela: vendas
-- Consultas testadas contra a base já tratada (após as questões de
-- UPDATE/DELETE do exercício anterior — 80 registros).
-- ============================================================


-- Questão 1 — Vendas concluídas
WITH vendas_concluidas AS (
    SELECT *
    FROM vendas
    WHERE status_venda = 'Concluída'
)
SELECT
    id_venda,
    data_venda,
    nome_cliente,
    nome_produto,
    valor_total,
    vendedor
FROM vendas_concluidas
ORDER BY valor_total DESC;


-- Questão 2 — Faturamento por categoria
WITH resumo_categorias AS (
    SELECT
        categoria,
        COUNT(*) AS quantidade_vendas,
        SUM(quantidade) AS total_produtos_vendidos,
        SUM(valor_total) AS faturamento_total,
        AVG(valor_total) AS valor_medio_vendas
    FROM vendas
    GROUP BY categoria
)
SELECT *
FROM resumo_categorias
WHERE faturamento_total > 10000.00
ORDER BY faturamento_total DESC;


-- Questão 3 — Desempenho dos vendedores
WITH desempenho_vendedores AS (
    SELECT
        vendedor,
        COUNT(*) AS quantidade_vendas,
        SUM(quantidade) AS total_produtos_vendidos,
        SUM(valor_total) AS valor_total_vendido,
        AVG(valor_total) AS ticket_medio
    FROM vendas
    GROUP BY vendedor
)
SELECT *
FROM desempenho_vendedores
ORDER BY valor_total_vendido DESC
LIMIT 3;


-- Questão 4 — Estados com faturamento acima da média
WITH vendas_validas AS (
    SELECT *
    FROM vendas
    WHERE quantidade > 0
      AND status_venda <> 'Cancelada'
),
faturamento_estados AS (
    SELECT
        estado_cliente,
        COUNT(*) AS quantidade_vendas,
        SUM(quantidade) AS total_produtos_vendidos,
        SUM(valor_total) AS faturamento_total
    FROM vendas_validas
    GROUP BY estado_cliente
),
media_faturamento AS (
    SELECT AVG(faturamento_total) AS media_geral
    FROM faturamento_estados
)
SELECT
    fe.estado_cliente,
    fe.quantidade_vendas,
    fe.total_produtos_vendidos,
    fe.faturamento_total,
    mf.media_geral,
    fe.faturamento_total - mf.media_geral AS diferenca_para_media
FROM faturamento_estados fe
CROSS JOIN media_faturamento mf
WHERE fe.faturamento_total > mf.media_geral
ORDER BY fe.faturamento_total DESC;


-- ============================================================
-- Desafio adicional — Questão 2 reescrita com subquery
-- ============================================================
SELECT *
FROM (
    SELECT
        categoria,
        COUNT(*) AS quantidade_vendas,
        SUM(quantidade) AS total_produtos_vendidos,
        SUM(valor_total) AS faturamento_total,
        AVG(valor_total) AS valor_medio_vendas
    FROM vendas
    GROUP BY categoria
) AS resumo_categorias
WHERE faturamento_total > 10000.00
ORDER BY faturamento_total DESC;

-- Comparação CTE x subquery
-- Legibilidade: a CTE nomeia o passo intermediário (resumo_categorias) antes
--   de ser usado, então quem lê o SQL de cima para baixo já sabe o que
--   "resumo_categorias" representa antes de chegar no WHERE/ORDER BY.
--   Na subquery o mesmo bloco fica "no meio" do FROM, então é preciso ler
--   a consulta de dentro para fora para entender o fluxo.
-- Organização: a CTE separa claramente "calcular" (WITH) de "filtrar/ordenar"
--   (SELECT principal). A subquery mistura os dois níveis na mesma instrução,
--   com parênteses delimitando onde termina um bloco e começa o outro.
-- Níveis de aninhamento: a CTE é sempre "achatada" (um WITH ao lado do outro,
--   mesmo quando há várias, como na Questão 4). A subquery cresce em
--   profundidade — se fosse necessário mais um passo de agregação, viraria
--   uma subquery dentro de outra subquery, aumentando o aninhamento.
-- Facilidade de manutenção: com CTE é possível reutilizar o mesmo nome
--   (resumo_categorias) em várias partes da consulta principal, e cada CTE
--   pode ser testada isoladamente rodando só o SELECT dela. Na subquery,
--   qualquer teste isolado exige copiar o bloco para fora do FROM, e reusar
--   o mesmo resultado duas vezes obrigaria repetir a subquery inteira.
-- Conclusão: para consultas com um único filtro simples, como a Questão 2,
--   as duas formas produzem o mesmo resultado e desempenho. A CTE compensa
--   mais à medida que a consulta cresce (como na Questão 4, com três passos
--   encadeados), pois evita aninhar parênteses e deixa cada etapa nomeada.
