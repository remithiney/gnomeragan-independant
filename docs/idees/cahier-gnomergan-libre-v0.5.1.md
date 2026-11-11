# Add-on de guilde « Gnomergan Libre » — idées et cahier des charges

Projet mené avec un ami : un add-on WoW Forever (Classic+) qui fédère les membres de la guilde autour de points, de grades, de RP et d'outils communautaires.

Dernière mise à jour : 10/11/2026 — version de l'add-on : **0.5.1**.

## 1. Cœur : points et grades
- Points par membre selon les actions pour la guilde : PvP sauvage, métiers, dons à la banque, aide aux autres membres.
- 14 grades à thème gnome, sur le modèle du système d'honneur de Classic, avec 14 armoiries originales dans l'esthétique Warcraft (détail en section 11).
- Contrats de la semaine : 3 à 5 objectifs tournants (tuer 50 Hordeux, livrer 20 Tissus de mage, faire un donjon avec un bas niveau).
- Hauts faits de guilde : badges uniques (« Premier 60 », « 100 victimes en PvP sauvage », « Artisan 300 »).
- Saisons de 2 à 3 mois : le classement est remis à zéro, les grades restent à vie.
- Objectif collectif « Reconquête de Gnomeregan » : une jauge commune avec des paliers qui débloquent des récompenses ou des événements.

## 2. PvP sauvage
- Avis de recherche : l'ennemi qui tue un membre est ajouté à une liste de primes, et le venger rapporte des points bonus.
- Carte des combats : zones chaudes où la guilde tue ou se fait tuer.

## 3. Carte interactive
- Positions des membres connectés (seulement ceux qui ont l'add-on, hors donjons et raids), avec filtres (par niveau, par zone).
- Points d'intérêt partagés : spots de farm, mobs rares, filons, points de rendez-vous.
- Bouton « Besoin d'aide » : ping avec la position du joueur.
- Direction visuelle retenue (voir section 12) : marqueurs posés sur la vraie carte de WoW, pas de fond dessiné maison.

## 4. Entraide et économie
- Annuaire des artisans : recettes connues, mises à jour automatiquement, et demandes de fabrication.
- Liste de souhaits et prêts : le membre qui fournit gagne des points.
- Banque de guilde : un perso banquier avec journal des dons si la version n'a pas de banque native.
- Parrainage : vétéran et filleul gagnent des points quand le filleul progresse.

## 5. RP
- Fiche de personnage : titre RP, histoire, traits, statut « en RP » ou « hors RP », visible au survol.
- Chronique de guilde générée automatiquement, dans un ton gnome.
- Proverbe gnome aléatoire affiché à la connexion.

## 6. Automatismes communautaires
- Rencontre d'un gnome : quand on cible ou survole un gnome (UnitRace), l'add-on propose une emote ou une phrase de salut à envoyer d'une touche (bouton qui clignote ou touche dédiée).
- Salut entre membres : deux membres qui se saluent mutuellement (/saluer) gagnent un petit bonus de points une fois par jour.
- Accueil automatique dans le canal de guilde : bienvenue RP pour un nouveau membre, félicitations tous les 10 niveaux ou au métier maximum, salut à la connexion d'un membre (désactivable).
- Anniversaire d'entrée dans la guilde, annoncé dans le canal.
- Rappel discret du tabard de guilde à la connexion ou en ville.
- Recensement de Gnomeregan : compteur des gnomes rencontrés et liste des gnomes et nains sans guilde croisés récemment.
- Gnome en détresse : alerte si un membre bas niveau meurt ou se fait attaquer près de soi.
- Serment d'entrée : texte RP que le nouveau membre prononce à son arrivée.

## 7. Aide au recrutement (officiers)
- Détection : gnomes et nains sans guilde (UnitRace + GetGuildInfo) au ciblage ou au survol, ajoutés à une liste de candidats.
- Fiche candidat : nom, race, classe, niveau, zone, date de rencontre, statut (contacté / refus / à relancer / recruté).
- Messages préfaits RP, envoyés en chuchotement d'un clic, avec la variable {nom} remplacée automatiquement.
- Garde-fous : un seul message par personne, délai avant relance, liste noire, jamais d'envoi automatique en masse.
- Bouton « Inviter » qui envoie l'invitation de guilde après la réponse positive.
- Les textes définitifs sont dans Textes.lua (voir section 11).

## 8. Macros et petits plus
- Cri de ralliement (touche dédiée) : `/g Pour Gnomeregan ! Libre et mécanique !`
- Salut gnome : `/saluer` + `/dire Que vos engrenages tournent rond !`
- Appel d'aide : `/g [Position] Besoin d'un coup de clé à molette ici !`
- Page 4 « Guilde » sur la MX Creative Console : salut, cri de ralliement, appel d'aide, ouverture de la fenêtre de l'add-on, recrutement et invitation du candidat ciblé.

## 9. Événements
- Calendrier avec inscriptions.
- Mini-jeux : loterie, concours de pêche, course de montures, tournoi de duels.
- Outils officiers : suivi d'activité, inactifs, ajout ou retrait manuel de points.

## 10. Contraintes techniques
- Pas de serveur : synchronisation entre joueurs par le canal invisible de la guilde. Seuls les membres qui ont l'add-on sont visibles ou comptés.
- Triche : les points officiels devront être validés ou signés par les officiers.
- Carte : pas de positions en donjon ou en raid. HereBeDragons pour les marqueurs.
- Règles Blizzard : les messages en /dire, /crier et dans les canaux publics, ainsi que les recherches /qui, demandent un appui de touche ou un clic. L'add-on propose, le joueur valide. Le canal de guilde et les chuchotements sont plus souples, mais pas d'envoi en masse pour éviter les signalements pour spam.
- L'interface de WoW Forever est modernisée (fenêtres à portrait rond, écran des rangs « Overlord » avec liste des rangs, barre de progression et compteurs) : l'add-on s'en inspire.
- Direction artistique voulue : rester dans l'esthétique Warcraft (métal en relief, bleu et or Alliance, parchemin et encre pour la carte), pas de style plat ou « cartoon ».

## 11. Avancement
### V1 codée (v0.1.0, 10/11/2026)
Dossier `GnomerganLibre` (Textes.lua, Core.lua, Rencontres.lua, Interface.lua, Bindings.xml), sans bibliothèque externe, testé dans un environnement simulé (pas encore en jeu).
- Points : niveau +10, PvP sauvage +5 (coup fatal, hors BG, 1×/h par victime), métier +1 (+10 à 75/150/225/300), salut mutuel +2 (1×/jour par membre), accueil +3, recrue +25. Barème dans `GL.Bareme` (Core.lua).
- Classement synchronisé par le canal invisible de guilde (préfixe `GnomLibre`).
- Bouton « Saluer » au ciblage d'un gnome ou d'un nain, recensement, liste de candidats.
- Recrutement : /gl recruter, relancer, presenter, inviter, candidats, refus, oublier (délais : 7 j entre premiers contacts, 1 j avant relance, 3 j entre relances).
- Automatismes : bienvenue RP (un seul membre l'envoie), annonce tous les 10 niveaux, promotions, proverbe à la connexion, /gl cri, /gl sos, /gl serment.
- Raccourcis : saluer, cri, appel à l'aide, fenêtre, recruter, inviter.
- Textes RP définitifs dans Textes.lua : grades, 10 proverbes, saluts gnomes / nains / membres, cris, bienvenue, niveau, promotion, serment, recrutement gnome / nain / relance / présentation.

### v0.2.0 — interface au style Classic (10/11/2026)
- Emblème de grade, barre de progression vers le grade suivant.
- Bouton de minicarte (clic gauche fenêtre, clic droit candidats, glisser pour déplacer).
- Grade dans l'infobulle des membres, emblème devant les messages du canal de guilde.
- Promotion annoncée au centre de l'écran avec le son de montée de niveau.
- Options ajoutées : minicarte, chat, infobulle.

### v0.3.0 — 14 grades (10/11/2026)
1. Apprenti bricoleur (0) · 2. Graisseur d'engrenages (40) · 3. Serreur de boulons (100) · 4. Mécano (180) · 5. Chef mécano (280) · 6. Artificier (400) · 7. Ingénieur (550) · 8. Ingénieur en chef (750) · 9. Inventeur (1000) · 10. Maître inventeur (1300) · 11. Architecte de Gnomeregan (1700) · 12. Maître ingénieur (2200) · 13. Grand Mécaniste (2800) · 14. Haut Bricoleur (3500).

### v0.4.0 — fenêtre façon écran des rangs de WoW Forever (10/11/2026)
- Cadre à portrait rond (modèles PortraitFrameTemplate → ButtonFrameTemplate → BasicFrameTemplate → cadre de dialogue, selon ce que le client propose), onglets en bas.
- Onglet Rang : grand emblème, nom et numéro du rang, barre avec emblème du rang suivant, compteurs « Victoires sauvages » et « Recrues », liste des 14 rangs à droite (actuel surligné, à venir grisés).
- Onglet Classement : 15 membres. Onglet Journal : 15 dernières actions datées + recensement (gnomes, nains, candidats, recrues, saluts, accueils).
- Compteurs par perso (`stats` : pvp, recrues, saluts, accueils). Commandes `/gl rang`, `/gl classement`, `/gl journal`.

### v0.5.0 / v0.5.1 — armoiries de la guilde (10/11/2026)
- 14 armoiries originales (TGA 128×128 dans `Media/`), redessinées en 0.5.1 dans l'esthétique Warcraft : métal en relief (éclairage spéculaire), rivets, contours épais, ombre portée, bleu et or Alliance.
- Rangs 1–3 : roues d'engrenage en fer, anneau de bronze riveté, champ rouge à 1, 2, 3 chevrons d'or. Rang 4 : écu de bronze rouge aux clés croisées. Rangs 5–8 : écus d'acier bleus (engrenage, bombe, marteau et clé, engrenage sur clés d'or). Rangs 9–12 : écus d'or bleus (engrenage étoilé, étoile à rayons, tour de Gnomeregan, engrenage ailé). Rangs 13–14 : écus d'or couronnés à gemmes (le 14 avec rayons et ailes).
- Blason de guilde rond riveté (engrenage d'acier, clés d'or croisées, étoile et gemme) pour le portrait, la minicarte et la liste des add-ons.
- Retour possible aux insignes PvP du jeu via `Textes.lua`. Générateur SVG → TGA en Python (rsvg-convert + Pillow).

## 12. V2 — maquettes validées en principe (rien n'est codé)
Onglets prévus dans la fenêtre : Rang · Classement · **Carte** · **Atelier** · **Officiers** · Journal.

- **Officiers** (visible des officiers seulement) : points à valider (Valider / Refuser) avant qu'ils comptent au classement, liste des membres avec rang, dernière connexion et points, boutons « ± points », « Lancer un contrat », « Inactifs », « Nouvelle saison ». Règle le problème de triche.
- **Atelier** : jauge « Reconquête de Gnomeregan » à paliers, contrats de la semaine avec barres de progression et récompense en points, annuaire des artisans avec bouton « Demander ».
- **Carte** : la première maquette (fond plat) a été jugée moche. Direction retenue : style parchemin et encre façon carte du jeu, médaillons des membres (intérieur = couleur de classe, anneau = métal du rang), balises en forme d'écu bordé d'or (filon, farm) ou de rouge (élite rare), appel à l'aide qui pulse en rouge avec un « ! ». En jeu, ces marqueurs se posent sur la vraie carte de WoW.
- Ordre proposé : Officiers → Atelier → Carte (la plus technique).

## 13. Partage et collaboration
- Le partage direct d'un projet Claude n'existe qu'en Team/Enterprise, au sein d'une même organisation. Avec des comptes personnels, partage via GitHub retenu comme meilleure option.
- Plan : dépôt GitHub `gnomergan-libre` (à créer par Pierre-Arthur), Claude y pousse l'add-on et un README. L'ami clone le dépôt directement dans `Interface\AddOns`, travaille avec son propre Claude, une branche par sujet et des pull requests relues par l'autre.
- Dossier de présentation pour l'ami : page HTML « Dossier Gnomergan Libre » (artifact privé à partager depuis le menu Partager) et fichier autonome `gnomergan-libre-dossier.html` (images intégrées). Contenu : idée, 14 rangs, barème, écrans en jeu, messages RP, commandes, code, maquettes V2, méthode de travail à deux, capture d'inspiration WoW Forever.

## 14. Prochaines étapes
- Tester en jeu : numéro `## Interface:` (`/dump select(4, GetBuildInfo())`), affichage des armoiries, rendu du cadre à portrait et des onglets. Envoyer des captures pour ajuster.
- Créer le dépôt GitHub et y pousser l'add-on.
- Option : copier l'add-on directement dans `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns` via l'ordinateur relié (accès au dossier à accorder).
- V2 : onglet Officiers (validation des points) en premier.
