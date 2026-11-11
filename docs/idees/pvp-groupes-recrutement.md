# PvP, groupes, recrutement — séances de questions-réponses

Domaine de remithiney. Le RP et le social sont le domaine de l'autre développeur (fichier à part).
Légende de faisabilité : ✅ possible · ⚠️ à vérifier en jeu · ❌ impossible avec l'API.

## Séance 1 — 2026-11-11 : priorités

### PvP sauvage — tout est voulu, par ordre de fiabilité
1. ✅ **Coordination en groupe** : boussole, appel de cible, ralliement, « besoin d'aide » avec position.
2. ✅/⚠️ **Alerte ennemis proches** : joueurs Horde repérés (plaques de nom, cible, survol), partagés à la guilde.
3. ⚠️ **Primes / avis de recherche** : dépend de la détection des morts, sans journal de combat.
4. ⚠️ **Stats et classement PvP** : même dépendance.

À vérifier en jeu : quelles sources permettent de savoir qu'un membre est mort et qui l'a tué
(événements de mort, compteurs d'honneur, messages système) — sinon primes et stats seront déclaratives.

### Sécurité (exigence forte)
Un utilisateur mal intentionné peut modifier son addon : **aucun message reçu n'est fiable**.
- L'**expéditeur** d'un message d'addon est garanti par Blizzard ; le contenu, non.
- Points, classement, primes officielles : seuls comptent les messages d'un expéditeur dont le rang
  d'officier est vérifié dans la liste de guilde **locale**.
- Validation stricte de chaque champ, jamais d'exécution de contenu reçu, erreurs ignorées sans planter.
- Limite d'envoi par expéditeur, liste d'ignorés, recoupement des alertes.
- Aucun envoi public automatique : l'addon propose, le joueur clique.

### Serveur : non
Budget nul, et de toute façon **un addon n'a pas accès à Internet**. Données partagées uniquement en jeu
(messages d'addon) et dans les fichiers de réglages de chacun. GitHub : code, issues, versions publiées.

### Groupes : « Appel aux armes »
Grouper vite les membres de la guilde **dans la même zone** (habillage RP : appel aux armes).
Esquisse : un membre lance l'appel → message de guilde avec sa zone → les membres de la même zone
voient « Rejoindre » → le lanceur reçoit la liste et invite d'un clic.
⚠️ Vérifier si l'invitation en groupe exige un clic (probable) : on prévoit donc un bouton « Inviter ».

### Recrutement : toute l'Alliance, par tous
- Tout membre peut repérer et signaler un joueur de l'Alliance sans guilde (cible, survol).
- Liste de candidats partagée ; seuls les officiers invitent (droit du jeu).
- Garde-fous du cahier conservés : un message par personne, délais de relance, liste noire, pas d'envoi en masse.

### Ordre de travail
1. **Boussole** : premier module (portage de DAoCCompass + flèche vers Gnomeregan).
2. Socle de messages sécurisés (préalable à alertes, appel aux armes, recrutement partagé, points).
