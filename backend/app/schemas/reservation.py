from datetime import date
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


class ReservationCreate(BaseModel):
    """Corps d'une demande de réservation."""

    model_config = ConfigDict(extra="forbid")
    item_id: int = Field(ge=1)
    date_debut: date
    date_fin: date

    @field_validator("date_debut")
    @classmethod
    def date_debut_pas_dans_le_passe(cls, valeur: date) -> date:
        """Refuse une date de début antérieure à aujourd'hui."""
        if valeur < date.today():
            raise ValueError("date_debut ne peut pas être dans le passé")
        return valeur

    @model_validator(mode="after")
    def date_fin_apres_date_debut(self):
        """Compare les deux dates, une fois toutes deux validées."""
        if self.date_fin <= self.date_debut:
            raise ValueError("date_fin doit être postérieure à date_debut")
        return self


class ReservationRead(BaseModel):
    """Réservation renvoyée par l'API."""

    id: int
    item_id: int
    date_debut: date
    date_fin: date
    statut: Literal["active", "annulee"]
