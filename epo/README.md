# EPO — l'histoire de la guerre en jeu vidéo

EPO est un jeu éducatif pour PC, en français, pour les 15-20 ans. On y traverse
**10 époques**, de l'Antiquité à la guerre moderne, et on y apprend comment une
guerre se prépare, s'organise et se décide : ingénierie, politique, stratégie,
champ de bataille.

Le jeu parle de **stratégie et d'organisation**. Il ne montre pas de crimes de
guerre. Les armes sont présentées comme dans un musée : histoire, rôle des
pièces, principe de fonctionnement, démontage d'entretien. Il n'y a **aucun plan
de fabrication**.

Le jeu est fait avec [Godot 4.7.2](https://godotengine.org), un moteur gratuit et
libre. Tout le projet est en texte (scripts GDScript et fichiers JSON), sans
modèle 3D ni image à télécharger : les modèles, les sons et la musique sont
générés par le code.

## Ce qu'on trouve dans le jeu

Chaque époque propose 6 missions, notées sur 3 étoiles. Elles sont toutes
accessibles dès le début.

| Mission | Contenu |
|---|---|
| Histoire et livres | 5 chapitres, des anecdotes, le livre de l'époque (Sun Tzu, Machiavel, Clausewitz, de Gaulle…) |
| Atelier d'armes | Une arme ou une machine en 3D : vue éclatée, fonctionnement animé, démontage chronométré ou inspection. S'y ajoute le bureau d'études, où l'on conçoit une arme à partir d'un cahier des charges. |
| Bataille 3D | Comme dans TABS : on place ses troupes, puis la bataille se joue toute seule. 14 batailles historiques, un bac à sable et des codes de défi à partager. |
| L'État en guerre | Deux façons de jouer : le conseil de guerre (cartes à la Reigns) ou l'économie de guerre (tableau de bord avec impôts, emprunts, budget et ligne de front). |
| Quotidien du soldat | Une semaine dans la peau d'un soldat : paquetage, corvées, imprévus. |
| Quiz final | 10 questions sur l'époque. |

On trouve aussi :

- des profils (plusieurs joueurs sur le même PC) ;
- des grades, de « Soldat de 2e classe » à « Maréchal de France » ;
- la solde, la monnaie du jeu ;
- des caisses de cartes-anecdotes (jeu de hasard avec raretés) ;
- la caserne, pour personnaliser son soldat (mode historique ou mode libre) ;
- une vidéothèque YouTube ;
- un codex (unités, grades, livres, glossaire).

## Jouer

### Avec la version Windows toute prête

À chaque modification du dossier `epo/`, GitHub fabrique automatiquement le jeu
(workflow `.github/workflows/epo.yml`). Pour le récupérer :

1. Ouvre l'onglet **Actions** du dépôt sur GitHub.
2. Choisis le dernier passage réussi de **EPO (jeu Godot)**.
3. Télécharge l'artefact **EPO-windows** en bas de la page.
4. Décompresse le fichier et lance `EPO.exe`.

Windows peut afficher un avertissement SmartScreen, car le jeu n'est pas signé :
clique sur « Informations complémentaires », puis « Exécuter quand même ».

### Depuis le code source, avec Godot

1. Télécharge **Godot 4.7.2 (version standard, pas .NET)** sur
   [godotengine.org](https://godotengine.org/download). Il n'y a rien à installer :
   c'est un simple exécutable.
2. Lance Godot, clique sur **Importer**, puis choisis le fichier `epo/project.godot`.
3. Appuie sur **F5** pour jouer.

### Commandes

| Où | Commande |
|---|---|
| Partout | souris (clic, survol pour les explications) |
| Bataille, placement | clic gauche pour placer (on peut glisser pour « peindre » une ligne), clic droit court pour retirer |
| Bataille, caméra | ZQSD / WASD ou flèches pour bouger, E ou Espace pour monter, C ou Ctrl pour descendre, Maj pour aller plus vite, molette pour zoomer, clic droit maintenu pour tourner, clic molette maintenu pour glisser |
| Bataille, combat | clic sur une unité pour la suivre (Échap pour la lâcher), P pour la pause |
| Atelier | glisser pour tourner l'arme, molette pour zoomer, clic sur les pièces |

## Organisation du projet

```
epo/
├── project.godot        réglages du projet (fenêtre, autoloads, physique Jolt)
├── export_presets.cfg   export Windows (inclut les fichiers JSON)
├── core/                services globaux (autoloads)
│   ├── content.gd       charge tout le contenu JSON
│   ├── game.gd          profils, sauvegardes, grades, solde, étoiles
│   ├── ui.gd            thème, couleurs et composants d'interface
│   ├── nav.gd           navigation entre les écrans
│   └── sfx.gd           sons et musique
├── screens/             écrans 2D (titre, carte, époque, histoire, quiz, État,
│                        économie de guerre, quotidien, caisses, caserne, vidéos…)
├── battle/              bataille 3D (terrain, unités, projectiles, ragdolls, effets)
├── workshop/            atelier 3D et bureau d'études
├── common/              modèles 3D procéduraux (soldats, chevaux, véhicules), caméra
├── data/                TOUT le contenu du jeu, en JSON (voir ci-dessous)
├── assets/              polices (licence OFL) et sons générés
├── tests/               lanceur de tests et captures d'écran
└── tools/               scripts utilitaires (sons, vérification, mise en forme)
```

## Ajouter ou modifier du contenu

Il n'y a pas de panneau d'administration : tout le contenu se trouve dans
`epo/data/`. Il suffit de modifier les fichiers JSON (avec n'importe quel éditeur
de texte) et de relancer le jeu.

| Fichier | Contenu |
|---|---|
| `eras.json` | les 10 époques : nom, période, couleur, terrain, texte d'intro, soldat de l'époque |
| `history/e01.json` … `e10.json` | chapitres d'histoire, anecdotes, livre de l'époque, autres livres, quiz |
| `units.json` | les unités de bataille : coût, points de vie, vitesse, attaque, apparence |
| `battles.json` | les batailles : budget, unités autorisées, armée ennemie, terrain, couverts, textes |
| `weapons/*.json` | l'atelier : pièces 3D, vue éclatée, animation, ordre de démontage, fiche |
| `briefs.json` | le bureau d'études : cahiers des charges et choix techniques |
| `state.json` | les cartes du conseil de guerre, par époque |
| `economy.json` | l'économie de guerre : lignes de budget, impôts, contexte et événements par époque |
| `daily.json` | le quotidien du soldat : objets du paquetage, activités, événements |
| `cards.json` | les cartes-anecdotes des caisses (rareté : commune, rare, épique, légendaire) |
| `videos.json` | la vidéothèque : identifiant YouTube, titre, chaîne, durée, époque |

Quelques exemples :

- **Ajouter une vidéo** : copier un bloc de `videos.json` et changer `id`
  (ce qui suit `watch?v=` dans l'adresse YouTube), `title`, `channel`, `duration`
  et `era`.
- **Ajouter une carte-anecdote** : copier un bloc de `cards.json` et lui donner un
  `id` unique.
- **Ajouter une arme à l'atelier** : copier un fichier de `weapons/`. L'ordre des
  fichiers donne l'ordre d'affichage. Chaque pièce est faite de formes simples
  (`box`, `cyl`, `cone`, `sphere`, `torus`, `prism`) avec une position, une
  rotation en degrés et une matière (`metal`, `wood`, `brass`, `glass`, `paint`…).

Pour remettre un JSON en forme : `python3 tools/fmt_json.py data/cards.json`.

## Tests

Tout se lance depuis le dossier `epo/`, avec l'exécutable Godot (`godot`) :

```bash
godot --headless --path . --import                         # première fois : import
GODOT=godot bash tools/check_scripts.sh                    # vérifie tous les scripts
godot --headless --path . res://tests/runner.tscn -- smoke # ouvre tous les écrans
godot --headless --fixed-fps 60 --path . res://tests/runner.tscn -- balance all 3
                                                           # simule les batailles (équilibrage)
godot --path . res://tests/runner.tscn -- shot hub capture.png
                                                           # capture d'écran d'un écran
```

## Comptes Steam, publication et hébergement

- **Aujourd'hui** : les profils sont enregistrés sur le PC du joueur (dossier
  utilisateur de Godot). Il n'y a pas besoin de serveur et c'est gratuit.
- **Gratuit** : le jeu peut être publié tel quel sur [itch.io](https://itch.io).
  On envoie `EPO.exe` et la page est gratuite.
- **Steam** : il faut un compte Steamworks et payer les frais *Steam Direct*
  (100 $ par jeu, remboursés après 1 000 $ de ventes). On ajoute ensuite le
  module [GodotSteam](https://godotsteam.com) pour les comptes Steam, les succès
  et la sauvegarde dans le cloud.

## Licences

- **Code et contenu** : écrits pour EPO.
- **Polices** : Black Ops One, Oswald et Lora (SIL Open Font License), et DejaVu
  Sans. Voir `assets/fonts/LICENCES.txt`.
- **Sons et musiques** : générés par `tools/gen_audio.py`.
- **Vidéos** : ce sont de simples liens vers YouTube. Elles appartiennent à leurs
  chaînes respectives et s'ouvrent dans le navigateur.
