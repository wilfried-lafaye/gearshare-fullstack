from datetime import date, timedelta
from typing import Any

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def reservation_active(client: TestClient) -> dict[str, Any]:
    """Une réservation active de l'item 1, du jour +10 au jour +15."""
    debut = date.today() + timedelta(days=10)
    fin = date.today() + timedelta(days=15)
    corps = {"item_id": 1, "date_debut": str(debut), "date_fin": str(fin)}

    response = client.post("/reservations", json=corps)

    assert response.status_code == 201
    return response.json()


# POST /reservations


def test_creer_reservation_valide_renvoie_201_et_est_relisible(client: TestClient) -> None:
    # Given
    debut = date.today() + timedelta(days=10)
    fin = date.today() + timedelta(days=15)
    corps = {"item_id": 1, "date_debut": str(debut), "date_fin": str(fin)}

    # When
    response = client.post("/reservations", json=corps)

    # Then : statut actif, et GET renvoie la même réservation
    assert response.status_code == 201
    reservation = response.json()
    assert reservation["statut"] == "active"
    assert client.get(f"/reservations/{reservation['id']}").json() == reservation


def test_creer_reservation_avec_fin_avant_debut_renvoie_422(client: TestClient) -> None:
    # Given : la fin est avant le début
    debut = date.today() + timedelta(days=15)
    fin = date.today() + timedelta(days=10)
    corps = {"item_id": 1, "date_debut": str(debut), "date_fin": str(fin)}

    # When
    response = client.post("/reservations", json=corps)

    # Then
    assert response.status_code == 422


def test_creer_reservation_qui_chevauche_une_active_renvoie_409(
    client: TestClient, reservation_active: dict[str, Any]
) -> None:
    # Given : la réservation existante va du jour +10 au jour +15 ; on demande du +12 au +18
    debut = date.today() + timedelta(days=12)
    fin = date.today() + timedelta(days=18)
    corps = {"item_id": 1, "date_debut": str(debut), "date_fin": str(fin)}

    # When
    response = client.post("/reservations", json=corps)

    # Then
    assert response.status_code == 409


def test_creer_reservation_qui_commence_quand_une_autre_finit_est_acceptee(
    client: TestClient, reservation_active: dict[str, Any]
) -> None:
    # Given : la réservation existante finit le jour +15 ; on demande du +15 au +20
    debut = date.today() + timedelta(days=15)
    fin = date.today() + timedelta(days=20)
    corps = {"item_id": 1, "date_debut": str(debut), "date_fin": str(fin)}

    # When
    response = client.post("/reservations", json=corps)

    # Then : la fin est exclusive, il n'y a pas de chevauchement
    assert response.status_code == 201


# GET /reservations


def test_lister_reservations_filtre_sur_item_id(
    client: TestClient, reservation_active: dict[str, Any]
) -> None:
    # Given : la fixture a réservé l'item 1 ; on réserve aussi l'item 2
    debut = date.today() + timedelta(days=10)
    fin = date.today() + timedelta(days=15)
    corps = {"item_id": 2, "date_debut": str(debut), "date_fin": str(fin)}
    autre = client.post("/reservations", json=corps)
    assert autre.status_code == 201

    # When
    response = client.get("/reservations", params={"item_id": 1})

    # Then
    resultats = response.json()
    assert len(resultats) == 1
    assert resultats[0]["id"] == reservation_active["id"]


# GET /reservations/{id}


def test_lire_reservation_existante_renvoie_200(
    client: TestClient, reservation_active: dict[str, Any]
) -> None:
    response = client.get(f"/reservations/{reservation_active['id']}")

    assert response.status_code == 200
    assert response.json() == reservation_active


def test_lire_reservation_absente_renvoie_404(client: TestClient) -> None:
    response = client.get("/reservations/999")

    assert response.status_code == 404


# POST /reservations/{id}/annuler


def test_annuler_reservation_renvoie_200_et_statut_annulee(
    client: TestClient, reservation_active: dict[str, Any]
) -> None:
    # Given
    reservation_id = reservation_active["id"]

    # When
    response = client.post(f"/reservations/{reservation_id}/annuler")

    # Then : le statut est changé, à la relecture aussi
    assert response.status_code == 200
    assert response.json()["statut"] == "annulee"
    assert client.get(f"/reservations/{reservation_id}").json()["statut"] == "annulee"


def test_annuler_reservation_absente_renvoie_404(client: TestClient) -> None:
    response = client.post("/reservations/999/annuler")

    assert response.status_code == 404


def test_annuler_deux_fois_renvoie_409(
    client: TestClient, reservation_active: dict[str, Any]
) -> None:
    # Given : une réservation déjà annulée
    reservation_id = reservation_active["id"]
    premiere = client.post(f"/reservations/{reservation_id}/annuler")
    assert premiere.status_code == 200

    # When
    response = client.post(f"/reservations/{reservation_id}/annuler")

    # Then
    assert response.status_code == 409
