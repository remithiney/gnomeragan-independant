# Journal des décisions

Une entrée par décision durable : date, décision, pourquoi. On n'efface pas, on ajoute une nouvelle entrée qui remplace.

## 2026-11-11 — Un seul addon, découpé en modules
Un addon `GnomeraganIndependant` avec un cœur (`Core.lua`) et des modules (boussole, guilde, RP…).
Pourquoi : une seule installation pour les membres, réglages communs, fichiers courts pour limiter
les conflits git et les tokens lus par Claude.

## 2026-11-11 — Repartir d'une base neuve
Les prototypes précédents (`DAoCCompass`, `GnomerganLibre` v0.5.1) servent de référence, pas de base.
La structure, la sécurité et le fonctionnement sont repensés avant de développer.

## 2026-11-11 — Nom et graphie
Nom affiché : « Gnomeragan Indépendant ». Identifiants techniques sans accent ni espace :
dossier et addon `GnomeraganIndependant`, dépôt `gnomeragan-independant`, base `GnomeraganIndependantDB`,
commande `/gi`.

## 2026-11-11 — Pas de bibliothèque externe pour l'instant
On en ajoute une seulement si elle évite beaucoup de code, avec une entrée ici.

## 2026-11-12 — Sécurité du dépôt entre contributeurs
Le dépôt est public et chacun travaille avec son Claude. Lancer `scripts/check.sh` sur une branche
exécute son code (`tests/smoke.lua`, `.luacheckrc`), et `CLAUDE.md` / `.claude/` donnent des consignes
au Claude de l'autre. Ces fichiers sont donc relus ligne à ligne, signalés dans la PR, et on lit le
diff avant de lancer les vérifications. Pas de `.claude/settings.json` versionné sans décision ici.
