# Orbit Pixel : port Plasma 6 (v0.1)

Port du pack Rainmeter « D-Goth - Orbit Pixel » en widget Plasma 6 (QML), écrit pour Kubuntu 26.04 / Plasma 6.6 / Wayland. **Pas encore testé sur un vrai Plasma** : dis-moi ce qui s'affiche de travers et on ajuste.

Un seul widget, `Orbit Pixel`, que tu ajoutes autant de fois que nécessaire. Dans sa configuration (clic droit, « Configurer ») tu choisis le **module** : horloge H/M/S, calendrier, CPU, RAM, GPU, disque, réseau, volume, énergie, système/IP. Couleur d'accent (même palette que ton Control Center), transparence du fond et police se règlent par instance.

## Installation

```bash
unzip orbit-pixel-plasma-v0.1.zip && cd orbitpixel
./install.sh --font ~/chemin/vers/LED_Dot-Matrix.ttf   # la police est copiée dans le widget
plasmawindowed fr.blacklab.orbitpixel                   # test en fenêtre, sans toucher au bureau
./place-layout.sh 1920                                  # pose tous les modules sur le bureau
```

Si le widget n'apparaît pas : `systemctl --user restart plasma-plasmashell.service`.

Sans `--font`, le widget utilise le nom de police indiqué dans sa config (par défaut « LED Dot-Matrix », s'il est installé sur le système).

## Dépendances

- `wpctl` (PipeWire) pour le module Volume
- `curl` pour l'IP publique (module Système, 1 requête par heure vers api.ipify.org)
- `python3-numpy` pour Média et Micro (analyse du son) : `sudo apt install python3-numpy`
- `playerctl` (optionnel) pour le titre, l'artiste et la progression dans Média
- GPU : lit `gpu_busy_percent` (AMD) ou `nvidia-smi` ; sinon affiche `--%`

## Pas encore porté

Monolith (le pack du PC fixe) n'est pas encore porté.

## Média et Micro (v0.2)

- **Média** : les anneaux réagissent au son qui sort (haut-parleurs ou oreillette). Variante `media-alt` : départ en haut, sensibilité 70.
- **Micro** : VU-mètre sur ce que capte le micro ; clic = couper/réactiver le micro (« MICRO MUTE » en accent). Variante `micro-alt` : graves à l'extérieur.
- Un petit démon (`contents/scripts/orbit-audio.py`) analyse le flux et sert uniquement des niveaux sur `127.0.0.1` (port aléatoire, jeton secret, aucun accès depuis une page web). Rien n'est enregistré. Il s'arrête seul 20 s après le dernier widget audio.
- Le module Micro écoute le micro en continu : Plasma peut donc afficher l'indicateur « micro utilisé » tant qu'il est sur le bureau.
- Après mise à jour : `./install.sh` puis `systemctl --user restart plasma-plasmashell.service`.

## Control Center et Météo (v0.3)

- **Control Center** : ajoute le module « Control Center (engrenage) » (ou lance `place-layout.sh`, qui le pose en bas à gauche). Un clic sur l'engrenage ouvre le panneau : `+` ajoute un module sur le bureau, `✕` le retire, un module se déplace ensuite en mode édition du bureau. On y ajoute aussi des disques (point de montage) et on y choisit la couleur d'accent, la transparence et la ville.
- Les réglages visuels sont partagés par tous les modules via `~/.config/orbitpixelrc` ; chaque widget peut s'en détacher (config du widget, case « Suivre le Control Center »).
- **Météo** : données [Open-Meteo](https://open-meteo.com) (sans clé API, CC BY 4.0, usage non commercial). La ville se cherche dans le Control Center ; ses coordonnées ne sont stockées que dans ton `orbitpixelrc` local, jamais dans le pack.
- Plasma n'écrit la liste des widgets qu'avec quelques secondes de retard : après un ajout ou un retrait, le Control Center garde l'état affiché ~12 s avant de relire la réalité.
- Dépendance : `kwriteconfig6` (présent avec Plasma 6).
