-- ============================================================
-- GUIA DE ESTUDOS DE SQL
-- ------------------------------------------------------------
-- Roteiro com os conceitos estudados durante o curso, do básico
-- ao avançado, organizado em ordem crescente de dificuldade.
--
-- A base usada aqui é uma versão reduzida do cenário TechVendas
-- S/A utilizado nos exercícios do curso (arquivos "innerjoin 1.sql",
-- "aula 03.sql", "dashboard_executivo_techvendas.sql",
-- "noitada_desafios_vol2.sql" e "desafio_final_sportzone.sql"). Os
-- dados foram simplificados para caber em poucas linhas e ainda
-- assim demonstrar todos os casos importantes: clientes sem
-- compra, vendedor sem venda, produto nunca vendido e uma venda
-- cancelada.
--
-- Compatibilidade: escrito para MySQL 8+. Onde a sintaxe muda em
-- PostgreSQL ou SQLite, há uma observação no comentário da seção.
-- ============================================================


-- ============================================================
-- 1. DDL — CRIAÇÃO DE TABELAS
-- ------------------------------------------------------------
-- Tipos de dados, chave primária (PRIMARY KEY), chave estrangeira
-- (FOREIGN KEY) e a ordem de criação/remoção respeitando as
-- dependências entre tabelas.
-- ============================================================

DROP TABLE IF EXISTS itens_venda;
DROP TABLE IF EXISTS vendas;
DROP TABLE IF EXISTS produtos;
DROP TABLE IF EXISTS vendedores;
DROP TABLE IF EXISTS clientes;

CREATE TABLE clientes (
    id_cliente      INTEGER       PRIMARY KEY,
    nome_cliente    VARCHAR(100)  NOT NULL,
    cidade          VARCHAR(80)   NOT NULL,
    estado          CHAR(2)       NOT NULL
);

CREATE TABLE vendedores (
    id_vendedor     INTEGER       PRIMARY KEY,
    nome_vendedor   VARCHAR(100)  NOT NULL,
    setor           VARCHAR(50)   NOT NULL
);

CREATE TABLE produtos (
    id_produto      INTEGER        PRIMARY KEY,
    nome_produto    VARCHAR(120)   NOT NULL,
    categoria       VARCHAR(60)    NOT NULL,
    preco           DECIMAL(10,2)  NOT NULL
);

CREATE TABLE vendas (
    id_venda          INTEGER        PRIMARY KEY,
    data_venda        DATE           NOT NULL,
    id_cliente        INTEGER        NOT NULL,
    id_vendedor       INTEGER        NOT NULL,
    forma_pagamento   VARCHAR(40)    NOT NULL,
    status            VARCHAR(20)    NOT NULL,
    valor_total       DECIMAL(10,2)  NOT NULL,
    CONSTRAINT fk_vendas_clientes
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    CONSTRAINT fk_vendas_vendedores
        FOREIGN KEY (id_vendedor) REFERENCES vendedores(id_vendedor)
);

CREATE TABLE itens_venda (
    id_item          INTEGER        PRIMARY KEY,
    id_venda         INTEGER        NOT NULL,
    id_produto       INTEGER        NOT NULL,
    quantidade       INTEGER        NOT NULL,
    valor_unitario   DECIMAL(10,2)  NOT NULL,
    desconto         DECIMAL(5,2)   NOT NULL DEFAULT 0,
    CONSTRAINT fk_itens_venda
        FOREIGN KEY (id_venda) REFERENCES vendas(id_venda),
    CONSTRAINT fk_itens_produtos
        FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);


-- ============================================================
-- 2. ÍNDICES
-- ------------------------------------------------------------
-- Índices nas colunas usadas como chave estrangeira, para
-- acelerar os JOINs feitos mais adiante.
-- ============================================================

CREATE INDEX idx_vendas_cliente   ON vendas (id_cliente);
CREATE INDEX idx_vendas_vendedor  ON vendas (id_vendedor);
CREATE INDEX idx_itens_venda_venda    ON itens_venda (id_venda);
CREATE INDEX idx_itens_venda_produto  ON itens_venda (id_produto);


-- ============================================================
-- 3. DML — INSERÇÃO DE DADOS
-- ------------------------------------------------------------
-- Base pequena, de propósito: 2 clientes nunca compraram,
-- 1 vendedor nunca vendeu, 2 produtos nunca foram vendidos e
-- 1 venda está cancelada. Cada venda tem exatamente um item,
-- para simplificar as agregações.
-- ============================================================

INSERT INTO clientes (id_cliente, nome_cliente, cidade, estado) VALUES
    (1, 'Ana Souza',       'Curitiba',       'PR'),
    (2, 'Bruno Lima',      'Curitiba',       'PR'),
    (3, 'Carla Mendes',    'São Paulo',      'SP'),
    (4, 'Diego Martins',   'São Paulo',      'SP'),
    (5, 'Eduarda Alves',   'Rio de Janeiro', 'RJ'),
    (6, 'Felipe Rocha',    'Rio de Janeiro', 'RJ'),   -- nunca comprou
    (7, 'Gabriela Costa',  'Belo Horizonte', 'MG'),   -- nunca comprou
    (8, 'Henrique Silva',  'Curitiba',       'PR');

INSERT INTO vendedores (id_vendedor, nome_vendedor, setor) VALUES
    (1, 'Amanda Freire', 'Loja Física'),
    (2, 'Breno Paiva',   'E-commerce'),
    (3, 'Camila Sales',  'Corporativo'),
    (4, 'Douglas Reis',  'Televendas'),
    (5, 'Elaine Braga',  'Marketplace');           -- nunca vendeu

INSERT INTO produtos (id_produto, nome_produto, categoria, preco) VALUES
    (1, 'Notebook Pro',        'Informática',       4000.00),
    (2, 'Mouse Sem Fio',       'Informática',        100.00),
    (3, 'Teclado Mecânico',    'Informática',        300.00),
    (4, 'Smartphone X1',       'Telefonia',         2000.00),
    (5, 'Fone Bluetooth',      'Telefonia',          200.00),
    (6, 'Smartwatch Fit',      'Wearables',          600.00),
    (7, 'Ar-condicionado',     'Climatização',      2400.00),   -- nunca vendido
    (8, 'Cafeteira Elétrica',  'Eletrodomésticos',   200.00);   -- nunca vendido

INSERT INTO vendas (id_venda, data_venda, id_cliente, id_vendedor, forma_pagamento, status, valor_total) VALUES
    (1,  '2026-01-05', 1, 1, 'Pix',               'Concluída', 4000.00),
    (2,  '2026-01-10', 2, 2, 'Cartão de Crédito', 'Concluída',  200.00),
    (3,  '2026-01-15', 3, 1, 'Boleto',            'Concluída', 2000.00),
    (4,  '2026-01-20', 4, 3, 'Pix',               'Concluída',  600.00),
    (5,  '2026-01-25', 5, 4, 'Dinheiro',          'Cancelada',  600.00),
    (6,  '2026-02-01', 8, 2, 'Pix',               'Concluída',  200.00),
    (7,  '2026-02-05', 1, 1, 'Cartão de Crédito', 'Concluída',  300.00),
    (8,  '2026-02-10', 3, 3, 'Boleto',            'Pendente',  4000.00),
    (9,  '2026-02-15', 2, 4, 'Pix',               'Cancelada',  600.00),
    (10, '2026-02-20', 4, 1, 'Cartão de Débito',  'Concluída',  300.00);

INSERT INTO itens_venda (id_item, id_venda, id_produto, quantidade, valor_unitario, desconto) VALUES
    (1,  1,  1, 1, 4000.00,  0.00),
    (2,  2,  2, 2,  100.00,  0.00),
    (3,  3,  4, 1, 2000.00, 10.00),
    (4,  4,  6, 1,  600.00,  0.00),
    (5,  5,  3, 2,  300.00,  5.00),
    (6,  6,  5, 1,  200.00,  0.00),
    (7,  7,  3, 1,  300.00,  0.00),
    (8,  8,  1, 1, 4000.00, 20.00),
    (9,  9,  6, 1,  600.00,  0.00),
    (10, 10, 2, 3,  100.00,  0.00);


-- ============================================================
-- 4. CONSULTAS BÁSICAS
-- ------------------------------------------------------------
-- SELECT de colunas específicas (nunca SELECT *), aliases com
-- AS, filtro com WHERE, faixa de valores com BETWEEN e
-- ordenação com ORDER BY.
-- ============================================================

-- Todos os clientes do Paraná
SELECT
    c.nome_cliente,
    c.cidade
FROM clientes AS c
WHERE c.estado = 'PR';

-- Vendas concluídas em um período, da mais recente para a mais antiga
SELECT
    v.id_venda,
    v.data_venda,
    v.valor_total
FROM vendas AS v
WHERE v.status = 'Concluída'
    AND v.data_venda BETWEEN '2026-01-01' AND '2026-01-31'
ORDER BY v.data_venda DESC;


-- ============================================================
-- 5. FUNÇÕES DE AGREGAÇÃO, GROUP BY E HAVING
-- ------------------------------------------------------------
-- COUNT, SUM, AVG, MIN, MAX agrupando linhas com GROUP BY, e
-- filtrando grupos (não linhas) com HAVING.
-- ============================================================

-- Faturamento e ticket médio por forma de pagamento
SELECT
    v.forma_pagamento,
    COUNT(*) AS quantidade_vendas,
    SUM(v.valor_total) AS faturamento,
    AVG(v.valor_total) AS ticket_medio,
    MIN(v.valor_total) AS menor_venda,
    MAX(v.valor_total) AS maior_venda
FROM vendas AS v
GROUP BY v.forma_pagamento
ORDER BY faturamento DESC;

-- Só as formas de pagamento com faturamento acima de 1000
-- (HAVING filtra depois do agrupamento; WHERE não pode usar SUM aqui)
SELECT
    v.forma_pagamento,
    SUM(v.valor_total) AS faturamento
FROM vendas AS v
GROUP BY v.forma_pagamento
HAVING SUM(v.valor_total) > 1000
ORDER BY faturamento DESC;


-- ============================================================
-- 6. UPDATE E DELETE
-- ------------------------------------------------------------
-- Sempre com WHERE para não alterar/apagar a tabela inteira.
-- ============================================================

-- Padroniza o nome da forma de pagamento
UPDATE vendas
SET forma_pagamento = 'Cartão de Débito'
WHERE forma_pagamento = 'Cartao Debito';

-- Cancela vendas pendentes antigas
UPDATE vendas
SET status = 'Cancelada'
WHERE status = 'Pendente'
    AND data_venda < '2026-01-01';

-- Remove vendas canceladas de um período que não interessa mais
DELETE FROM vendas
WHERE status = 'Cancelada'
    AND data_venda < '2025-01-01';


-- ============================================================
-- 7. INNER JOIN
-- ------------------------------------------------------------
-- Só traz linhas que têm correspondência nas duas tabelas.
-- Sempre com alias e a condição de junção explícita no ON.
-- ============================================================

-- Duas tabelas
SELECT
    v.id_venda,
    v.data_venda,
    c.nome_cliente,
    v.valor_total
FROM vendas AS v
INNER JOIN clientes AS c
    ON v.id_cliente = c.id_cliente;

-- Três tabelas: detalhamento de cada item vendido
SELECT
    v.id_venda,
    v.data_venda,
    p.nome_produto,
    iv.quantidade,
    iv.valor_unitario
FROM vendas AS v
INNER JOIN itens_venda AS iv
    ON v.id_venda = iv.id_venda
INNER JOIN produtos AS p
    ON iv.id_produto = p.id_produto;

-- Cinco tabelas: relatório completo de vendas
SELECT
    v.id_venda,
    v.data_venda,
    c.nome_cliente,
    vd.nome_vendedor,
    p.nome_produto,
    iv.quantidade,
    iv.valor_unitario
FROM vendas AS v
INNER JOIN clientes AS c
    ON v.id_cliente = c.id_cliente
INNER JOIN vendedores AS vd
    ON v.id_vendedor = vd.id_vendedor
INNER JOIN itens_venda AS iv
    ON v.id_venda = iv.id_venda
INNER JOIN produtos AS p
    ON iv.id_produto = p.id_produto;

-- Agregação com INNER JOIN: desempenho de cada vendedor que já vendeu
SELECT
    vd.nome_vendedor,
    COUNT(v.id_venda) AS quantidade_vendas,
    SUM(v.valor_total) AS total_vendido,
    AVG(v.valor_total) AS ticket_medio
FROM vendas AS v
INNER JOIN vendedores AS vd
    ON v.id_vendedor = vd.id_vendedor
GROUP BY
    vd.id_vendedor,
    vd.nome_vendedor
ORDER BY total_vendido DESC;


-- ============================================================
-- 8. LEFT JOIN
-- ------------------------------------------------------------
-- Traz TODAS as linhas da tabela da esquerda, mesmo sem
-- correspondência na tabela da direita (que aparece com NULL).
-- Usado para achar "quem não tem": clientes sem compra,
-- vendedores sem venda, produtos nunca vendidos.
-- ============================================================

-- Todos os clientes, com a venda quando existir
SELECT
    c.id_cliente,
    c.nome_cliente,
    v.id_venda,
    v.data_venda
FROM clientes AS c
LEFT JOIN vendas AS v
    ON c.id_cliente = v.id_cliente;

-- Só os clientes que nunca compraram (o "buraco" do LEFT JOIN)
SELECT
    c.id_cliente,
    c.nome_cliente
FROM clientes AS c
LEFT JOIN vendas AS v
    ON c.id_cliente = v.id_cliente
WHERE v.id_venda IS NULL;

-- Total comprado por cliente, incluindo quem nunca comprou.
-- COALESCE troca o NULL do SUM (quando não há venda) por 0.
SELECT
    c.id_cliente,
    c.nome_cliente,
    COUNT(v.id_venda) AS quantidade_vendas,
    COALESCE(SUM(v.valor_total), 0) AS total_comprado
FROM clientes AS c
LEFT JOIN vendas AS v
    ON c.id_cliente = v.id_cliente
GROUP BY
    c.id_cliente,
    c.nome_cliente
ORDER BY total_comprado DESC;

-- Produtos que nunca apareceram em uma venda
SELECT
    p.id_produto,
    p.nome_produto,
    p.categoria
FROM produtos AS p
LEFT JOIN itens_venda AS iv
    ON p.id_produto = iv.id_produto
WHERE iv.id_item IS NULL;


-- ============================================================
-- 9. RIGHT JOIN E SIMULAÇÃO DE FULL OUTER JOIN
-- ------------------------------------------------------------
-- RIGHT JOIN é o espelho do LEFT JOIN: preserva tudo da tabela
-- da direita. MySQL não tem FULL OUTER JOIN nativo — a forma de
-- simular é somar um LEFT JOIN com um RIGHT JOIN via UNION
-- (o UNION também remove linhas duplicadas).
-- Em PostgreSQL basta usar FULL OUTER JOIN diretamente.
-- ============================================================

-- Vendedores e vendas, agora partindo da tabela vendas (RIGHT JOIN)
SELECT
    vd.nome_vendedor,
    v.id_venda
FROM vendas AS v
RIGHT JOIN vendedores AS vd
    ON v.id_vendedor = vd.id_vendedor;

-- Simulação de FULL OUTER JOIN entre clientes e vendedores
-- (exemplo didático, sem sentido de negócio — só para mostrar a técnica)
SELECT
    c.nome_cliente,
    vd.nome_vendedor
FROM clientes AS c
LEFT JOIN vendedores AS vd
    ON c.id_cliente = vd.id_vendedor

UNION

SELECT
    c.nome_cliente,
    vd.nome_vendedor
FROM clientes AS c
RIGHT JOIN vendedores AS vd
    ON c.id_cliente = vd.id_vendedor;


-- ============================================================
-- 10. IN, LIKE, EXISTS E NOT EXISTS
-- ------------------------------------------------------------
-- IN filtra por uma lista de valores. LIKE busca por padrão de
-- texto (% substitui qualquer sequência de caracteres). EXISTS
-- testa se uma subquery correlacionada retorna alguma linha —
-- não interessa o valor, só se existe ou não — e roda mais rápido
-- que um INNER JOIN quando a tabela relacionada tem repetição,
-- porque para no primeiro registro encontrado. NOT EXISTS faz o
-- oposto: verdadeiro quando a subquery não retorna nada.
-- ============================================================

-- IN: vendas feitas por um grupo específico de vendedores
SELECT
    v.id_venda,
    v.data_venda,
    v.valor_total
FROM vendas AS v
WHERE v.id_vendedor IN (1, 2, 3);

-- BETWEEN: mesma ideia de faixa de valores, mas com números
SELECT
    p.nome_produto,
    p.preco
FROM produtos AS p
WHERE p.preco BETWEEN 100 AND 1000;

-- LIKE: clientes cujo nome começa com "A"
SELECT
    c.nome_cliente,
    c.cidade
FROM clientes AS c
WHERE c.nome_cliente LIKE 'A%';

-- LIKE com % nas duas pontas: nome contém "Silva" em qualquer posição
SELECT
    c.nome_cliente
FROM clientes AS c
WHERE c.nome_cliente LIKE '%Silva%';

-- EXISTS: só os clientes que já têm pelo menos uma venda
-- (mesmo resultado de um INNER JOIN com clientes, mas sem juntar
-- as tabelas — só testa se a venda existe)
SELECT
    c.id_cliente,
    c.nome_cliente
FROM clientes AS c
WHERE EXISTS (
    SELECT 1
    FROM vendas AS v
    WHERE v.id_cliente = c.id_cliente
);

-- NOT EXISTS: o oposto — clientes que nunca compraram
-- (alternativa ao LEFT JOIN + IS NULL da seção 8)
SELECT
    c.id_cliente,
    c.nome_cliente
FROM clientes AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM vendas AS v
    WHERE v.id_cliente = c.id_cliente
);


-- ============================================================
-- 11. SUBQUERIES
-- ------------------------------------------------------------
-- Uma consulta dentro de outra: escalar (retorna um valor único),
-- no FROM (tratada como uma tabela) ou correlacionada (referencia
-- a consulta externa e roda uma vez por linha).
-- ============================================================

-- Subquery escalar no WHERE: vendas acima do ticket médio geral
SELECT
    v.id_venda,
    v.valor_total
FROM vendas AS v
WHERE v.valor_total > (
    SELECT AVG(valor_total) FROM vendas
);

-- Subquery no FROM: resumo por categoria, filtrando o resultado já agregado
SELECT *
FROM (
    SELECT
        p.categoria,
        SUM(iv.quantidade * iv.valor_unitario) AS faturamento_bruto
    FROM itens_venda AS iv
    INNER JOIN produtos AS p
        ON iv.id_produto = p.id_produto
    GROUP BY p.categoria
) AS resumo_categoria
WHERE faturamento_bruto > 500
ORDER BY faturamento_bruto DESC;

-- Subquery correlacionada no SELECT: quantidade de vendas de cada cliente
SELECT
    c.nome_cliente,
    (
        SELECT COUNT(*)
        FROM vendas AS v
        WHERE v.id_cliente = c.id_cliente
    ) AS quantidade_vendas
FROM clientes AS c;


-- ============================================================
-- 12. CTE (COMMON TABLE EXPRESSION / WITH)
-- ------------------------------------------------------------
-- Nomeia um passo intermediário antes da consulta principal.
-- Mesmo resultado de uma subquery no FROM, mas mais fácil de
-- ler (de cima para baixo) e de encadear em vários passos.
-- ============================================================

-- CTE única, equivalente à subquery da seção anterior
WITH resumo_categoria AS (
    SELECT
        p.categoria,
        SUM(iv.quantidade * iv.valor_unitario) AS faturamento_bruto
    FROM itens_venda AS iv
    INNER JOIN produtos AS p
        ON iv.id_produto = p.id_produto
    GROUP BY p.categoria
)
SELECT *
FROM resumo_categoria
WHERE faturamento_bruto > 500
ORDER BY faturamento_bruto DESC;

-- CTEs encadeadas: faturamento por vendedor comparado com a média da equipe
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
    SELECT AVG(faturamento_total) AS media_faturamento
    FROM faturamento_vendedor
)
SELECT
    fv.nome_vendedor,
    fv.faturamento_total,
    me.media_faturamento
FROM faturamento_vendedor AS fv
CROSS JOIN media_equipe AS me
WHERE fv.faturamento_total > me.media_faturamento
ORDER BY fv.faturamento_total DESC;


-- ============================================================
-- 13. CASE WHEN
-- ------------------------------------------------------------
-- Classificação condicional dentro do próprio SELECT.
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
        WHEN quantidade_compras = 0 THEN 'Sem compras'
        WHEN valor_total >= 3000 THEN 'Cliente VIP'
        WHEN valor_total >= 1000 THEN 'Cliente Regular'
        ELSE 'Cliente Ocasional'
    END AS classificacao
FROM resumo_cliente
ORDER BY valor_total DESC;


-- ============================================================
-- 14. WINDOW FUNCTIONS
-- ------------------------------------------------------------
-- ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...) numera as
-- linhas dentro de cada grupo, sem colapsar o resultado como o
-- GROUP BY faz. Aqui: o produto de maior faturamento de cada
-- vendedor.
-- ============================================================

WITH faturamento_por_produto_e_vendedor AS (
    SELECT
        v.id_vendedor,
        p.nome_produto,
        SUM(iv.quantidade * iv.valor_unitario) AS faturamento,
        ROW_NUMBER() OVER (
            PARTITION BY v.id_vendedor
            ORDER BY SUM(iv.quantidade * iv.valor_unitario) DESC
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
    id_vendedor,
    nome_produto AS produto_mais_vendido,
    faturamento
FROM faturamento_por_produto_e_vendedor
WHERE posicao = 1;


-- ============================================================
-- 15. FUNÇÕES DE DATA
-- ------------------------------------------------------------
-- DATEDIFF e CURDATE são do MySQL. Em PostgreSQL o equivalente é
-- (CURRENT_DATE - data_venda); em SQLite é
-- julianday('now') - julianday(data_venda).
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


-- ============================================================
-- 16. CONSULTA FINAL — JUNTANDO TUDO
-- ------------------------------------------------------------
-- Um dashboard por cliente combinando LEFT JOIN, COUNT, SUM,
-- MIN, MAX, COALESCE, CASE, GROUP BY e ORDER BY na mesma
-- consulta — o mesmo formato usado no desafio de fechamento do
-- curso (dashboard_executivo_techvendas.sql).
-- ============================================================

SELECT
    c.id_cliente,
    c.nome_cliente,
    c.cidade,
    COUNT(v.id_venda) AS quantidade_vendas,
    COALESCE(SUM(v.valor_total), 0) AS valor_total_comprado,
    MIN(v.data_venda) AS data_primeira_compra,
    MAX(v.data_venda) AS data_ultima_compra,
    CASE
        WHEN COUNT(v.id_venda) = 0 THEN 'Sem compras'
        WHEN COALESCE(SUM(v.valor_total), 0) >= 3000 THEN 'Cliente VIP'
        WHEN COALESCE(SUM(v.valor_total), 0) >= 1000 THEN 'Cliente Regular'
        ELSE 'Cliente Ocasional'
    END AS classificacao
FROM clientes AS c
LEFT JOIN vendas AS v
    ON c.id_cliente = v.id_cliente
GROUP BY
    c.id_cliente,
    c.nome_cliente,
    c.cidade
ORDER BY valor_total_comprado DESC;
