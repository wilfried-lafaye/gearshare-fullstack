from pydantic import BaseModel, ConfigDict, Field


class ItemCreate(BaseModel):
    """Corps de création (POST) et de remplacement (PUT) d'un item."""

    model_config = ConfigDict(extra="forbid")  # refuse les champs inconnus (422)
    titre: str = Field(min_length=3, max_length=120)
    description: str | None = Field(default=None, max_length=1000)
    tarif_jour: float = Field(gt=0)
    disponible: bool = True


class ItemUpdate(BaseModel):
    """Corps de modification partielle (PATCH) : tous les champs sont optionnels."""

    titre: str | None = Field(default=None, min_length=3, max_length=120)
    description: str | None = Field(default=None, max_length=1000)
    tarif_jour: float | None = Field(default=None, gt=0)
    disponible: bool | None = None


class ItemRead(BaseModel):
    """Item renvoyé par l'API."""

    id: int
    titre: str
    description: str | None
    tarif_jour: float
    disponible: bool
