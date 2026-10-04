# Séance 1 : notes

Les questions reprennent mot pour mot l'énoncé du TP (`seances/seance-1-api/tp/README.md`).

## Étape 0 

`curl http://localhost:8000/health` renvoie `{"status":"ok"}` :
`http://localhost:8000/docs` s'ouvre dans votre navigateur :
modifiez le message de `/health`, sauvegardez, et rappelez la route sans reconstruire l'image : le changement est pris en compte : **oui, vérifié.**

Prenez 2 minutes pour comprendre pourquoi (le `volumes:` monte votre dossier `app/` local dans le conteneur, donc le code du conteneur est votre code ; le `--reload` d'uvicorn détecte la modification et redémarre le serveur) :
**sans volume, il faut rebuild à chaque fois et sans -reload, le serveur lancé devrait etre redémarré à chgaque modification**

## Étape 1


`GET /items/42`, code attendu ? corps ? : **200, `{"item_id":42}`**

`GET /items/abc`, code attendu ? corps ? : **422, `{"detail":[{"type":"int_parsing","loc":["path","item_id"],"msg":"Input should be a valid integer, unable to parse string as an integer","input":"abc"}]}` valeur refusée car pas convertible en int**

`GET /items/-1`, code attendu ? corps ? : **200, `{"item_id":-1}` (`int` accepte les négatifs : rien n'interdit un identifiant négatif)**


 
 Corrigez avec `Path`. Appelez à nouveau `GET /items/-1` : **après `Path(ge=1)`, 422, `{"detail":[{"type":"greater_than_equal","loc":["path","item_id"],"msg":"Input should be greater than or equal to 1","input":"-1","ctx":{"ge":1}}]}`**

Regardez aussi `/docs` : la contrainte y apparaît : **oui, `minimum: 1` sur le paramètre `item_id` (vérifié dans `/openapi.json`)**

## Étape 2 
`curl "http://localhost:8000/items"` : **200, `{"skip":0,"limit":20,"q":null,"disponible":null}` (valeurs par défaut, paramètres optionnels à `null`)**

`curl "http://localhost:8000/items?limit=5&q=velo"` : **200, `{"skip":0,"limit":5,"q":"velo","disponible":null}`**

`curl "http://localhost:8000/items?limit=500"` (attendu : 422) : **422, `{"detail":[{"type":"less_than_equal","loc":["query","limit"],"msg":"Input should be less than or equal to 100","input":"500","ctx":{"le":100}}]}`**

`curl "http://localhost:8000/items?disponible=oui"` (que se passe-t-il ?) : **422, `bool_parsing` : « Input should be a valid boolean, unable to interpret input ». `oui` n'est pas accepté : FastAPI ne reconnaît que les valeurs anglaises (`true`, `false`, `1`, `0`, `yes`, `no`, `on`, `off`).**

Testez `disponible=peut-etre` pour voir l'erreur : **422, même erreur `bool_parsing`, `"input":"peut-etre"`**

## Étape 3 

Créez un item valide → vérifiez le code `201` et le corps renvoyé : **201, `{"id":1,"titre":"Velo de ville","description":null,"tarif_jour":5.5,"disponible":true}`**

Créez un item avec `"titre": "ab"` → lisez attentivement le `422` : **422, `string_too_short`, `loc: ["body","titre"]`, « String should have at least 3 characters »**

Créez un item avec `"tarif_jour": 0` → même chose : **422, `greater_than`, `loc: ["body","tarif_jour"]`, « Input should be greater than 0 »**

Créez un item avec un champ en trop, `"couleur": "rouge"` → que se passe-t-il ? : **201, l'item est créé et `couleur` est ignorée silencieusement (absente du corps renvoyé)**


Essayez `extra="forbid"` et gardez-le : **422, `extra_forbidden`, `loc: ["body","couleur"]`. Le champ inconnu est maintenant refusé au lieu d'être ignoré : un client qui se trompe de nom de champ est averti.**

## Étape 4

Vérifiez chacun des cas d'erreur, pas seulement les cas nominaux :

`GET /items/{item_id}` (404 si l'item n'existe pas) : **200 avec l'item si présent et 404, `{"detail":"Item 999 introuvable"}` si absent**

`PUT /items/{item_id}` (404 si absent) : **200 avec l'item remplacé (même `id`) et 404, `{"detail":"Item 999 introuvable"}` si absent ou bien 422 `missing` sur `tarif_jour` si le corps est incomplet (schéma `ItemCreate`)**

`PATCH /items/{item_id}` (404 si absent) : **200, seul le champ envoyé change (`{"titre":"Velo de route"}` garde `description: "bleu"`) ; 404, `{"detail":"Item 999 introuvable"}` si absent**

`DELETE /items/{item_id}` (204, aucun corps de réponse ; 404 si absent) : **204 sans corps pour un item existant ; 404, `{"detail":"Item 999 introuvable"}` si absent ; un `GET` ensuite renvoie bien 404**

Comprenez bien `exclude_unset=True` : **Pydantic se souvient de quels champs le client a été rentrées exclude_unset=True ne garde que ceux-là**


## Étape 5 

Vérifiez que toutes vos routes fonctionnent encore : **oui : `/health` 200, `POST` 201, `GET` liste 200, `GET /1` 200, `GET /-1` 422, `GET /999` 404, `PUT` 200, `PATCH` 200, `DELETE` 204 puis 404, champ en trop 422**

Vérifiez que `/docs` les regroupe désormais sous le tag `items` : **oui : les 6 routes `/items` ont le tag `items` dans `/openapi.json`, `/health` garde le tag `monitoring`**

## Étape 6 : Faire produire une ressource par Copilot

Notez la validation croisée « `date_fin > date_debut` » : elle ne s'exprime pas avec un simple `Field`. Regardez comment l'agent s'en sort : **un `model_validator(mode="after")`, comme l'exemple du prof (422, `loc: ["body"]`), sans `if` dans le router.**

Lisez le plan avant d'accepter : **lu avant le code, puis corrigé (chevauchement, dates passées, nom `RESERVATIONS_DB`).**

La review se remplit dans `reviews/REVIEW.md` (tableau de 8 points de contrôle) : **faite.**
