from typing import Any

from fastapi.testclient import TestClient


# POST /items


def test_creer_item_valide_renvoie_201_et_est_relisible(client: TestClient) -> None:
    # Given
    corps = {"titre": "Vélo de ville", "tarif_jour": 8.5}

    # When
    creation = client.post("/items", json=corps)

    # Then : GET renvoie le même item
    assert creation.status_code == 201
    item = creation.json()
    assert client.get(f"/items/{item['id']}").json() == item


def test_creer_item_avec_titre_trop_court_renvoie_422(client: TestClient) -> None:
    response = client.post("/items", json={"titre": "ab", "tarif_jour": 5})

    assert response.status_code == 422


# GET /items


def test_lister_avec_q_filtre_sur_le_titre(client: TestClient, item_velo: dict[str, Any]) -> None:
    # Given : un second item qui ne doit pas ressortir
    tente = client.post("/items", json={"titre": "Tente", "tarif_jour": 4})
    assert tente.status_code == 201

    # When
    response = client.get("/items", params={"q": "vélo"})

    # Then
    resultats = response.json()
    assert len(resultats) == 1
    assert resultats[0]["id"] == item_velo["id"]


def test_lister_avec_skip_et_limit_renvoie_la_bonne_page(
    client: TestClient, item_velo: dict[str, Any]
) -> None:
    # Given : un second item
    tente = client.post("/items", json={"titre": "Tente", "tarif_jour": 4})
    assert tente.status_code == 201

    # When : on saute le premier et on en prend un seul
    response = client.get("/items", params={"skip": 1, "limit": 1})

    # Then : il ne reste que la tente
    resultats = response.json()
    assert len(resultats) == 1
    assert resultats[0]["titre"] == "Tente"


def test_lister_avec_disponible_true_exclut_les_items_indisponibles(
    client: TestClient, item_velo: dict[str, Any]
) -> None:
    # Given : un item indisponible en plus du vélo disponible
    tente = client.post("/items", json={"titre": "Tente", "tarif_jour": 4, "disponible": False})
    assert tente.status_code == 201

    # When
    response = client.get("/items", params={"disponible": "true"})

    # Then
    resultats = response.json()
    assert len(resultats) == 1
    assert resultats[0]["id"] == item_velo["id"]


def test_lister_avec_limit_trop_grand_renvoie_422(client: TestClient) -> None:
    response = client.get("/items", params={"limit": 500})

    assert response.status_code == 422


# GET /items/{id}


def test_lire_item_existant_renvoie_200(client: TestClient, item_velo: dict[str, Any]) -> None:
    response = client.get(f"/items/{item_velo['id']}")

    assert response.status_code == 200
    assert response.json() == item_velo


def test_lire_item_absent_renvoie_404(client: TestClient) -> None:
    response = client.get("/items/999")

    assert response.status_code == 404


# PUT /items/{id}


def test_remplacer_item_efface_la_description(
    client: TestClient, item_velo: dict[str, Any]
) -> None:
    # Given : le vélo a une description, le nouveau corps n'en a pas
    item_id = item_velo["id"]

    # When
    response = client.put(f"/items/{item_id}", json={"titre": "Vélo de route", "tarif_jour": 12})

    # Then : le titre change et la description disparaît, à la relecture aussi
    assert response.status_code == 200
    assert response.json()["titre"] == "Vélo de route"
    relecture = client.get(f"/items/{item_id}").json()
    assert relecture["titre"] == "Vélo de route"
    assert relecture["description"] is None


def test_remplacer_item_absent_renvoie_404(client: TestClient) -> None:
    corps = {"titre": "Vélo de route", "tarif_jour": 12}

    response = client.put("/items/999", json=corps)

    assert response.status_code == 404


# PATCH /items/{id}


def test_modifier_un_champ_laisse_les_autres_inchanges(
    client: TestClient, item_velo: dict[str, Any]
) -> None:
    # Given
    item_id = item_velo["id"]

    # When : on n'envoie que le titre
    response = client.patch(f"/items/{item_id}", json={"titre": "Vélo de route"})

    # Then : le titre change, la description reste, à la relecture aussi
    assert response.status_code == 200
    relecture = client.get(f"/items/{item_id}").json()
    assert relecture["titre"] == "Vélo de route"
    assert relecture["description"] == "Trois vitesses"


def test_modifier_item_absent_renvoie_404(client: TestClient) -> None:
    response = client.patch("/items/999", json={"titre": "Vélo de route"})

    assert response.status_code == 404


# DELETE /items/{id}


def test_supprimer_item_renvoie_204_puis_404_a_la_lecture(
    client: TestClient, item_velo: dict[str, Any]
) -> None:
    # Given
    item_id = item_velo["id"]

    # When
    suppression = client.delete(f"/items/{item_id}")

    # Then
    assert suppression.status_code == 204
    assert client.get(f"/items/{item_id}").status_code == 404


def test_supprimer_item_absent_renvoie_404(client: TestClient) -> None:
    response = client.delete("/items/999")

    assert response.status_code == 404
