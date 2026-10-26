-- Requêtes de l'étape 3, testées sur les données de sql/init/02-seed.sql.
-- Rejouer : docker compose exec -T db psql -U gearshare -d gearshare < sql/requetes.sql

-- 1. Items disponibles à moins de 10 €/jour, triés par tarif croissant
SELECT id, titre, tarif_jour
FROM items
WHERE disponible = TRUE AND tarif_jour < 10
ORDER BY tarif_jour ASC;
-- id |     titre     | tarif_jour
-- ----+---------------+------------
--  2 | Perceuse      |       5.00
--  1 | Vélo de ville |       8.50


-- 2. Items dont le titre contient « velo », insensible à la casse
SELECT id, titre
FROM items
WHERE titre ILIKE '%velo%';
-- (0 rows)
-- ILIKE ignore la casse mais pas les accents : « Vélo » ne contient pas « velo ».
-- Une recherche sans accent ne trouve donc pas le Vélo de ville.


-- 3. Chaque item avec le nom de son propriétaire
SELECT items.id, items.titre, users.display_name AS proprietaire
FROM items
JOIN users ON users.id = items.owner_id
ORDER BY items.id;
-- id |     titre      | proprietaire
-- ----+----------------+--------------
--  1 | Vélo de ville  | Alice
--  2 | Perceuse       | Alice
--  3 | Tente 2 places | Bob
--  4 | Appareil photo | Bob


-- 4. Nombre de réservations par item, y compris les items jamais réservés
SELECT items.id, items.titre, count(reservations.id) AS nb_reservations
FROM items
LEFT JOIN reservations ON reservations.item_id = items.id
GROUP BY items.id, items.titre
ORDER BY items.id;
-- id |     titre      | nb_reservations
-- ----+----------------+-----------------
--  1 | Vélo de ville  |               1
--  2 | Perceuse       |               0
--  3 | Tente 2 places |               1
--  4 | Appareil photo |               1
-- LEFT JOIN garde la Perceuse ; count(reservations.id) ignore le NULL (count(*) donnerait 1).


-- 5. Par utilisateur ayant publié au moins un item : nom, nombre d'items, tarif moyen
SELECT users.display_name,
       count(items.id) AS nb_items,
       round(avg(items.tarif_jour), 2) AS tarif_moyen
FROM users
JOIN items ON items.owner_id = users.id
GROUP BY users.id, users.display_name
ORDER BY users.display_name;
-- display_name | nb_items | tarif_moyen
-- --------------+----------+-------------
-- Alice        |        2 |        6.75
-- Bob          |        2 |       16.00
-- Chloé n'apparaît pas : elle n'a publié aucun item.


-- 6. Réservations actives dont le début est postérieur au 1er septembre 2026
SELECT reservations.id,
       items.titre,
       users.display_name AS emprunteur,
       reservations.date_debut,
       reservations.date_fin
FROM reservations
JOIN items ON items.id = reservations.item_id
JOIN users ON users.id = reservations.borrower_id
WHERE reservations.statut = 'active'
  AND reservations.date_debut > '2026-09-01'
ORDER BY reservations.date_debut;
-- id |     titre      | emprunteur | date_debut |  date_fin
-- ----+----------------+------------+------------+------------
--  2 | Tente 2 places | Alice      | 2026-09-10 | 2026-09-12
--  3 | Appareil photo | Chloé      | 2026-09-15 | 2026-09-20


-- 7. Les 2 items les plus chers, en sautant le premier
SELECT id, titre, tarif_jour
FROM items
ORDER BY tarif_jour DESC
LIMIT 2 OFFSET 1;
-- id |     titre      | tarif_jour
-- ----+----------------+------------
--  3 | Tente 2 places |      12.00
--  1 | Vélo de ville  |       8.50


-- 8. Chiffre d'affaires potentiel de chaque réservation active
SELECT reservations.id,
       items.titre,
       items.tarif_jour,
       reservations.date_fin - reservations.date_debut AS nb_jours,
       items.tarif_jour * (reservations.date_fin - reservations.date_debut) AS chiffre_affaires
FROM reservations
JOIN items ON items.id = reservations.item_id
WHERE reservations.statut = 'active'
ORDER BY reservations.id;
-- id |     titre      | tarif_jour | nb_jours | chiffre_affaires
-- ----+----------------+------------+----------+------------------
--  2 | Tente 2 places |      12.00 |        2 |            24.00
--  3 | Appareil photo |      20.00 |        5 |           100.00
