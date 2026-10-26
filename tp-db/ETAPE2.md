# Étape 2 : casser la base

Jeu de données : `sql/init/02-seed.sql` (3 utilisateurs, 4 items, 3 réservations). Les 5 insertions et la suppression ont été jouées avec `psql` dans le conteneur, sur une base neuve. Le schéma v2 (`03-schema-v2.sql`) était déjà chargé ; il n'ajoute rien qui touche ces tests (aucun avis, aucun tag).

## Les cinq insertions refusées

| # | Cas | Contrainte violée | Type | Message d'erreur |
|---|---|---|---|---|
| 1 | Deuxième utilisateur `alice@esiee.fr` | `uq_users_email` | UNIQUE | `duplicate key value violates unique constraint "uq_users_email"` |
| 2 | Item avec `owner_id = 999` | `fk_items_owner` | clé étrangère | `insert or update on table "items" violates foreign key constraint "fk_items_owner"` |
| 3 | Item à tarif négatif | `ck_items_tarif_positif` | CHECK | `new row for relation "items" violates check constraint "ck_items_tarif_positif"` |
| 4 | Réservation qui finit avant de commencer | `ck_reservations_dates` | CHECK | `new row for relation "reservations" violates check constraint "ck_reservations_dates"` |
| 5 | Statut `en_attente_peut_etre` | `ck_reservations_statut` | CHECK | `new row for relation "reservations" violates check constraint "ck_reservations_statut"` |

Les cinq échouent, chacune pour la bonne raison. En séance 4, ces noms serviront à distinguer les erreurs interceptées en Python : 409 pour `uq_users_email`, 422 ou 409 pour les autres.

Remarque : un `INSERT` refusé consomme quand même une valeur de l'identité (`GENERATED ALWAYS AS IDENTITY`). Les ids ne sont donc pas continus après une erreur (le test 3 portait l'id 6).

## Suppression de Bob (clé étrangère sans `ON DELETE`)

Avant : Bob possède 2 items (3 et 4) et emprunte le vélo (réservation 1).

`DELETE FROM users WHERE id = 2;` est refusé :

```
ERROR:  update or delete on table "users" violates foreign key constraint "fk_reservations_borrower" on table "reservations"
DETAIL:  Key (id)=(2) is still referenced from table "reservations".
```

Après : rien n'a été supprimé, ni l'utilisateur, ni ses 2 items, ni les réservations (3 / 2 / 3). La base refuse tout ou rien : la cascade de `fk_items_owner` avait commencé à supprimer ses items, mais l'instruction est annulée en entier.

Sans `ON DELETE`, la clé étrangère `fk_reservations_borrower` vaut `NO ACTION` : la suppression est refusée tant qu'une réservation référence l'utilisateur.

## Même suppression avec `ON DELETE CASCADE` sur `borrower_id`

```sql
ALTER TABLE reservations DROP CONSTRAINT fk_reservations_borrower;
ALTER TABLE reservations ADD CONSTRAINT fk_reservations_borrower
    FOREIGN KEY (borrower_id) REFERENCES users (id) ON DELETE CASCADE;
```

Avant la suppression :

| id | item | propriétaire | emprunteur | statut |
|---|---|---|---|---|
| 1 | Vélo de ville | Alice | Bob | terminee |
| 2 | Tente 2 places | Bob | Alice | active |
| 3 | Appareil photo | Bob | Chloé | active |

`DELETE FROM users WHERE id = 2;` réussit (`DELETE 1`). Après : 2 utilisateurs, 0 item pour Bob (2 items au total, ceux d'Alice), et la table `reservations` est **vide**.

| Réservation perdue | Qui l'a perdue | Par quelle clé étrangère |
|---|---|---|
| 1, Vélo de ville | Bob (emprunteur) | `fk_reservations_borrower` : Bob est l'emprunteur |
| 2, Tente 2 places | Alice (emprunteuse) | `fk_items_owner` supprime d'abord l'item 3 (Bob), puis `fk_reservations_item` supprime ses réservations |
| 3, Appareil photo | Chloé (emprunteuse) | `fk_items_owner` supprime l'item 4 (Bob), puis `fk_reservations_item` supprime ses réservations |

Conséquence : en supprimant Bob, Alice et Chloé perdent aussi l'historique de leurs propres emprunts, pour une raison qui ne les concerne pas. La cascade passe par deux chemins (emprunteur, et propriétaire via l'item).

## Question de conception : que devient l'historique quand un compte est supprimé ?

**Décision** : supprimer un compte ne doit pas effacer de données, il doit seulement l'anonymiser. Les items, les réservations et les avis restent en place ; seules les données personnelles de l'utilisateur disparaissent.

**Raison** : l'historique des prêts n'appartient pas à un seul utilisateur. Avec la cascade, Alice et Chloé perdent leurs propres emprunts parce que Bob a quitté la plateforme.

**Conséquence pour le schéma** : le `ON DELETE CASCADE` depuis `users` n'est pas cohérent avec cette décision. À reprendre dans `REVIEW-schema.md` (point « `ON DELETE` explicites et cohérents avec le métier ») : `RESTRICT` explicite. L'implémentation de l'anonymisation (colonnes, requête, endpoint) est décidée mais reste à faire dans une séance ultérieure.

## Retour à l'état initial

`docker compose down -v && docker compose up -d` : la base est rechargée (3 / 4 / 3), avec `fk_reservations_borrower` sans `ON DELETE` comme dans `01-schema.sql`. Le `ALTER TABLE` n'a pas été reporté dans les fichiers du dépôt.
