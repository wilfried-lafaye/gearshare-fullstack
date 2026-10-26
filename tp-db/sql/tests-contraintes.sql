-- Tests des contraintes du schéma v2 (03-schema-v2.sql).
-- Chaque instruction marquée ÉCHEC doit être rejetée, par la contrainte indiquée.
-- À jouer sur une base fraîche (seed de 02-seed.sql), sans ON_ERROR_STOP, depuis tp-db/ :
--   docker compose exec -T db psql -U gearshare -d gearshare < sql/tests-contraintes.sql
-- Ids du seed : réservation 1 = terminee (vélo), 2 et 3 = active ; item 3 = tente (du 10 au 12/09).

-- Préparation : un avis valide, un tag valide, un tag sur un matériel (doivent réussir).
INSERT INTO avis (reservation_id, note, commentaire) VALUES (1, 4, 'Très bon vélo');
INSERT INTO tags (libelle) VALUES ('velo');
INSERT INTO item_tags (item_id, tag_id) VALUES (1, 1);

-- ÉCHEC 1 : note à 6 -> ck_avis_note
INSERT INTO avis (reservation_id, note) VALUES (1, 6);

-- ÉCHEC 2 : deuxième avis sur la même réservation -> uq_avis_reservation
INSERT INTO avis (reservation_id, note) VALUES (1, 3);

-- ÉCHEC 3 : deux tags de même libellé -> uq_tags_libelle
INSERT INTO tags (libelle) VALUES ('velo');

-- ÉCHEC 4 : avis sur une réservation inexistante -> fk_avis_reservation
INSERT INTO avis (reservation_id, note) VALUES (999, 5);

-- ÉCHEC 5 : avis sur une réservation non terminée (la 2 est active) -> fk_avis_reservation
INSERT INTO avis (reservation_id, note) VALUES (2, 5);

-- ÉCHEC 6 : changer le statut d'une réservation qui a un avis -> fk_avis_reservation
UPDATE reservations SET statut = 'annulee' WHERE id = 1;

-- ÉCHEC 7 : tag avec une majuscule -> ck_tags_libelle_minuscules
INSERT INTO tags (libelle) VALUES ('Vélo');

-- ÉCHEC 8 : même tag deux fois sur le même matériel -> pk_item_tags
INSERT INTO item_tags (item_id, tag_id) VALUES (1, 1);

-- ÉCHEC 9 : tag sur un matériel inexistant -> fk_item_tags_item
INSERT INTO item_tags (item_id, tag_id) VALUES (999, 1);

-- ÉCHEC 10 : réservation active qui chevauche celle de la tente (10 au 12/09) -> ex_reservations_pas_de_chevauchement
INSERT INTO reservations (item_id, borrower_id, date_debut, date_fin, statut)
VALUES (3, 3, '2026-09-11', '2026-09-13', 'active');

-- Contrôles qui doivent RÉUSSIR (la contrainte ne bloque pas trop) :
-- période adjacente (la fin est exclusive) et chevauchement avec une réservation annulée.
INSERT INTO reservations (item_id, borrower_id, date_debut, date_fin, statut)
VALUES (3, 3, '2026-09-12', '2026-09-14', 'active');
INSERT INTO reservations (item_id, borrower_id, date_debut, date_fin, statut)
VALUES (3, 3, '2026-09-10', '2026-09-12', 'annulee');

-- Nettoyage : retour à l'état du seed (les identités consomment des ids, pas de souci).
DELETE FROM reservations WHERE id > 3;
DELETE FROM item_tags;
DELETE FROM tags;
DELETE FROM avis;
