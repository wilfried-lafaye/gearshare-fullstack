from fastapi import APIRouter, HTTPException, Path, Query, Response

from app.schemas.item import ItemCreate, ItemRead, ItemUpdate

router = APIRouter(prefix="/items", tags=["items"])

# Stockage en mémoire : id -> item
FAKE_DB: dict[int, dict] = {}


def _next_id() -> int:
    # L'id se déduit du dictionnaire : un seul état à remettre à zéro
    return max(FAKE_DB, default=0) + 1


@router.get("", response_model=list[ItemRead])
def list_items(
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    q: str | None = None,
    disponible: bool | None = None,
):
    """Liste les items, filtrés par titre (`q`) et disponibilité, avec pagination."""
    items = []
    for item in FAKE_DB.values():
        garder = True
        if q is not None and q.lower() not in item["titre"].lower():
            garder = False
        if disponible is not None and item["disponible"] != disponible:
            garder = False
        if garder:
            items.append(item)
    fin = skip + limit
    return items[skip:fin]


@router.post("", response_model=ItemRead, status_code=201)
def create_item(payload: ItemCreate):
    """Crée un item et lui attribue le prochain id."""
    item_id = _next_id()
    item = {"id": item_id, **payload.model_dump()}
    FAKE_DB[item_id] = item
    return item


@router.put("/{item_id}", response_model=ItemRead)
def replace_item(payload: ItemCreate, item_id: int = Path(ge=1)):
    """Remplace entièrement un item ; 404 s'il n'existe pas."""
    if item_id not in FAKE_DB:
        raise HTTPException(status_code=404, detail=f"Item {item_id} introuvable")
    item = payload.model_dump()
    item["id"] = item_id
    FAKE_DB[item_id] = item
    return item


@router.patch("/{item_id}", response_model=ItemRead)
def update_item(payload: ItemUpdate, item_id: int = Path(ge=1)):
    """Modifie seulement les champs envoyés ; 404 si l'item n'existe pas."""
    item = FAKE_DB.get(item_id)
    if item is None:
        raise HTTPException(status_code=404, detail=f"Item {item_id} introuvable")
    # exclude_unset : ignore les champs que le client n'a pas envoyés
    data = payload.model_dump(exclude_unset=True)
    item.update(data)
    return item


@router.get("/{item_id}", response_model=ItemRead)
def get_item(item_id: int = Path(ge=1)):
    """Renvoie un item ; 404 s'il n'existe pas."""
    item = FAKE_DB.get(item_id)
    if item is None:
        raise HTTPException(status_code=404, detail=f"Item {item_id} introuvable")
    return item


@router.delete("/{item_id}", status_code=204, response_class=Response)
def delete_item(item_id: int = Path(ge=1)):
    """Supprime un item (204, sans corps) ; 404 s'il n'existe pas."""
    if item_id not in FAKE_DB:
        raise HTTPException(status_code=404, detail=f"Item {item_id} introuvable")
    del FAKE_DB[item_id]
