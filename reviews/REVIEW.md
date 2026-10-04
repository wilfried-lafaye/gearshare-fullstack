# Review : ressource `reservations` (séance 1)

Agent utilisé : Claude Code, et non GitHub Copilot (choix assumé). Journal complet : `prompts/seance-1.md`. Chaque point a été vérifié à la main avec `curl` ou `grep`.

| Point de contrôle | OK / KO | Ce que j'ai corrigé |
|---|---|---|
| Les codes de statut correspondent à la spec (201, 404, 409) | OK | Testés : 201, 404, 409 à la double annulation. Écart : l'agent ajoute un 409 (chevauchement) et un 422 (date passée), absents de la spec. Je les ai demandés après son plan. |
| `response_model` présent sur les 4 routes | OK | Rien à corriger. |
| La validation `date_fin > date_debut` est bien dans le schéma Pydantic | OK | `model_validator(mode="after")`, comme l'exemple du prof. 422, `loc: ["body"]`. |
| Le router n'accède pas au stockage de `items` | OK | `grep` vide. Dictionnaire propre : `RESERVATIONS_DB`. |
| Pas d'`async def` sans `await` | OK | `grep` vide : routes en `def`. |
| Aucune dépendance ajoutée dans `requirements.txt` (ou justifiée) | OK | Identique à celui du prof. |
| Les routes littérales sont déclarées avant les routes paramétrées | OK | Sans objet : aucune route littérale. |
| Le code renvoie une réponse cohérente pour `POST /reservations/999/annuler` | OK | 404, `{"detail":"Réservation 999 introuvable"}`. |

## Écarts à la spec

- **409 sur chevauchement** : deux réservations actives du même item ne peuvent pas se recouvrir (fin exclusive, annulées ignorées). Testé : 201 puis 409.
- **422 sur date de début passée** : `field_validator("date_debut")`.

## Limites connues

- `item_id` n'est jamais vérifié (la spec interdit d'accéder à `items`) : à traiter avec la base de données.
- `date.today()` : un test avec des dates fixes dans le passé reçoit un 422.
- Stockage en mémoire : données perdues au redémarrage (séance 3).
- Bug connu sur `items` (code du prof, hors `reservations`) : `PATCH /items/{id}` avec `{"titre": null}` écrit `None` dans le stockage, puis la réponse échoue en 500 (`ItemRead` attend une chaîne). Testé avec `curl`. Non corrigé : à traiter avec les contraintes de la base de données.

## Retour d'expérience

Lire le plan avant le code m'a permis d'imposer mes choix en amont. Claude Code à la place de Copilot est un écart à l'énoncé, signalé ici.
