from fastapi import FastAPI

from app.routers import items, reservations

app = FastAPI(title="GearShare API", version="0.1.0")
app.include_router(items.router)
app.include_router(reservations.router)  # ajoute les routes à l'app et à /docs


@app.get("/health", tags=["monitoring"])
def health() -> dict[str, str]:
    """Vérifie que l'API répond."""
    return {"status": "ok"}
