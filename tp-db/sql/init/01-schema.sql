-- Schéma de base de GearShare : utilisateurs, matériel, réservations.
-- Contraintes nommées (pk_, fk_, uq_, ck_) : les noms servent à reconnaître l'erreur côté API.
-- Complété par 03-schema-v2.sql (avis, tags, anti-chevauchement).

CREATE TABLE users (
    id            INTEGER GENERATED ALWAYS AS IDENTITY,
    email         VARCHAR(255) NOT NULL,
    password_hash TEXT         NOT NULL,
    display_name  VARCHAR(80)  NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT uq_users_email UNIQUE (email)
);

CREATE TABLE items (
    id          INTEGER GENERATED ALWAYS AS IDENTITY,
    owner_id    INTEGER       NOT NULL,
    titre       VARCHAR(120)  NOT NULL,
    description TEXT,
    tarif_jour  NUMERIC(8, 2) NOT NULL,
    disponible  BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT pk_items PRIMARY KEY (id),
    CONSTRAINT fk_items_owner FOREIGN KEY (owner_id)
        REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT ck_items_tarif_positif CHECK (tarif_jour > 0)
);

CREATE TABLE reservations (
    id          INTEGER GENERATED ALWAYS AS IDENTITY,
    item_id     INTEGER     NOT NULL,
    borrower_id INTEGER     NOT NULL,
    date_debut  DATE        NOT NULL,
    date_fin    DATE        NOT NULL,
    statut      VARCHAR(20) NOT NULL DEFAULT 'active',
    CONSTRAINT pk_reservations PRIMARY KEY (id),
    CONSTRAINT fk_reservations_item FOREIGN KEY (item_id)
        REFERENCES items (id) ON DELETE CASCADE,
    CONSTRAINT fk_reservations_borrower FOREIGN KEY (borrower_id)
        REFERENCES users (id),
    CONSTRAINT ck_reservations_statut
        CHECK (statut IN ('active', 'annulee', 'terminee')),
    CONSTRAINT ck_reservations_dates CHECK (date_fin > date_debut)
);
