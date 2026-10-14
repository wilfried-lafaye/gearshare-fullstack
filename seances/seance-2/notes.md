# Séance 2 : notes

L'énoncé du TP ne pose pas de questions : ces notes suivent ses quatre objectifs, puis la couverture et la mutation (cours §7 et §8).

## Objectif 1 : installer pytest dans le conteneur

Dépendances ajoutées : **`pytest` (lance les tests), `pytest-cov` (couverture), `httpx` (requis par `TestClient`).**

Lancement : **`docker compose run --rm api pytest -v`**. L'image a dû être reconstruite (`docker compose build`) : `pip install` ne s'exécute qu'au build.

## Objectif 2 : tester avec `TestClient`

Pourquoi aucun serveur n'est nécessaire : **`TestClient` appelle l'application en mémoire, dans le processus du test, sans réseau ni port.**

## Objectif 3 : les fixtures

Compteurs `_next_id` supprimés : **l'id se déduit du dictionnaire (`max + 1`), donc un seul état à vider entre deux tests.**

Fixtures : **`storage` vide les dictionnaires de l'API avant et après chaque test, `client` en dépend (état vide garanti), `item_velo` fournit un item déjà créé.**

## Objectif 4 : tests de contrat

Les vérifications manuelles de la séance 1 sont automatisées : **27 tests, un par `raise HTTPException`, un cas nominal par route, plus les validations des schémas.**

## Couverture

**100 %** (`--cov-fail-under=70` respecté). Une première mesure à 95 % montrait trois lignes non testées, ensuite couvertes. La couverture mesure l'exécution, pas la vérification : d'où la mutation.

## Mutation à la main

On casse une règle dans `app/`, on vérifie que les tests deviennent rouges, puis on restaure le code.

| # | Mutation | Résultat |
|---|---|---|
| 1 | 409 de la double annulation commenté | test de la double annulation rouge |
| 2 | `<` remplacé par `>` dans le chevauchement | tests du chevauchement rouges |
| 3 | `exclude_unset=True` retiré du `PATCH` | test du `PATCH` sur un champ rouge |
| 4 | `del FAKE_DB[item_id]` désactivé | test du `DELETE` puis `GET` rouge |

Les quatre mutations sont détectées, et le code d'origine est restauré.

Ce que j'ai retenu : **un test qui reste vert après une mutation ne protège pas la règle, quelle que soit la couverture. Il faut vérifier l'effet visible par le client (le `GET` après un `DELETE`).**

## Limites connues

- Après un `DELETE` de l'id le plus élevé, cet id est réattribué (`max + 1`) : acceptable en mémoire, réglé par la base en séance 3.
- Bug `PATCH` avec `{"titre": null}` sur `items` : non corrigé, non testé (voir `reviews/REVIEW.md`).
