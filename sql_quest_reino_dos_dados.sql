USE sql_quest;

SET SQL_SAFE_UPDATES = 0;


-- ETAPA 1 - CLASSIFICACAO

UPDATE jogadores
SET classificacao = CASE
        WHEN pontos >= 12000 THEN 'LENDÁRIO'
        WHEN pontos >=  8000 THEN 'ELITE'
        WHEN pontos >=  5000 THEN 'VETERANO'
        ELSE 'APRENDIZ'
    END;

SELECT COUNT(*) AS sem_classificacao
FROM jogadores
WHERE classificacao IS NULL;


-- ETAPA 2 - BONUS

UPDATE jogadores
SET bonus = COALESCE(bonus, 0)
WHERE bonus IS NULL;

SELECT COUNT(*) AS bonus_nulos
FROM jogadores
WHERE bonus IS NULL;


-- ETAPA 3 - JOGADORES ACIMA DA MEDIA

SELECT id, nome, pontos, moedas
FROM jogadores
WHERE pontos > (SELECT AVG(pontos) FROM jogadores)
ORDER BY pontos DESC;

UPDATE jogadores
SET moedas = moedas + 250
WHERE pontos > (
    SELECT media
    FROM (SELECT AVG(pontos) AS media FROM jogadores) AS m
);


-- ETAPA 4 - GUERRA DAS GUILDAS

SELECT guilda, AVG(pontos) AS media_pontos
FROM jogadores
WHERE guilda IS NOT NULL
GROUP BY guilda
HAVING AVG(pontos) > 7000;

UPDATE jogadores
SET moedas = moedas + 300
WHERE guilda IN (
    SELECT guilda
    FROM (
        SELECT guilda
        FROM jogadores
        WHERE guilda IS NOT NULL
        GROUP BY guilda
        HAVING AVG(pontos) > 7000
    ) AS vencedoras
);


-- ETAPA 5 - CONSELHO DOS CAMPEOES

SELECT id, nome, pontos, nivel
FROM jogadores
ORDER BY pontos DESC
LIMIT 3;

UPDATE jogadores
SET nivel = nivel + 1
ORDER BY pontos DESC
LIMIT 3;


-- ETAPA 6 - TREINAMENTO EMERGENCIAL

SELECT id, nome, nivel, status_jogador
FROM jogadores
WHERE status_jogador = 'ATIVO'
  AND nivel < 18;

UPDATE jogadores
SET nivel = nivel + 2
WHERE status_jogador = 'ATIVO'
  AND nivel < 18;


-- ETAPA 7 - ESPIOES DE NULLMASTER

SELECT id, nome, pontos, status_jogador
FROM jogadores
WHERE status_jogador = 'INATIVO'
  AND pontos < 2000;

DELETE FROM jogadores
WHERE status_jogador = 'INATIVO'
  AND pontos < 2000;


-- AUDITORIA FINAL

SELECT id, nome, nivel, moedas, pontos, guilda, bonus, status_jogador, classificacao
FROM jogadores
ORDER BY pontos DESC;

SET SQL_SAFE_UPDATES = 1;
