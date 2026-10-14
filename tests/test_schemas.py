from datetime import date, timedelta

import pytest
from pydantic import ValidationError

from app.schemas.reservation import ReservationCreate


def test_dates_egales_levent_une_erreur_de_validation() -> None:
    # Given : début et fin le même jour
    jour = date.today() + timedelta(days=10)

    # When / Then : l'erreur vient bien de date_fin
    with pytest.raises(ValidationError, match="date_fin"):
        ReservationCreate(item_id=1, date_debut=jour, date_fin=jour)


def test_date_debut_passee_leve_une_erreur_de_validation() -> None:
    # Given : le début est hier
    hier = date.today() - timedelta(days=1)
    demain = date.today() + timedelta(days=1)

    # When / Then : l'erreur vient bien de date_debut
    with pytest.raises(ValidationError, match="date_debut"):
        ReservationCreate(item_id=1, date_debut=hier, date_fin=demain)
