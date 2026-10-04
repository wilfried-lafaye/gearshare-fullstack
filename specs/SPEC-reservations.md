# Ressource : reservations

Fichiers : `backend/app/schemas/reservation.py`, `backend/app/routers/reservations.py` <!-- modifié : le modèle du prof indiquait `app/...`, mais notre code est dans `backend/` -->
Stockage : dictionnaire en mémoire dans le router (comme `items`)

## Schémas
- `ReservationCreate` : item_id (int, >= 1), date_debut (date), date_fin (date)
- `ReservationRead` : id, item_id, date_debut, date_fin, statut ("active" | "annulee")
- À la création, `statut` vaut "active". <!-- ajouté : absent du modèle du prof, on précise le statut initial -->

## Routes (préfixe /reservations, tag "reservations")
- POST ""              → 201, ReservationRead. 422 si date_fin <= date_debut.
- GET  ""              → 200, list[ReservationRead]. Query : item_id optionnel, limit (défaut 20, max 100).
- GET  "/{reservation_id}" → 200, ReservationRead. 404 si absente.
- POST "/{reservation_id}/annuler" → 200, ReservationRead avec statut "annulee".
                                     404 si absente, 409 si déjà annulée.

## Contraintes
- Aucun accès à FAKE_DB de items.
- response_model sur toutes les routes.
- Pas de logique de validation en `if` dans le router : tout ce qui peut l'être dans Pydantic.
