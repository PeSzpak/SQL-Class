-- =====================================================================
-- DESAFIO DA NOITE (14/11) - SQL MURDER MYSTERY
-- Banco de Dados II - Pedro Szpak
-- Jogo: https://mystery.knightlab.com/  (banco SQLite)
-- Crime: assassinato em SQL City, 15/01/2018
--
-- Observação: no SQLite as datas são inteiros no formato AAAAMMDD
-- (15/01/2018 = 20180115), por isso os filtros de data usam números.
-- =====================================================================


-- =====================================================================
-- PARTE 1 E 2 - INVESTIGAÇÃO E EVIDÊNCIAS
-- =====================================================================

-- ---------------------------------------------------------------------
-- Consulta 1 - Recuperar o relatório do crime
-- Objetivo: o relatório original foi perdido; buscar o registro do
-- assassinato pela data, tipo e cidade informados.
-- ---------------------------------------------------------------------
SELECT *
FROM crime_scene_report
WHERE date = 20180115
  AND type = 'murder'
  AND city = 'SQL City';

-- Evidência: as câmeras mostram 2 testemunhas.
--   - A primeira mora na última casa da rua "Northwestern Dr".
--   - A segunda se chama Annabel e mora na "Franklin Ave".
-- Contribuição: o relatório não traz nomes, então o próximo passo é
-- identificar as testemunhas pela tabela person.


-- ---------------------------------------------------------------------
-- Consulta 2 - Primeira testemunha
-- Objetivo: "última casa" = maior número na rua Northwestern Dr.
-- ---------------------------------------------------------------------
SELECT id, name, address_number, address_street_name
FROM person
WHERE address_street_name = 'Northwestern Dr'
ORDER BY address_number DESC
LIMIT 1;

-- Evidência: Morty Schapiro (id 14887), número 4919.


-- ---------------------------------------------------------------------
-- Consulta 3 - Segunda testemunha
-- Objetivo: nome começando com Annabel, na Franklin Ave (LIKE).
-- ---------------------------------------------------------------------
SELECT id, name, address_number, address_street_name
FROM person
WHERE address_street_name = 'Franklin Ave'
  AND name LIKE 'Annabel%';

-- Evidência: Annabel Miller (id 16371).


-- ---------------------------------------------------------------------
-- Consulta 4 - Depoimentos das duas testemunhas
-- Objetivo: ler o que cada uma disse, ligando interview a person
-- (INNER JOIN) e encontrando os ids por subconsulta.
-- ---------------------------------------------------------------------
SELECT p.name, i.transcript
FROM interview i
INNER JOIN person p ON p.id = i.person_id
WHERE p.id IN (SELECT id FROM person
               WHERE address_street_name = 'Northwestern Dr'
               ORDER BY address_number DESC LIMIT 1)
   OR p.id IN (SELECT id FROM person
               WHERE address_street_name = 'Franklin Ave'
                 AND name LIKE 'Annabel%');

-- Evidências:
--   Morty: um homem saiu correndo com uma bolsa da academia "Get Fit Now";
--          o número de sócio na bolsa começa com "48Z", só sócios GOLD têm
--          essa bolsa, e o carro tinha uma placa contendo "H42W".
--   Annabel: reconheceu o assassino da academia, onde treinou em 09/01/2018.
-- Contribuição: agora há quatro filtros objetivos para cruzar:
-- sócio "48Z%", status gold, check-in em 20180109 e placa "%H42W%".


-- ---------------------------------------------------------------------
-- Consulta 5 - Sócios gold "48Z" que estiveram na academia em 09/01
-- Objetivo: cruzar o cadastro de sócios com os check-ins (pista da Annabel
-- + pista do Morty).
-- ---------------------------------------------------------------------
SELECT m.id, m.name, m.membership_status, c.check_in_date
FROM get_fit_now_member m
INNER JOIN get_fit_now_check_in c ON c.membership_id = m.id
WHERE m.id LIKE '48Z%'
  AND m.membership_status = 'gold'
  AND c.check_in_date = 20180109;

-- Evidência: dois suspeitos, Joe Germuska (48Z7A) e Jeremy Bowers (48Z55).
-- Contribuição: ainda falta a pista da placa para separar os dois.


-- ---------------------------------------------------------------------
-- Consulta 6 - Qual dos suspeitos tem a placa com "H42W"
-- Objetivo: ligar sócio -> pessoa -> carteira de motorista.
-- ---------------------------------------------------------------------
SELECT p.id, p.name, d.plate_number, d.car_make, d.car_model
FROM person p
INNER JOIN drivers_license d ON d.id = p.license_id
INNER JOIN get_fit_now_member m ON m.person_id = p.id
WHERE m.id LIKE '48Z%'
  AND m.membership_status = 'gold'
  AND d.plate_number LIKE '%H42W%';

-- Evidência: só Jeremy Bowers (person 67318) atende, placa 0H42W2,
-- Chevrolet Spark LS. Joe Germuska não aparece: a pessoa dele não tem
-- carteira com essa placa.


-- ---------------------------------------------------------------------
-- Consulta 7 - Conferência no próprio jogo
-- ---------------------------------------------------------------------
INSERT INTO solution VALUES (1, 'Jeremy Bowers');
SELECT value FROM solution;

-- Resultado: "Congrats, you found the murderer! But wait, there's more..."
-- O jogo confirma o assassino e sugere ler o depoimento dele.


-- =====================================================================
-- MISTÉRIO ADICIONAL - QUEM MANDOU MATAR
-- =====================================================================

-- ---------------------------------------------------------------------
-- Consulta 8 - Depoimento do assassino
-- ---------------------------------------------------------------------
SELECT p.name, i.transcript
FROM interview i
INNER JOIN person p ON p.id = i.person_id
WHERE p.name = 'Jeremy Bowers';

-- Evidência: foi contratado por uma mulher rica; ela tem entre 65 e 67
-- polegadas de altura, cabelo ruivo, dirige um Tesla Model S e foi ao
-- "SQL Symphony Concert" 3 vezes em dezembro de 2017.


-- ---------------------------------------------------------------------
-- Consulta 9 - A mandante, em uma única consulta
-- Objetivo: cruzar as características físicas e o carro (drivers_license)
-- com a presença no concerto (facebook_event_checkin), contando as idas
-- com GROUP BY + HAVING. A renda (income, via LEFT JOIN) confirma a parte
-- "com muito dinheiro".
-- ---------------------------------------------------------------------
SELECT p.id, p.name, d.height, d.hair_color, d.car_make, d.car_model,
       i.annual_income,
       COUNT(f.event_id) AS vezes_no_concerto
FROM drivers_license d
INNER JOIN person p ON p.license_id = d.id
INNER JOIN facebook_event_checkin f ON f.person_id = p.id
LEFT JOIN income i ON i.ssn = p.ssn
WHERE d.gender = 'female'
  AND d.hair_color = 'red'
  AND d.car_make = 'Tesla'
  AND d.car_model = 'Model S'
  AND d.height BETWEEN 65 AND 67
  AND f.event_name = 'SQL Symphony Concert'
  AND f.date BETWEEN 20171201 AND 20171231
GROUP BY p.id, p.name, d.height, d.hair_color, d.car_make, d.car_model, i.annual_income
HAVING COUNT(f.event_id) = 3;

-- Evidência: Miranda Priestly (person 99716), 66 polegadas, ruiva,
-- Tesla Model S, renda anual de 310.000, foi 3 vezes ao concerto.


-- ---------------------------------------------------------------------
-- Consulta 10 - Conferência no próprio jogo
-- ---------------------------------------------------------------------
INSERT INTO solution VALUES (1, 'Miranda Priestly');
SELECT value FROM solution;

-- Resultado: "Congrats, you found the brains behind the murder!"


-- =====================================================================
-- PARTE 3 - CONCLUSÃO
-- =====================================================================
--
-- Quem foi o responsável pelo assassinato?
--   O assassino foi JEREMY BOWERS. A mandante do crime foi MIRANDA PRIESTLY,
--   que o contratou. As duas respostas foram confirmadas pela tabela
--   solution do próprio jogo.
--
-- Quais foram as principais evidências encontradas?
--   - Relatório do crime: duas testemunhas e onde cada uma mora.
--   - Depoimento do Morty: bolsa da Get Fit Now de sócio GOLD com número
--     iniciado em "48Z" e placa contendo "H42W".
--   - Depoimento da Annabel: o assassino treinou na academia em 09/01/2018.
--   - Só Jeremy Bowers é sócio gold "48Z", fez check-in em 09/01 e tem a
--     placa 0H42W2.
--   - Depoimento do Jeremy: descrição da mulher que o contratou, que leva a
--     uma única pessoa, Miranda Priestly, com 3 idas ao concerto em
--     dezembro de 2017 e alta renda.
--
-- Quais tabelas foram fundamentais para solucionar o caso?
--   crime_scene_report (ponto de partida), person (identificar as pessoas),
--   interview (depoimentos), get_fit_now_member e get_fit_now_check_in
--   (academia), drivers_license (placa, carro e características físicas),
--   facebook_event_checkin (presença no concerto) e income (renda).
--
-- Como os relacionamentos entre tabelas contribuíram para a investigação?
--   Nenhuma tabela sozinha apontava o culpado. A pessoa (person) é o centro
--   do modelo: o id liga aos depoimentos e aos check-ins de eventos, o
--   license_id liga à carteira de motorista, o person_id liga ao cadastro
--   da academia, e o ssn liga à renda. Com INNER JOIN cada pista virou um
--   filtro sobre o mesmo conjunto de pessoas, e o cruzamento reduziu a
--   lista a um único suspeito. A subconsulta localizou as testemunhas sem
--   copiar ids na mão, e o GROUP BY com HAVING contou as idas ao concerto,
--   mostrando que relacionar as tabelas é o que transforma dados soltos
--   em prova.
