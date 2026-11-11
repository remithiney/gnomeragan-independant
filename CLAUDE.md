# Gnomeragan Indépendant — addon WoW Forever

Addon de la guilde **Gnomeragan Indépendant** (PvP sauvage, RP, francophone) pour **WoW Forever**
(Classic+ de Blizzard, sorti en novembre 2026). Deux développeurs, chacun avec son propre Claude.
Le dépôt est notre seule mémoire commune : toute décision durable va dans `docs/`.

## Le jeu et l'API
- `## Interface: 16001`. **API moderne** (pas celle de Classic Era) avec les **restrictions de Midnight** :
  valeurs secrètes, pas de journal de combat, communications d'addon verrouillées en instance.
- Pas de doc officielle. Référence : https://github.com/zmarotrix/ForeverAPI (API observée en jeu).
  **Obligatoire avant d'utiliser un événement ou une fonction** : vérifier son statut dans
  `docs/events.md` ou `docs/systems/*.md` de ce dépôt (✅ existe, ⛔ absent de Forever). Copie locale :
  `git clone --depth 1 https://github.com/zmarotrix/ForeverAPI /tmp/ForeverAPI` puis grep.
  Exemple : `MINIMAP_PING` est ⛔ ; la position des pings en jeu est protégée (seul `CHAT_MSG_PING` dit qui a pingé).
  Non confirmé là-bas → à vérifier en jeu ; protéger par `if X then` / `pcall`. `/boussole diag` liste les événements refusés.
- Toujours tester `issecretvalue(v)` **avant** de comparer une valeur venant du jeu (comparer un secret = erreur Lua).
- `UnitPosition` : seulement soi et le groupe, jamais en instance / BG. Les monstres n'ont pas de position.

## Structure
- `GnomeraganIndependant/` : l'addon (c'est ce dossier qui est déployé dans `Interface/AddOns`).
  - `Core.lua` : espace de noms `GI`, base sauvegardée, événements, registre de modules.
  - Un fichier (ou un dossier) **par module**, chargé dans l'ordre du `.toc`. Un module ne touche que son propre code.
- `scripts/` : `deploy.sh` (copie vers WoW), `check.sh` (luacheck + stylua + test de fumée).
- `tests/smoke.lua` : charge l'addon hors jeu avec une API imitée. L'addon met l'API en `local` au chargement :
  pour changer un comportement en cours de test, modifier les variables du faux jeu, pas les fonctions.
- `docs/DECISIONS.md` : journal des décisions. `docs/idees/` : idées et cahiers des charges (pas du code).

## Règles de code (addon léger, petites configs)
- Aucune variable globale sauf : `GnomeraganIndependantDB`, `SLASH_*`, `BINDING_*`, fonctions de raccourcis.
  Tout passe par la table d'addon (`local _, GI = ...`).
- Événements plutôt que scrutation. Un `OnUpdate` doit être limité en fréquence et ne tourner que si le cadre est visible.
- Pas de création de tables, de chaînes ou de closures dans les chemins chauds (OnUpdate, événements fréquents).
- Mettre en `local` les fonctions de l'API utilisées souvent. Créer l'interface à la première ouverture, pas au chargement.
- Pas de bibliothèque externe sans décision dans `docs/DECISIONS.md`.
- Textes affichés en français, centralisés par module. Code et identifiants en anglais, commentaires en français.
- Formatage : `stylua` (tabulations). Avant un commit : `scripts/check.sh` doit passer.

## Sécurité (messages entre joueurs)
- Tout message d'addon reçu est **non fiable** : valider le format, les types, les bornes et l'expéditeur.
- Jamais `loadstring`, `RunScript` ou exécution de contenu reçu. Taille et fréquence des envois limitées.
- Rien d'automatique en /dire, /crier, canaux publics ou chuchotements en masse : l'addon propose, le joueur valide.

## Git et collaboration
- `main` est toujours jouable. On ne pousse jamais directement dessus : branche + pull request relue par l'autre.
- Branches : `feat/<sujet>`, `fix/<sujet>`, `docs/<sujet>`, `proto/<sujet>` (prototype jetable, jamais fusionné).
- Commits courts en français, préfixés : `feat:`, `fix:`, `perf:`, `refactor:`, `docs:`, `chore:`.
- Versions SemVer ; la version du `.toc` ne change qu'au moment d'une release.
- Partir d'un `main` à jour (`git pull`) avant chaque branche ; petites PR, un sujet par PR.

## Économie de tokens (pour Claude)
- Lire seulement les fichiers du module concerné ; chercher avec Grep avant d'ouvrir un gros fichier.
- Ne pas relire un fichier qu'on vient de modifier. Ne pas réexpliquer le code dans les réponses.
- Une tâche = une session ; l'utilisateur fait `/clear` entre deux sujets. Les décisions vont dans `docs/`, pas dans le chat.

## Environnement
- Développement dans WSL (instance `wow-addon`, Ubuntu 24.04), dépôt dans `~/projets/gnomeragan-independant`.
- Déployer pour tester en jeu : `scripts/deploy.sh` puis `/reload` dans WoW. Dossier cible : variable `WOW_ADDONS`.
- Depuis le Git Bash de Windows, préfixer les appels `wsl.exe` par `MSYS_NO_PATHCONV=1` (sinon les chemins sont réécrits).
- Écrire un fichier depuis Windows (`\\wsl.localhost\...`) retire le droit d'exécution : `chmod +x scripts/*.sh`.
- Préférences personnelles : `CLAUDE.local.md` (non versionné).
