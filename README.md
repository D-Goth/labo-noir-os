# Lab'O Noir OS

Un poste de travail Debian sobre et soigné pour les développeurs et la cyberdéfense.

Lab'O Noir s'installe par-dessus une **Debian 13 avec KDE Plasma 6** ou une **Kubuntu 26.04** : un bureau épuré façon elementary OS,
avec verre dépoli et thèmes à la carte, les outils de défense sur le système, les outils offensifs isolés
dans une Kali en conteneur ou en machine virtuelle, une messagerie sans inscription, et aucun recueil de
date de naissance ni de télémétrie.

![Arsenal : carte réseau Nmap](docs/img/arsenal-nmap.png)

## Ce que contient Lab'O Noir

| Module | Contenu |
|---|---|
| `base` | Outils de base, Flathub, commandes `labnoir-*` |
| `confidentialite` | Pas de popularity-contest, retours d'usage de KDE coupés, garde-fou contre le service de vérification d'âge, `labnoir-privacy` |
| `bureau` | Plasma 6 : barre fine en haut, dock flottant, verre dépoli, thème Lab'O Noir, Konsole translucide, écran de connexion assorti, Studio de thèmes |
| `dev` | Compilateurs, Python, Node, Go, Rust (rustup), Podman, Distrobox, Kate, Neovim, VSCodium |
| `defense` | Wireshark, Suricata, YARA, ClamAV, rkhunter, Lynis, AIDE, auditd, Sleuth Kit, Volatility 3… |
| `redteam` | Kali officielle isolée dans un conteneur Distrobox, `labnoir-redteam` |
| `virtualisation` | QEMU/KVM et virt-manager pour les VM d'attaque et d'analyse de logiciels malveillants |
| `messagerie` | SimpleX Chat (aucun identifiant) et Briar (Tor, Wi-Fi, Bluetooth) |
| `arsenal` | Lanceur graphique des outils, sur le système ou dans la Kali, avec des vues graphiques des résultats (carte réseau Nmap, rapport Lynis, détections ClamAV et YARA) |
| `orbit` | Orbit Pixel : modules circulaires pour le bureau |
| `durcissement` | Pare-feu, noyau durci, mises à jour de sécurité automatiques, SSH |

## Installation

1. Installe **Debian 13** en choisissant l'environnement **KDE Plasma** (ou ajoute-le ensuite avec `sudo apt install task-kde-desktop`), ou bien **Kubuntu 26.04**.
2. Depuis ta session :

```bash
git clone https://github.com/D-Goth/labo-noir-os.git
cd labo-noir-os
./install.sh --list              # les modules
sudo ./install.sh --dry-run      # ce qui serait fait, sans rien toucher
sudo ./install.sh                # installation complète
```

3. Ferme puis rouvre ta session : le bureau Lab'O Noir s'applique à la première connexion.

Options utiles : `--only bureau,arsenal`, `--skip redteam,virtualisation`, `--user NOM`, `--yes`.
Le journal est dans `/var/log/labnoir-install.log`. Un paquet absent des dépôts est signalé dans le bilan sans arrêter l'installation.

## Au quotidien

| Commande | Rôle |
|---|---|
| `labnoir-studio` | Studio de thèmes : accent, flou, boutons, fond, avec aperçu (aussi dans le menu) |
| `labnoir-theme list` | Thèmes disponibles (`labonoir`, `nuit-bleue`, `givre`) |
| `labnoir-theme apply nuit-bleue` | Change d'accent, de flou, de boutons de fenêtres, et Orbit Pixel suit ; ton fond d'écran est gardé (`--fond` pour prendre celui du thème) |
| `labnoir-redteam init` | Crée la Kali isolée (top 10 des outils ; `--full` ou `--large` pour plus) |
| `labnoir-redteam enter` | Terminal dans la Kali |
| `labnoir-redteam vm` | Vérifie la virtualisation et ouvre virt-manager |
| `labnoir-privacy` | Vérifie : pas de date de naissance, pas de service d'âge, pas de télémétrie |
| `arsenal` | Lanceur graphique des outils |

Un thème est un petit fichier TOML. Le plus simple est le **Studio Lab'O Noir** : choisis un thème,
change l'accent, le flou ou les boutons, regarde l'aperçu, puis **Enregistrer et appliquer**.
Tes thèmes vont dans `~/.local/share/labnoir/themes/` et s'exportent pour être partagés.

![Studio Lab'O Noir](docs/img/studio.png)

## Confidentialité

Lab'O Noir ne demande jamais de date de naissance et n'installe aucun service de vérification d'âge :
un réglage D-Bus empêche même un tel service (`org.freedesktop.AgeVerification1`) de s'enregistrer.
`labnoir-privacy` le vérifie à tout moment. Ces lois visent pour l'instant certains États américains et le
Brésil ; si tu redistribues Lab'O Noir, vérifie les règles qui s'appliquent là où il sera utilisé.

## Documentation

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) : organisation du dépôt et choix techniques
- [docs/NOMENCLATURE.md](docs/NOMENCLATURE.md) : chaque code de référence du code, avec sa définition
- [ROADMAP.md](ROADMAP.md) : la suite (ISO, studio de thèmes, client bitchat…)

## Licence

Le code est sous **GPL-3.0** ([LICENSE](LICENSE)). Le nom Lab'O Noir, les logos, le fond d'écran et la
charte graphique restent réservés : voir [BRANDING.md](BRANDING.md).
