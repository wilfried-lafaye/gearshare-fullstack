# Mesures : index et `EXPLAIN ANALYZE`

Table `items` : 200 004 lignes (4 d'origine + 200 000 générées avec `generate_series`), `ANALYZE items` lancé avant chaque mesure. Commandes rejouables : `sql/mesures.sql` (les temps varient d'une machine à l'autre, les types de nœud non). Chaque chiffre est une mesure unique (`Execution Time`).

## Recherche exacte sur `titre`

Requête : `SELECT * FROM items WHERE titre = 'Item de test 123456';`

| | Nœud | Temps |
|---|---|---|
| Sans index | `Seq Scan` (200 003 lignes écartées) | 28,2 ms |
| Avec `idx_items_titre` | `Index Scan` | 0,24 ms |

Facteur d'accélération : environ × 118.

## Deux cas plus subtils

| Requête | Nœud | Temps |
|---|---|---|
| (a) `titre LIKE '%123456'` | `Seq Scan` | 33,8 ms |
| (b) `disponible = TRUE` | `Seq Scan` | 19,0 ms |
| (b) `disponible = FALSE` | `Index Scan` (0 ligne) | 0,11 ms |

**(a)** Un B-tree est trié par le début de la chaîne : avec un joker en tête, PostgreSQL ne sait pas où chercher dans l'arbre et lit toute la table.

**(b)** `TRUE` correspond aux 200 004 lignes, donc lire toute la table coûte moins qu'utiliser l'index ; `FALSE` ne correspond à aucune ligne, donc l'index la trouve tout de suite.

## Question bonus : `LIKE 'Item de test 12%'`

Le joker en fin de chaîne n'a pas utilisé l'index : `Seq Scan`, 23,5 ms, 11 111 lignes trouvées. La base utilise la collation `en_US.utf8`, dont l'ordre de tri n'est pas celui du début de chaîne. Un index `text_pattern_ops` le permettrait (non testé).
