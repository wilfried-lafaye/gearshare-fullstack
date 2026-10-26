# Review du schéma v2

## Grille

| Point de contrôle | OK / KO | Ce que j'ai corrigé |
|---|---|---|
| Chaque table a une clé primaire | OK | `users`, `items`, `reservations`, `avis`, `tags` : clé sur `id`. `item_tags` : clé composite `(item_id, tag_id)`. |
| Les clés étrangères sont déclarées avec `REFERENCES` | OK | Les 6 clés étrangères sont nommées (`fk_*`). |
| Les `ON DELETE` sont explicites et cohérents avec le métier | **KO puis corrigé** | Voir ci-dessous. |
| « Un seul avis par réservation » garanti par `UNIQUE` | OK | `uq_avis_reservation`. |
| Note bornée par `CHECK (note BETWEEN 1 AND 5)` | OK | `ck_avis_note`. |
| Table de liaison item/tag à clé primaire composite | OK | `pk_item_tags`. |
| Libellé de tag `UNIQUE` | OK | `uq_tags_libelle`, plus `ck_tags_libelle_minuscules`. |
| Contraintes nommées | OK | Toutes les contraintes déclarées ont un nom (vérifié dans `pg_constraint`). |
| Index sur les clés étrangères | OK | 4 index créés. `avis.reservation_id` est couvert par `uq_avis_reservation`, `item_tags.item_id` par `pk_item_tags`. Les index sur `items.owner_id` et `reservations.item_id` / `borrower_id` manquaient dans le schéma de base. |
| Non-chevauchement réellement garanti | OK | Contrainte d'exclusion, voir ci-dessous. |
| Pas de flottant pour un montant, pas de `TIMESTAMP` sans fuseau | OK | `tarif_jour` en `NUMERIC(8, 2)`, tous les horodatages en `TIMESTAMPTZ`. `date_debut` / `date_fin` en `DATE`, voulu : une réservation est à la journée. |

## `ON DELETE` : le point KO

Constat : dans `01-schema.sql`, `fk_items_owner` était en `CASCADE` et `fk_reservations_borrower` sans règle explicite (`NO ACTION`). L'étape 2 du TP a montré le danger : avec `CASCADE` sur l'emprunteur, supprimer Bob vide la table `reservations`, y compris les emprunts d'Alice et de Chloé (voir `ETAPE2.md`).

**Décision (réponse à la question du TP)** : supprimer un compte ne doit pas effacer l'historique des prêts. Le compte sera anonymisé, pas supprimé. Raison : cet historique appartient aussi aux autres utilisateurs.

**Correction** : `fk_items_owner` et `fk_reservations_borrower` sont maintenant `ON DELETE RESTRICT`, écrit explicitement (ajouté en tête de `03-schema-v2.sql`). Vérifié : `DELETE` d'un utilisateur refusé tant qu'il a des items ou des emprunts, avec `fk_items_owner` ou `fk_reservations_borrower` dans le message. L'anonymisation elle-même (colonnes, requête, endpoint) est décidée mais pas encore implémentée.

Les autres règles sont gardées en `CASCADE`, volontairement :
- `item_tags` (→ `items`, → `tags`) : simple table de liaison, une ligne n'a de sens que si ses deux côtés existent.
- `avis` (→ `reservations`) : un avis n'existe pas sans sa réservation.

**Point laissé ouvert** : `fk_reservations_item` reste en `CASCADE`. Supprimer un matériel efface donc les réservations qui le concernent, y compris l'historique des emprunteurs. L'API a une route `DELETE /items/{id}`. Je ne l'ai pas changé dans ce TP ; à trancher quand l'API sera branchée sur la base (séance 4) : `RESTRICT`, ou retrait du matériel plutôt que suppression (`disponible = FALSE`).

## Non-chevauchement des réservations

Garanti par la base : `ex_reservations_pas_de_chevauchement`, une contrainte d'exclusion (`EXCLUDE USING gist`) sur `item_id` et `daterange(date_debut, date_fin, '[)')`, limitée aux réservations `active`. Elle demande l'extension `btree_gist` pour combiner égalité et chevauchement.

Choix de conception :
- Bornes `[)` : une réservation qui finit le 12 et une autre qui commence le 12 sont permises (testé).
- Seules les réservations `active` comptent : une réservation `annulee` libère la période (testé).
- Pourquoi la base plutôt que l'API : un contrôle applicatif « lire puis insérer » échoue si deux requêtes arrivent en même temps. La contrainte tient quoi qu'il arrive.

Ce que la base ne garantit pas, et que l'API devra vérifier : matériel disponible (`disponible`), dates dans le futur, emprunteur différent du propriétaire.

## Limites connues (non corrigées)

- **Tags** : `ck_tags_libelle_minuscules` rejette `Vélo` mais ne le convertit pas ; l'API doit appliquer `lower()` et `strip()`. `vélo` et `velo` restent deux tags distincts, et un libellé vide passe.
- **Avis** : la base garantit que la réservation est `terminee`, mais pas que l'auteur de l'avis est l'emprunteur (il n'y a pas de colonne auteur, il se déduit de la réservation). C'est à l'authentification de l'API de le contrôler.
- **Contrepartie de la clé composite** : une réservation qui a un avis ne peut plus changer de statut (testé, `fk_avis_reservation`). Voulu, mais à garder en tête pour l'API.
- **`created_at` / avis** : `statut` dans `avis` est une colonne technique, toujours `terminee`, qui n'existe que pour la clé étrangère composite.

## Preuve

`sql/tests-contraintes.sql` : 10 instructions rejetées, chacune par la contrainte attendue (nom lu dans le message), et 2 contrôles qui réussissent. Rejoué après la correction `RESTRICT` : les 10 échecs sont inchangés.

Usage de l'IA : le journal du travail avec l'agent est dans `prompts/seance-3.md`.
