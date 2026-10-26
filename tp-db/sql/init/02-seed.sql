-- Les id sont générés par la base, dans l'ordre d'insertion (1, 2, 3...).
-- Les mots de passe sont des chaînes factices, pas de vrais hashs.

INSERT INTO users (email, password_hash, display_name) VALUES
    ('alice@esiee.fr', 'hash-factice-alice', 'Alice'),
    ('bob@esiee.fr',   'hash-factice-bob',   'Bob'),
    ('chloe@esiee.fr', 'hash-factice-chloe', 'Chloé');

-- owner_id : 1 = Alice, 2 = Bob
INSERT INTO items (owner_id, titre, description, tarif_jour) VALUES
    (1, 'Vélo de ville',   'Cadre alu, panier avant', 8.50),
    (1, 'Perceuse',        'Avec jeu de mèches',      5.00),
    (2, 'Tente 2 places',  NULL,                      12.00),
    (2, 'Appareil photo',  'Reflex + objectif 50mm',  20.00);

-- item_id : 1 = Vélo, 3 = Tente, 4 = Appareil photo
-- borrower_id : 1 = Alice, 2 = Bob, 3 = Chloé
INSERT INTO reservations (item_id, borrower_id, date_debut, date_fin, statut) VALUES
    (1, 2, '2026-09-01', '2026-09-05', 'terminee'),
    (3, 1, '2026-09-10', '2026-09-12', 'active'),
    (4, 3, '2026-09-15', '2026-09-20', 'active');
