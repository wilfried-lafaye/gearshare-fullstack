 Agent utilisé : Claude Code
 
Je démarre le projet GearShare pour le module E5 (Fullstack data application) : une plateforme de prêt de matériel entre étudiants.

Je suis seul sur le projet, le projet indique qu'il faut être deux, mais le prof a indiqué à l'oral qu'il est possible de le faire tout seul. Le cours et les énoncés sont disponibles en lecture seule sur [GitHub (Madwaks/fullstack-data-application-2026)](https://github.com/Madwaks/fullstack-data-application-2026). Tu vas donc copier ce repo dans un dossier externe et on va lire ce repo de l'extérieur pour construire le notre.
Mon travail sera rendu sur mon propre dépôt.

Contraintes strictes du prof :

Je dois savoir expliquer chaque ligne de code générée par IA.
Traçabilité obligatoire : specs, reviews et journal des prompts par séance (prompts bruts, résultats, corrections et explications).
Historique Git propre : au moins un commit par séance, pas de commit massif de fin de projet, aucun secret commité (.env.example requis).

L'usage de l'IA et les retours d'expérience font partie intégrante de la notation.

Ton rôle : agis en tuteur, pas en exécutant. Aide-moi à comprendre, relis mon code et pointe mes erreurs. N'écris pas le code à ma place sans demande explicite, et demande toujours confirmation avant une commande destructive (push, reset, suppression).

Pour commencer :

Lis le fichier PRESENTATION.md sur le dépôt du prof pour vérifier que rien d'essentiel ne manque.
Propose-moi une arborescence claire pour mon dépôt de rendu, sans rien créer pour l'instant.
Même ce fichier prompt et son résultat doit paraitre dans la tracabilité exigé par le prof.
Garde ces consignes en mémoire. 

---

## Résultat (réponse de l'agent)

Agent utilisé : Claude Code (le prof impose GitHub Copilot ; un second LLM est autorisé, cf. `OUTILS.md`).

1. **Lecture de `PRESENTATION.md`** (dépôt du prof cloné hors du projet, dans `~/Documents/GitHub/fullstack-cours`). Points relevés :
   - `projet/grille-evaluation.md`, `projet/` et `templates/` sont cités mais absents du clone ; les séances 4 à 7 aussi.
   - Le module parle de groupes de 2 : le travail en solo doit être documenté (accord oral du prof).
   - Copilot est l'agent imposé : le retour d'expérience doit préciser quel outil a fait quoi.
   - Trois points qui pèsent lourd : démarrage fonctionnel (`git clone`, `cp .env.example .env`, `docker compose up`), historique Git lisible, retour d'expérience honnête.
2. **Arborescence proposée** (monorepo) : `README.md`, `.gitignore`, `.env.example`, `docker-compose.yml`, `AGENTS.md`, `backend/`, `frontend/`, `tests/`, `specs/`, `reviews/`, `prompts/`, `seances/`.
3. **Actions exécutées à ma demande explicite**, une par une :
   - création de l'arborescence (dossiers avec `.gitkeep`, `.gitignore`, `.env.example` avec valeurs factices, `README.md`, fichiers vides `docker-compose.yml` et `AGENTS.md`) ;
   - `git init -b main` et ajout du remote `origin` ;
   - création du dépôt GitHub public `wilfried-lafaye/gearshare-fullstack` avec `gh repo create` ;
   - déplacement de ce prompt dans `prompts/seance-0.md`.
   Aucun commit ni push n'a été fait par l'agent.

## Corrections

- **Erreur de l'agent (mémoire périmée)** : la mémoire de l'agent indiquait que le dépôt du prof était déjà cloné et que le dépôt de rendu était déjà un clone Git. Vérification faite : ni l'un ni l'autre n'existait. L'agent a recloné le dépôt du prof et signalé que le dossier n'était pas un dépôt Git.
- **Dépôt distant introuvable** : après `git init`, `git ls-remote` répondait `Repository not found`. Plutôt que de deviner, l'agent a demandé comment procéder ; j'ai demandé la création du dépôt public.
- **Arborescence** : conservée telle quelle. Un doublon possible entre `seances/` (livrables de TP) et `reviews/` (relectures de code) a été signalé ; à surveiller.
- **Ce que j'ai décidé moi-même** : valider l'arborescence, créer le dépôt en public, déplacer le prompt dans `prompts/`, et faire moi-même le premier commit.

## Pourquoi

- Dépôt du prof cloné hors du projet : il reste en lecture seule et ne pollue pas mon rendu.
- `.env` ignoré, `.env.example` commité avec des valeurs factices : règle « aucun secret commité ».
- `.gitkeep` dans les dossiers vides : Git ne versionne pas les dossiers vides, et la structure doit être visible dès le premier commit.
- Pas de commit par l'agent : l'historique Git doit refléter mon travail (un commit par séance), et je dois savoir expliquer chaque action.
- Dépôt créé sans README ni `.gitignore` côté GitHub : évite un conflit avec mon premier commit local.
