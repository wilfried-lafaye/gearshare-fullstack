-- Mesures de MESURES.md : index et EXPLAIN ANALYZE sur 200 000 items.
-- Pas dans sql/init : à jouer à la main sur une base fraîche, depuis tp-db/ :
--   docker compose exec -T db psql -U gearshare -d gearshare < sql/mesures.sql
-- Les temps varient d'une exécution à l'autre ; les types de nœud ne changent pas.
-- Pour revenir à l'état du seed : docker compose down -v && docker compose up -d

-- Volume : 200 000 items à Alice (owner_id = 1), tarif aléatoire entre 1 et 51 €.
INSERT INTO items (owner_id, titre, tarif_jour)
SELECT 1, 'Item de test ' || n, round((1 + random() * 50)::numeric, 2)
FROM generate_series(1, 200000) AS n;
ANALYZE items;

-- Recherche exacte, sans index sur titre : Seq Scan.
EXPLAIN ANALYZE SELECT * FROM items WHERE titre = 'Item de test 123456';

-- Même recherche avec un index : Index Scan.
CREATE INDEX idx_items_titre ON items (titre);
ANALYZE items;
EXPLAIN ANALYZE SELECT * FROM items WHERE titre = 'Item de test 123456';

-- (a) Joker en tête : un B-tree est trié par le début de la chaîne, l'index ne sert pas.
EXPLAIN ANALYZE SELECT * FROM items WHERE titre LIKE '%123456';

-- (b) Colonne booléenne : l'index n'est utile que si peu de lignes correspondent.
CREATE INDEX idx_items_disponible ON items (disponible);
ANALYZE items;
EXPLAIN ANALYZE SELECT * FROM items WHERE disponible = TRUE;   -- toutes les lignes : Seq Scan
EXPLAIN ANALYZE SELECT * FROM items WHERE disponible = FALSE;  -- aucune ligne : Index Scan

-- Bonus : joker en fin de chaîne. Seq Scan avec la collation en_US.utf8 de la base.
EXPLAIN ANALYZE SELECT * FROM items WHERE titre LIKE 'Item de test 12%';
