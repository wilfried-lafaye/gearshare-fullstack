-- Schéma v2 : avis, tags, anti-chevauchement des réservations, index sur les clés étrangères.
-- Joué après 01 (schéma) et 02 (données) : les contraintes ajoutées valident aussi le seed.

-- Un compte n'est jamais supprimé, il sera anonymisé : l'historique des prêts appartient aussi
-- aux autres utilisateurs (cf. ETAPE2.md). Les clés vers users sont donc recréées en RESTRICT,
-- explicite : un DELETE sur users est refusé au lieu de cascader sur le matériel et les emprunts.
-- Elles sont d'abord créées en 01 (CASCADE ou sans règle) pour garder l'étape 2 du TP rejouable.
ALTER TABLE items DROP CONSTRAINT fk_items_owner;
ALTER TABLE items ADD CONSTRAINT fk_items_owner FOREIGN KEY (owner_id)
    REFERENCES users (id) ON DELETE RESTRICT;
ALTER TABLE reservations DROP CONSTRAINT fk_reservations_borrower;
ALTER TABLE reservations ADD CONSTRAINT fk_reservations_borrower FOREIGN KEY (borrower_id)
    REFERENCES users (id) ON DELETE RESTRICT;

-- Règle 4 : btree_gist permet de mélanger l'égalité (item_id =) et le chevauchement (&&)
-- dans un même index GiST. Extension fournie avec l'image postgres:16.
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Règle 1 : cible de la clé étrangère composite de avis.
-- Redondant avec la clé primaire (id suffit à être unique), mais une clé étrangère
-- ne peut viser qu'une contrainte d'unicité portant exactement ses colonnes.
ALTER TABLE reservations
    ADD CONSTRAINT uq_reservations_id_statut UNIQUE (id, statut);

-- Règle 4 : deux réservations actives du même matériel ne peuvent pas se chevaucher.
-- '[)' = fin exclusive : une réservation qui finit le 5 et une autre qui commence le 5
-- sont permises. WHERE : seules les réservations actives comptent, une annulée libère la période.
ALTER TABLE reservations
    ADD CONSTRAINT ex_reservations_pas_de_chevauchement
    EXCLUDE USING gist (
        item_id WITH =,
        daterange(date_debut, date_fin, '[)') WITH &&
    ) WHERE (statut = 'active');

-- Règles 1 et 2 : un avis par réservation terminée.
CREATE TABLE avis (
    id             INTEGER GENERATED ALWAYS AS IDENTITY,
    reservation_id INTEGER     NOT NULL,
    -- Toujours 'terminee' : sert uniquement à alimenter la clé étrangère composite.
    statut         VARCHAR(20) NOT NULL DEFAULT 'terminee',
    note           SMALLINT    NOT NULL,
    commentaire    TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT pk_avis PRIMARY KEY (id),
    -- Règle 2 : une réservation n'a qu'un seul avis (crée aussi l'index de la clé étrangère).
    CONSTRAINT uq_avis_reservation UNIQUE (reservation_id),
    -- Règle 1 : note entière de 1 à 5.
    CONSTRAINT ck_avis_note CHECK (note BETWEEN 1 AND 5),
    CONSTRAINT ck_avis_statut_terminee CHECK (statut = 'terminee'),
    -- Règle 1 : la paire (reservation_id, 'terminee') doit exister dans reservations.
    -- ON UPDATE par défaut (NO ACTION) : on ne peut pas changer le statut d'une réservation notée.
    CONSTRAINT fk_avis_reservation FOREIGN KEY (reservation_id, statut)
        REFERENCES reservations (id, statut) ON DELETE CASCADE
);

-- Règle 3 : un tag est unique et en minuscules.
CREATE TABLE tags (
    id      INTEGER GENERATED ALWAYS AS IDENTITY,
    libelle VARCHAR(50) NOT NULL,
    CONSTRAINT pk_tags PRIMARY KEY (id),
    CONSTRAINT uq_tags_libelle UNIQUE (libelle),
    -- Rejette 'Vélo' sans le convertir : la mise en minuscules reste à faire côté API.
    CONSTRAINT ck_tags_libelle_minuscules CHECK (libelle = lower(libelle))
);

-- Règle 3 : table de jonction, un matériel a plusieurs tags et inversement.
CREATE TABLE item_tags (
    item_id INTEGER NOT NULL,
    tag_id  INTEGER NOT NULL,
    -- Interdit le doublon (même tag deux fois sur un matériel) et indexe item_id.
    CONSTRAINT pk_item_tags PRIMARY KEY (item_id, tag_id),
    CONSTRAINT fk_item_tags_item FOREIGN KEY (item_id)
        REFERENCES items (id) ON DELETE CASCADE,
    CONSTRAINT fk_item_tags_tag FOREIGN KEY (tag_id)
        REFERENCES tags (id) ON DELETE CASCADE
);

-- Index sur les clés étrangères. PostgreSQL n'en crée pas automatiquement.
-- Déjà couverts : avis.reservation_id (UNIQUE) et item_tags.item_id (début de la clé primaire).
CREATE INDEX idx_items_owner_id ON items (owner_id);
CREATE INDEX idx_reservations_item_id ON reservations (item_id);
CREATE INDEX idx_reservations_borrower_id ON reservations (borrower_id);
CREATE INDEX idx_item_tags_tag_id ON item_tags (tag_id);
