# Gnomeragan Indépendant

Addon de la guilde **Gnomeragan Indépendant** pour WoW Forever : PvP sauvage, RP, francophone.

> Projet en préparation : la base de code est neuve, les idées sont en cours de tri dans `docs/idees/`.

## Installer (joueurs)
À venir : les versions publiées seront disponibles dans les *Releases* de ce dépôt.

## Développer
1. Cloner le dépôt (sous WSL ou Windows).
2. Tester en jeu :
   - WSL : `scripts/deploy.sh` copie l'addon dans `Interface/AddOns` (cible modifiable avec `WOW_ADDONS`).
   - Windows : copier ou lier le dossier `GnomeraganIndependant/` dans `Interface\AddOns`.
3. Dans WoW : `/reload`, puis `/gi`.
4. Avant un commit : `scripts/check.sh` (luacheck et stylua).

Méthode de travail et règles : voir [`CLAUDE.md`](CLAUDE.md) et [`docs/DECISIONS.md`](docs/DECISIONS.md).
