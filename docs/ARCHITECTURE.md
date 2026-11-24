# Architecture de Lab'O Noir OS

Lab'O Noir est une surcouche : il part d'une Debian 13 + Plasma 6 standard (ou d'une Kubuntu 26.04) et la transforme par des modules
indépendants. Les mêmes modules serviront à fabriquer l'ISO (voir la [ROADMAP](../ROADMAP.md)).

## Dépôt

```
install.sh                 installateur : options, sélection, exécution des modules, bilan
lib/common.sh              fonctions communes : journal, simulation, apt, Flathub, compte cible, réglages
modules/NN-nom.sh          un module = MODULE_DESC + module_run ; l'ordre suit le numéro
packages/*.list            listes de paquets Debian, une par module (vérifiées par la CI)
bin/                       commandes installées : labnoir-theme, labnoir-privacy, labnoir-redteam, labnoir-first-login
themes/*.toml              thèmes du bureau
desktop/                   look-and-feel Plasma, fond d'écran, icône, profil Konsole
config/                    fichiers déposés dans /etc : D-Bus, xdg, SDDM, sysctl, apt, SSH, autostart
arsenal/                   lanceur graphique PyQt6 et son catalogue tools.json
widgets/orbitpixel/        Orbit Pixel (projet à part, inclus tel quel)
scripts/nomenclature.py    vérifie la nomenclature et génère docs/NOMENCLATURE.md
tools/check-packages.sh    vérifie les listes de paquets sur la distribution courante
```

## Installation sur le système

| Emplacement | Contenu |
|---|---|
| `/opt/labnoir` | outils, thèmes, ressources du bureau, Arsenal, script de disposition d'Orbit Pixel |
| `/usr/local/bin` | liens vers `labnoir-theme`, `labnoir-privacy`, `labnoir-redteam`, `labnoir-first-login`, `arsenal` |
| `/etc/labnoir/labnoir.conf` | version, compte, thème par défaut, `ORBIT_LAYOUT`, `PRIVACY_GUARD` |
| `/etc/xdg/*` | réglages par défaut de KDE pour tout nouveau compte |
| `/var/log/labnoir-install.log` | journal de la dernière installation (lisible par root seulement) |

## Modules

Chaque module tourne dans un sous-shell avec `set -e` : une erreur arrête le module, pas l'installation.
Le paquet manquant d'une liste est signalé puis sauté, pour qu'un nom changé dans Debian ne bloque rien.
`--dry-run` affiche chaque commande sans l'exécuter.

## Bureau

Le bureau est un **look-and-feel Plasma** (`desktop/lookandfeel/fr.blacklab.labonoir`) : réglages par
défaut (couleurs, icônes Papirus, décorations Breeze) et disposition des panneaux écrite en JavaScript
Plasma : barre fine en haut avec menu global et horloge centrée, dock flottant centré qui s'efface
devant les fenêtres. KWin active le flou (verre dépoli) et la décoration sans bordure, avec les boutons
réduire, agrandir et fermer en haut à droite (modifiable par thème : `classique`, `elementary`, `macos`).

Comme Plasma ne lit la disposition qu'à l'application du look-and-feel, `labnoir-first-login` (lancé
automatiquement à la première connexion de chaque compte) applique le look-and-feel, le thème choisi et,
si `ORBIT_LAYOUT=1`, la disposition d'Orbit Pixel calculée sur la largeur réelle de l'écran.

## Thèmes

`labnoir-theme` génère à partir d'un fichier TOML :

- le jeu de couleurs KDE (palette sombre ou claire, accent pour la sélection, les liens et le focus) ;
- le thème de Konsole (opacité et flou) ;
- les réglages de KWin (force du flou, bruit, boutons des fenêtres) ;
- l'accent et la transparence d'Orbit Pixel (`~/.config/orbitpixelrc`) ;
- le fond d'écran.

Plasma n'applique pas un jeu de couleurs qui porte déjà le nom du jeu actif : l'outil alterne entre
`LabONoir` et `LabONoirB` pour forcer le rechargement.

## Red team

Les outils offensifs ne sont pas installés sur le système : ils vivent dans la **Kali officielle**,
dans un conteneur Distrobox (Podman, sans root). Le système reste une Debian stable ; la Kali se met à
jour depuis ses propres dépôts et se recrée en une commande. Pour les logiciels malveillants, ce sont de
vraies VM (QEMU/KVM) avec instantanés : l'isolation par conteneur ne suffit pas.

Arsenal choisit l'environnement de chaque outil : système, Kali, ou automatique (système si l'outil y
est installé). La commande est construite argument par argument, sans shell : une saisie ne peut pas
injecter de commande. Les outils interactifs ou qui demandent `sudo` s'ouvrent dans Konsole.

## Confidentialité

- `config/dbus/labnoir-age.conf` interdit à `org.freedesktop.AgeVerification1` (nom proposé en 2026 pour
  un service de vérification d'âge) de s'enregistrer sur le bus système et d'y recevoir des messages.
- Les fiches utilisateurs de systemd peuvent contenir un champ `birthDate` (facultatif, vide par défaut) :
  `labnoir-privacy` le signale, `labnoir-privacy clear` le retire des fiches `/etc/userdb`.
- Les retours d'usage de KDE sont désactivés par défaut et popularity-contest est retiré.

Ces mécanismes évoluent : `labnoir-privacy` cherche le mot « AgeVerification » dans les services D-Bus et
les portails installés pour détecter une future implémentation, quel que soit son nom exact.

## Nomenclature

Comme dans les autres projets Black-Lab, le code ne contient pas de commentaires explicatifs mais des
codes de référence (`# [INS-04]`), définis dans `docs/nomenclature.toml`. `scripts/nomenclature.py`
génère `docs/NOMENCLATURE.md` avec un extrait de chaque élément ; la CI vérifie qu'elle est à jour.

## Vérifications

La CI (`.github/workflows/ci.yml`) lance ShellCheck, compile le Python, vérifie la nomenclature,
fait une simulation complète de l'installateur et vérifie toutes les listes de paquets dans des
conteneurs `debian:trixie` et `ubuntu:26.04`.

Non vérifié automatiquement : le rendu réel du bureau (look-and-feel, disposition, flou) demande une
session Plasma 6 ; à tester dans une VM Debian 13 avant chaque version.
