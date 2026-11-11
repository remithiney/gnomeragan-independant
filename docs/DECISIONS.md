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

## 2026-11-11 — La boussole n'affiche pas les ennemis
La boussole ne pointe que vers soi et les membres du groupe, jamais vers une cible hostile.
Pourquoi : testé en jeu, `UnitPosition("target")` sur un joueur de la faction adverse renvoie
`nil nil nil 0`. Blizzard cache la position des unités hors groupe (`C_Map.GetPlayerMapPosition` :
« Only works for the player and party members »). Un addon ne peut pas contourner ce blocage.
Piste à la place : un guildeux signale un ennemi et l'addon diffuse la position de ce guildeux.

## 2026-11-12 — Vecteurs du jeu : lire `.x` / `.y`, jamais `:GetXY()`
Dans Forever, `C_Map.GetUserWaypoint().position` est une table simple sans méthodes : `GetXY()`
a causé plus de 1000 erreurs pendant un wipe. On lit les champs `.x` / `.y` (ils existent aussi
sur les vrais `Vector2D`) en vérifiant leur type. Le code appelé dans un `OnUpdate` qui dépend
d'une API mal connue passe par `pcall` et ne signale son erreur qu'une fois.
Les erreurs Lua du jeu sont écrites dans `Logs/General.log` (`[E][Lua]`), même sans BugSack.

## 2026-11-12 — Noms de personnages : « Prénom Nom », jamais découpés
Dans WoW Forever, un personnage a un prénom et un nom de famille, sans royaume : les serveurs sont
des rulesets. On ne découpe donc jamais un nom (pas de `-Royaume` à retirer, pas d'`Ambiguate`).
Pour reconnaître un joueur (soi, un membre du groupe), on compare des **GUID** ; le nom exact sert
seulement à l'affichage et à `C_PartyInfo.InviteUnit`. Repli par nom exact si le GUID manque.
À confirmer en jeu : ce que renvoient `UnitName`, `GetGuildRosterInfo` (17e valeur = GUID ?) et
l'expéditeur des messages de chat.

## 2026-11-12 — Réglages sauvegardés bornés au démarrage, appel aux armes limité aux places libres
Les SavedVariables (et les réglages repris de DAoCCompass) sont traités comme non fiables : au démarrage,
chaque réglage de mauvais type revient à sa valeur par défaut, chaque nombre est ramené dans la plage
de son curseur, et un `point` mal formé est oublié. Sinon `fps = 0` figeait la bande et `scale = 0`
ou un point invalide faisait planter le module à chaque connexion.
« Sonner l'appel » n'invite que dans la limite des places libres (groupe de 5, raid de 40, moins les
invitations envoyées sans réponse depuis moins de 60 s). L'addon ne passe jamais en raid tout seul :
il l'indique et le joueur décide.
