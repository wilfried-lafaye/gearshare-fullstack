from fastapi import APIRouter, HTTPException, Path, Query

from app.schemas.reservation import ReservationCreate, ReservationRead

router = APIRouter(prefix="/reservations", tags=["reservations"])

# Stockage en mémoire, propre à ce router
RESERVATIONS_DB: dict[int, dict] = {}
_next_id = 1


@router.post("", response_model=ReservationRead, status_code=201)
def create_reservation(payload: ReservationCreate):
    """Crée une réservation active ; 409 si la période chevauche une réservation active du même item."""
    global _next_id
    for existante in RESERVATIONS_DB.values():
        # Périodes à fin exclusive : fin le 15 et début le 15 ne se chevauchent pas
        if (
            existante["item_id"] == payload.item_id
            and existante["statut"] == "active"
            and payload.date_debut < existante["date_fin"]
            and existante["date_debut"] < payload.date_fin
        ):
            raise HTTPException(
                status_code=409,
                detail=f"Item {payload.item_id} déjà réservé sur cette période",
            )
    reservation = {"id": _next_id, "statut": "active", **payload.model_dump()}
    RESERVATIONS_DB[_next_id] = reservation
    _next_id += 1
    return reservation


@router.get("", response_model=list[ReservationRead])
def list_reservations(
    item_id: int | None = Query(default=None, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
):
    """Liste les réservations, filtrées par item si `item_id` est donné."""
    reservations = []
    for reservation in RESERVATIONS_DB.values():
        if item_id is None or reservation["item_id"] == item_id:
            reservations.append(reservation)
    return reservations[:limit]


@router.get("/{reservation_id}", response_model=ReservationRead)
def get_reservation(reservation_id: int = Path(ge=1)):
    """Renvoie une réservation ; 404 si elle n'existe pas."""
    reservation = RESERVATIONS_DB.get(reservation_id)
    if reservation is None:
        raise HTTPException(
            status_code=404, detail=f"Réservation {reservation_id} introuvable"
        )
    return reservation


@router.post("/{reservation_id}/annuler", response_model=ReservationRead)
def cancel_reservation(reservation_id: int = Path(ge=1)):
    """Annule une réservation ; 404 si absente, 409 si déjà annulée."""
    reservation = RESERVATIONS_DB.get(reservation_id)
    if reservation is None:
        raise HTTPException(
            status_code=404, detail=f"Réservation {reservation_id} introuvable"
        )
    if reservation["statut"] == "annulee":
        raise HTTPException(
            status_code=409, detail=f"Réservation {reservation_id} déjà annulée"
        )
    reservation["statut"] = "annulee"
    return reservation
