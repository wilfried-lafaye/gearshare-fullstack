Agent utilisé : Claude Code, et non GitHub Copilot (choix assumé : le prof impose Copilot, un second LLM est autorisé, cf. `OUTILS.md`).

Ce fichier est mis à jour au fur et à mesure. Chaque étape contient : mon message tel quel, la réponse de l'agent, ma correction, la raison.

---

## Étape 1 : proposition du schéma v2 par règle (sans code)

### Mon message (tel quel)

Tâche : écrire `tp-db/sql/init/03-schema-v2.sql` pour ces règles :
1. Après une réservation `terminee`, l'emprunteur peut laisser un avis : note entière de 1 à 5, commentaire optionnel.
2. Un avis est lié à une seule réservation, et une réservation n'a qu'un seul avis.
3. Un matériel a plusieurs tags, un tag peut être sur plusieurs matériels. Libellé de tag unique et en minuscules.
4. Un même matériel n'a pas deux réservations actives qui se chevauchent.
Contraintes : PostgreSQL 16, contraintes nommées, `TIMESTAMPTZ`, index sur les clés étrangères.

Méthode : 1) propose d'abord, par règle, le mécanisme choisi et ce que la base ne garantit pas seule, sans code ; 2) après mon accord, écris le DDL avec un bref commentaire par choix ; 3) applique-le sur une base neuve (`docker compose down -v && docker compose up -d`, depuis `tp-db/`).

Ne fais pas la review ni `sql/tests-contraintes.sql` : c'est moi qui les fais.

Journal : crée `prompts/seance-3.md` au format de `prompts/seance-2.md`, mis à jour au fil de l'eau. Ce prompt est la première étape.

### Réponse de l'agent

Lecture de `tp-db/sql/init/01-schema.sql`, `02-seed.sql`, `docker-compose.yml` et de `prompts/seance-2.md`. Aucun SQL écrit, rien appliqué. Seul `prompts/seance-3.md` est créé.

Proposition, par règle :

1. **Avis (note 1 à 5, commentaire optionnel)** : table `avis` avec `note SMALLINT NOT NULL` et `CHECK (note BETWEEN 1 AND 5)`, `commentaire TEXT` nullable, `created_at TIMESTAMPTZ`. Pas de colonne d'auteur : l'auteur est l'emprunteur de la réservation, donc il ne peut pas être incohérent. La base ne garantit pas seule que la réservation est `terminee` (un `CHECK` ne voit pas une autre table). Deux options : clé étrangère composite `(reservation_id, statut)` vers `reservations` avec `UNIQUE (id, statut)` et `statut = 'terminee'` dans `avis` (la base bloque même un retour en arrière du statut), ou contrôle dans l'API.
2. **Un avis par réservation** : `UNIQUE (reservation_id)` sur `avis` en plus de la clé étrangère. Le `UNIQUE` crée l'index de la clé étrangère. Non garanti : que celui qui poste soit bien l'emprunteur (c'est l'authentification de l'API).
3. **Tags** : table `tags` (`libelle` avec `UNIQUE` et `CHECK (libelle = lower(libelle))`) et table de jonction `item_tags` avec clé primaire `(item_id, tag_id)` et deux clés étrangères. Index supplémentaire sur `tag_id` ; la clé primaire couvre déjà `item_id`. Non garanti : la base rejette `Vélo` mais ne le convertit pas (l'API doit appliquer `lower()` et `strip()`), `lower()` ne règle pas les accents (`vélo` et `velo` restent deux tags), et un libellé vide passe sans `CHECK` supplémentaire.
4. **Pas de chevauchement** : contrainte `EXCLUDE USING gist` sur `(item_id WITH =, daterange(date_debut, date_fin, '[)') WITH &&) WHERE (statut = 'active')`, avec l'extension `btree_gist`. Les bornes `[)` rendent la fin exclusive, donc deux périodes adjacentes restent permises, comme dans les tests de la séance 2. Non garanti : seul `active` bloque (une `annulee` libère la période) ; disponibilité de l'item, dates futures et emprunteur différent du propriétaire restent à l'API.

Points à trancher :
- **DATE ou TIMESTAMPTZ** : `reservations.date_debut` et `date_fin` sont des `DATE` depuis la séance 1. Je propose de les garder en `DATE` (changer le type serait une migration hors sujet, et l'API manipule des dates) et d'utiliser `TIMESTAMPTZ` pour les nouveaux horodatages (`created_at`).
- **Index sur les clés étrangères existantes** : `items.owner_id`, `reservations.item_id` et `reservations.borrower_id` n'ont aucun index. Je propose de les ajouter dans le même fichier. L'index `gist` de l'exclusion ne remplace pas un `btree` sur `item_id`.
- **Statut `terminee`** : clé étrangère composite (la base le garantit) ou contrôle dans l'API (plus simple à expliquer) ?

Les données de `02-seed.sql` respectent les règles : aucune réservation active ne se chevauche.

### Ma correction

1. Garder `DATE` pour les réservations, `TIMESTAMPTZ` pour les nouvelles colonnes.
2. Oui pour les index sur les clés étrangères existantes.
3. Statut `terminee` : pas de décision, je demande d'abord une explication de la clé composite, avec un exemple refusé.

### Raison

- **`DATE` conservé** : pas de migration de type hors sujet, l'API manipule des dates.
- **Index sur les clés étrangères existantes** : la consigne les demande sur toutes les clés étrangères.
- **Explication avant décision** : règle 1 du prof, je dois pouvoir justifier chaque ligne avant de la valider.

---

## Étape 2 : explication de la clé étrangère composite

### Mon message (tel quel)

1. Garde DATE pour les réservations, TIMESTAMPTZ pour les nouvelles colonnes
2. Oui pour les index sur les clés étrangères existantes
3. Explique-moi d'abord la clé composite en quelques lignes, avec un exemple refusé

### Réponse de l'agent

Explication seule, sans SQL écrit dans le dépôt. Principe : `avis` porte une colonne `statut` fixée à `terminee` (`CHECK`), et sa clé étrangère vise `(id, statut)` de `reservations`. Une paire `(2, 'terminee')` n'existe que si la réservation 2 est terminée. Exemple refusé avec le seed : avis sur la réservation 2 (active) refusé ; passer la réservation 1 à `annulee` alors qu'elle a un avis, refusé aussi. Contrepartie : `UNIQUE (id, statut)` redondant sur `reservations`, et une réservation notée ne peut plus changer de statut sans supprimer l'avis.

### Ma correction

Je prends la clé composite.

### Raison

- **Clé composite** : la base garantit seule que l'avis porte sur une réservation `terminee`, et bloque aussi un retour en arrière du statut. Je l'ai choisie après avoir compris l'exemple refusé.

---

## Étape 3 : écriture du DDL et application sur une base neuve

### Mon message (tel quel)

je prends la clé composite

### Réponse de l'agent

Création de `tp-db/sql/init/03-schema-v2.sql`, avec un commentaire par choix.

- Extension `btree_gist`.
- `reservations` : `UNIQUE (id, statut)` (cible de la clé composite) et `EXCLUDE USING gist` sur `item_id` et `daterange(date_debut, date_fin, '[)')`, limité aux réservations `active`.
- Table `avis` : `UNIQUE (reservation_id)`, `CHECK` sur la note (1 à 5) et sur le statut, clé étrangère composite `(reservation_id, statut)`, `created_at` en `TIMESTAMPTZ`.
- Tables `tags` (`UNIQUE` + `CHECK (libelle = lower(libelle))`) et `item_tags` (clé primaire `(item_id, tag_id)`, deux clés étrangères).
- Quatre index : `items.owner_id`, `reservations.item_id`, `reservations.borrower_id`, `item_tags.tag_id`. `avis.reservation_id` et `item_tags.item_id` sont déjà couverts par le `UNIQUE` et la clé primaire.

Application depuis `tp-db/` : `docker compose down -v && docker compose up -d`. La base passe `healthy`, aucune erreur dans les logs. Vérification : 6 tables, 13 contraintes nommées attendues, 4 index présents. Je n'ai pas lancé de test de rejet : `sql/tests-contraintes.sql` et la review restent à faire de mon côté. Pas de commit.


---

## Étape 4 : vérification des commentaires, de la simplicité et de la qualité du code SQL

### Mon message (tel quel)

vérifie la bonne présence  commentaires des codes sql, la simplicité du code et la qualité du code fournit pendant cette seance

### Réponse de l'agent

Relecture de tous les fichiers SQL de la séance, sans rien modifier. `requetes.sql` rejoué : les résultats en commentaire correspondent à ceux de la base. Constat global : code simple, contraintes nommées de façon cohérente, un commentaire par choix dans `03-schema-v2.sql`. Trois défauts relevés :

1. Les mesures de `MESURES.md` ne sont pas reproductibles : les commandes (`generate_series`, `CREATE INDEX`, `ANALYZE`, `EXPLAIN ANALYZE`) ne sont dans aucun fichier du dépôt.
2. Le correctif `RESTRICT` de `03-schema-v2.sql` est un patch (clés recréées après `01-schema.sql`) et son commentaire « Correction de la review » n'explique pas la raison métier.
3. `01-schema.sql` n'a aucun commentaire, et « ECHEC » est écrit sans accent dans `tests-contraintes.sql`.

Autre point : le journal ne traçait pas la création des requêtes et des mesures. Aucune correction appliquée. Pas de commit.


---

## Étape 5 : mot de passe de la base hors du dépôt

### Mon message (tel quel)

Mets le mot de passe de bdd dans .env pour respecter la règle du prof

### Réponse de l'agent

Historique git vérifié (`git log --all -S`) : le mot de passe de `tp-db/docker-compose.yml` n'a jamais été commité (`tp-db/` n'est pas suivi, `origin/main` identique aux commits locaux) ; seul `.env.example` racine contient `change-me`. Après mon accord : `tp-db/docker-compose.yml` lit `POSTGRES_USER`, `POSTGRES_PASSWORD` et `POSTGRES_DB` depuis `.env` (même convention que le `.env.example` racine) ; le mot de passe est obligatoire (`:?`), le message d'erreur dit de copier `.env.example`. Ajout de `tp-db/.env.example` (valeurs fictives) ; `tp-db/.env` est ignoré par le `.gitignore` existant. Vérifié : sans `.env`, `docker compose` refuse de démarrer ; avec `.env`, la base passe `healthy` et les 10 échecs de `tests-contraintes.sql` sont inchangés. Pas de commit.

### Raison

Règle 5 du prof : aucun secret commité.

---

## Étape 6  : correction des défauts de l'étape 7

### Mon message (tel quel)

Ajoute de quoi refaire les tests.

### Réponse de l'agent

- Création de `tp-db/sql/mesures.sql` (génération des 200 000 items, `ANALYZE`, index, `EXPLAIN ANALYZE` de chaque cas) ; rejoué sur une base neuve : mêmes types de nœud que dans `MESURES.md` (Seq Scan sans index, Index Scan avec index, Seq Scan pour `LIKE '%123456'`, `disponible = TRUE` et `LIKE 'Item de test 12%'`, Index Scan pour `disponible = FALSE`), temps différents selon la machine. `MESURES.md` renvoie vers ce fichier.
- Commentaire du bloc `RESTRICT` de `03-schema-v2.sql` réécrit : il donne la raison métier (anonymisation) et pourquoi les clés sont d'abord créées en `01`.
- En-tête ajouté à `01-schema.sql` ; « ECHEC » corrigé en « ÉCHEC » dans `tests-contraintes.sql`.
- Base reconstruite : aucune erreur dans les logs, `requetes.sql` sans erreur, 10 échecs de `tests-contraintes.sql` inchangés, base remise à l'état du seed (4 items, 3 réservations). Pas de commit.


---

## Étape 7 : décision sur la suppression d'un compte (échange ayant eu lieu après l'étape 4)

### Mon message (tel quel)

supprimer un compte doit juste anonymiser

(puis, après la réponse de l'agent)

J'ai l'impression que ce que je viens de dire, c'est pas en accord, je vais plus loin que ce que propose le prof, est-ce que c'est une question posée par le prof, le fait de qu'est-ce que ça devient si on supprime

(puis)

écris-le dans ETAPE2.md

(puis, plus tard)

ajoute la décision d'anonymiser au journal de la séance

### Réponse de l'agent

Première réponse : l'agent a développé les conséquences d'une anonymisation (`deleted_at`, écrasement de l'email pour garder `UNIQUE`, `RESTRICT` sur les clés vers `users`, sort des items et des réservations à venir) et proposé de modifier le schéma. Après ma question, il a confirmé que la suppression d'un compte est bien une question posée par le prof (fin de l'étape 2 du TP, à répondre en 2 ou 3 lignes dans `REVIEW-schema.md`), que ma réponse est valable, et que ce qu'il avait ajouté (colonnes, requête d'anonymisation, endpoint) allait plus loin que ce qui est demandé. Seul changement de schéma utile pour le TP : `ON DELETE RESTRICT` explicite, pour rester cohérent avec la décision.

Ensuite, à ma demande : décision, raison et conséquence pour le schéma écrites dans la section « Question de conception » de `tp-db/ETAPE2.md` ; le passage à `RESTRICT` a été fait pendant la review (étape 6).

### Ma correction

Décision : **supprimer un compte ne doit pas effacer de données, il doit seulement l'anonymiser.** J'ai aussi recadré l'agent, qui était parti trop loin : je garde le périmètre du TP (une décision écrite et le `RESTRICT` cohérent), l'implémentation de l'anonymisation est repoussée à une séance ultérieure (séance 4 ou 5).

### Raison

- L'historique des prêts n'appartient pas à un seul utilisateur : avec `CASCADE`, la suppression de Bob a effacé les emprunts d'Alice et de Chloé (voir `tp-db/ETAPE2.md`).
- Le prof demande explicitement de noter la décision, « un choix de conception, pas un détail » ; il ne demande pas de l'implémenter dans ce TP.
- Un `ON DELETE CASCADE` depuis `users` aurait contredit cette décision, d'où `RESTRICT`.
