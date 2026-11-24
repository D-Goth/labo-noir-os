# Nomenclature de Lab'O Noir OS

Le code ne contient pas de commentaires explicatifs : chaque élément important porte un code de référence
(`# [INS-01]` en Bash et en Python, `// [DSK-06]` en JavaScript).
Ce document associe chaque code à sa définition et à un extrait du code d'origine.

Fichier généré par `python3 scripts/nomenclature.py` à partir de `docs/nomenclature.toml` :
ne pas le modifier à la main.

## Règles

- Un code par unité : fonction, module, commande, classe ou bloc de configuration.
- Un nouveau code prend le numéro suivant de son préfixe ; un code n'est jamais réattribué.
  Un élément supprimé garde sa définition dans `nomenclature.toml` avec `retire = true`.
- Seules les directives `# shellcheck` et les lignes `#!` sont admises en plus des codes.
- Orbit Pixel (`widgets/orbitpixel`) est un projet à part et garde ses propres conventions.
- `python3 scripts/nomenclature.py --check` vérifie que chaque code est défini, que chaque définition
  est utilisée, qu'aucun commentaire libre n'est présent et que ce document est à jour.

## Préfixes

| Préfixe | Périmètre | Codes |
|---|---|---|
| [`INS`](#ins) | Installateur principal (install.sh) | 6 |
| [`LIB`](#lib) | Bibliothèque commune des modules (lib/common.sh) | 11 |
| [`BAS`](#bas) | Module base | 1 |
| [`PRV`](#prv) | Confidentialité : module et outil labnoir-privacy | 7 |
| [`DSK`](#dsk) | Bureau : module, look-and-feel Plasma, première connexion | 9 |
| [`THM`](#thm) | Gestionnaire de thèmes labnoir-theme | 10 |
| [`DEV`](#dev) | Module développement | 1 |
| [`DEF`](#def) | Module défense | 1 |
| [`RED`](#red) | Red team : module et outil labnoir-redteam | 5 |
| [`VIR`](#vir) | Module virtualisation | 1 |
| [`MSG`](#msg) | Module messagerie | 1 |
| [`ARS`](#ars) | Arsenal, lanceur graphique des outils | 15 |
| [`ORB`](#orb) | Module Orbit Pixel | 1 |
| [`HRD`](#hrd) | Module durcissement | 5 |
| [`VUE`](#vue) | Vues graphiques d'Arsenal (arsenal/vues.py) | 9 |
| [`OUT`](#out) | Outils du dépôt (vérifications, CI) | 1 |

## INS

Installateur principal (install.sh)

### [INS-01] Démarrage

Repère le dossier du dépôt, charge la bibliothèque commune et prépare les options.

`install.sh` ligne 4

```bash
LABNOIR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LABNOIR_ROOT
# shellcheck source=lib/common.sh
. "$LABNOIR_ROOT/lib/common.sh"

ONLY=()
SKIP=()
ASSUME_YES=0
FORCE=0
```

### [INS-02] Options

Aide et lecture des options : --list, --only, --skip, --user, --dry-run, --yes, --force.

`install.sh` ligne 15

```bash
usage() {
    cat <<EOF
Lab'O Noir OS : installateur

Transforme une Debian 13 ou une Kubuntu 26.04 (KDE Plasma 6) en poste Lab'O Noir.

Usage : sudo ./install.sh [options]

  --list              affiche les modules et quitte
  --only a,b          n'installe que ces modules
  --skip a,b          saute ces modules
  --user NOM          compte à personnaliser (par défaut : celui qui a lancé sudo)
…
```

### [INS-03] Modules

Découverte des modules (modules/NN-nom.sh), identifiant, description, modules facultatifs, sélection et vérification des noms demandés.

`install.sh` ligne 56

```bash
module_id() {
    basename "$1" .sh | sed 's/^[0-9]*-//'
}
```

### [INS-04] Vérifications

Droits root (sauf simulation), système Debian 13 (ou --force), compte à personnaliser, résumé et confirmation.

`install.sh` ligne 110

```bash
[[ $EUID -eq 0 || "$LABNOIR_DRY_RUN" == 1 ]] || die "lance l'installateur avec sudo : sudo ./install.sh"

if ! is_supported; then
    if ((FORCE)); then
        warn "système détecté : $(os_field PRETTY_NAME). Lab'O Noir vise Debian 13 et Kubuntu 26.04 : on continue (--force)."
    elif [[ "$LABNOIR_DRY_RUN" == 1 ]]; then
        warn "système détecté : $(os_field PRETTY_NAME), ni Debian 13 ni Kubuntu 26.04 (simulation seulement)"
    else
        die "Lab'O Noir vise Debian 13 et Kubuntu 26.04 (système détecté : $(os_field PRETTY_NAME)). Relance avec --force pour essayer quand même."
    fi
fi
```

### [INS-05] Exécution

Journal en 600, mise à jour unique de l'index apt, puis chaque module dans un sous-shell avec set -e : l'échec d'un module n'arrête pas les autres.

`install.sh` ligne 141

```bash
if [[ "$LABNOIR_DRY_RUN" != 1 ]]; then
    : >"$LABNOIR_LOG" 2>/dev/null || true
    chmod 600 "$LABNOIR_LOG" 2>/dev/null || true
fi
: >"$LABNOIR_MISSING_FILE"
export LABNOIR_MISSING_FILE
step "préparation"
apt_ready

DONE=()
FAILED=()
for f in "${TODO[@]}"; do
…
```

### [INS-06] Bilan

Modules terminés, en échec, paquets introuvables, emplacement du journal ; code de sortie non nul si un module a échoué.

`install.sh` ligne 169

```bash
printf '\n%s●%s Bilan\n' "$C_ACC" "$C_OFF"
((${#DONE[@]})) && ok "terminés : ${DONE[*]}"
```


## LIB

Bibliothèque commune des modules (lib/common.sh)

### [LIB-01] Chemins et réglages

Dossier du dépôt, préfixe /opt/labnoir, /etc/labnoir, journal, mode simulation, fichier des paquets manquants.

`lib/common.sh` ligne 3

```bash
LABNOIR_ROOT="${LABNOIR_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LABNOIR_PREFIX="${LABNOIR_PREFIX:-/opt/labnoir}"
LABNOIR_ETC="${LABNOIR_ETC:-/etc/labnoir}"
LABNOIR_LOG="${LABNOIR_LOG:-/var/log/labnoir-install.log}"
LABNOIR_DRY_RUN="${LABNOIR_DRY_RUN:-0}"
LABNOIR_MISSING_FILE="${LABNOIR_MISSING_FILE:-/tmp/labnoir-missing.$$}"
```

### [LIB-02] Affichage et journal

Messages étape, info, ok, avertissement et erreur fatale ; couleurs seulement dans un terminal ; tout est copié dans le journal.

`lib/common.sh` ligne 11

```bash
if [[ -t 1 ]]; then
    C_DIM=$'\e[2m' C_OK=$'\e[32m' C_WARN=$'\e[33m' C_ERR=$'\e[31m' C_ACC=$'\e[38;2;255;22;84m' C_OFF=$'\e[0m'
else
    C_DIM="" C_OK="" C_WARN="" C_ERR="" C_ACC="" C_OFF=""
fi

_log() {
    if [[ "$LABNOIR_DRY_RUN" != 1 && -w "$(dirname "$LABNOIR_LOG")" ]]; then
        printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LABNOIR_LOG"
    fi
}
```

### [LIB-03] Exécution d'une commande

Lance la commande et la note dans le journal, ou se contente de l'afficher en simulation.

`lib/common.sh` ligne 30

```bash
run() {
    if [[ "$LABNOIR_DRY_RUN" == 1 ]]; then
        printf '  %s$ %s%s\n' "$C_DIM" "$*" "$C_OFF"
        return 0
    fi
    _log "\$ $*"
    "$@"
}
```

### [LIB-04] Lecture d'une liste de paquets

Lit packages/<nom>.list en ignorant les lignes vides.

`lib/common.sh` ligne 40

```bash
read_list() {
    local file="$LABNOIR_ROOT/packages/$1.list"
    [[ -f "$file" ]] || die "liste de paquets introuvable : $file"
    grep -Ev '^[[:space:]]*($|#)' "$file" | awk '{print $1}'
}
```

### [LIB-05] Installation apt

Mise à jour unique de l'index, tri entre paquets disponibles et absents (signalés et comptés dans le bilan), installation sans paquets recommandés.

`lib/common.sh` ligne 47

```bash
apt_ready() {
    if [[ "${_LABNOIR_APT_UPDATED:-0}" != 1 ]]; then
        run apt-get update -qq || warn "apt-get update a échoué : les paquets seront cherchés dans l'index existant"
        _LABNOIR_APT_UPDATED=1
        export _LABNOIR_APT_UPDATED
    fi
}
```

### [LIB-06] Compte cible

Compte à personnaliser : --user, sinon celui qui a lancé sudo, sinon le premier compte humain ; et son dossier personnel.

`lib/common.sh` ligne 86

```bash
target_user() {
    local u="${LABNOIR_USER:-${SUDO_USER:-}}"
    if [[ -z "$u" || "$u" == root ]]; then
        u="$(awk -F: '$3 >= 1000 && $3 < 60000 && $7 !~ /nologin|false/ {print $1; exit}' /etc/passwd)"
    fi
    printf '%s' "$u"
}
```

### [LIB-07] Commande en tant qu'utilisateur

Lance une commande sous le compte cible avec son bus de session, pour rustup, pipx ou la Kali isolée.

`lib/common.sh` ligne 99

```bash
as_user() {
    local u
    u="$(target_user)"
    [[ -n "$u" ]] || { warn "aucun compte utilisateur trouvé pour : $*"; return 1; }
    local uid
    uid="$(id -u "$u")"
    run sudo -u "$u" -H env XDG_RUNTIME_DIR="/run/user/$uid" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" "$@"
}
```

### [LIB-08] Copie de fichiers

Copie d'un fichier avec droits, d'un dossier, et lien d'un outil dans /usr/local/bin.

`lib/common.sh` ligne 110

```bash
put() {
    local src="$1" dest="$2" mode="${3:-0644}"
    run install -D -m "$mode" "$src" "$dest"
}
```

### [LIB-09] Flatpak

Ajoute Flathub si besoin et installe des applications pour tout le système, sans réinstaller celles déjà présentes.

`lib/common.sh` ligne 126

```bash
flatpak_ready() {
    command -v flatpak >/dev/null 2>&1 || apt_install flatpak
    run flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}
```

### [LIB-10] Système détecté

Lit /etc/os-release et reconnaît les systèmes pris en charge : Debian 13 et Kubuntu 26.04.

`lib/common.sh` ligne 144

```bash
os_field() {
    sed -n "s/^$1=//p" /etc/os-release 2>/dev/null | head -n1 | tr -d '"'
}
```

### [LIB-11] Réglages Lab'O Noir

Écrit et lit les clés de /etc/labnoir/labnoir.conf (version, compte, thème, Orbit Pixel…).

`lib/common.sh` ligne 161

```bash
conf_set() {
    local key="$1" value="$2" file="$LABNOIR_ETC/labnoir.conf"
    run mkdir -p "$LABNOIR_ETC"
    if [[ "$LABNOIR_DRY_RUN" == 1 ]]; then
        info "$file : $key=$value"
        return 0
    fi
    touch "$file"
    if grep -q "^$key=" "$file"; then
        sed -i "s|^$key=.*|$key=$value|" "$file"
    else
        printf '%s=%s\n' "$key" "$value" >>"$file"
…
```


## BAS

Module base

### [BAS-01] Module base

Outils de base, Flathub, copie des outils, thèmes et ressources dans /opt/labnoir, liens des commandes labnoir-*, réglages initiaux.

`modules/10-base.sh` ligne 4

```bash
module_run() {
    apt_install_list base
    flatpak_ready

    run mkdir -p "$LABNOIR_PREFIX" "$LABNOIR_ETC"
    put_dir "$LABNOIR_ROOT/bin" "$LABNOIR_PREFIX/bin"
    put_dir "$LABNOIR_ROOT/themes" "$LABNOIR_PREFIX/themes"
    put_dir "$LABNOIR_ROOT/desktop" "$LABNOIR_PREFIX/desktop"
    run chmod 0755 "$LABNOIR_PREFIX"/bin/*
    local tool
    for tool in labnoir-theme labnoir-privacy labnoir-redteam; do
        link_bin "$tool"
…
```


## PRV

Confidentialité : module et outil labnoir-privacy

### [PRV-01] Module confidentialité

Retire popularity-contest, installe le garde-fou D-Bus contre le service d'âge, désactive par défaut les retours d'usage de KDE, puis lance une vérification.

`modules/20-confidentialite.sh` ligne 4

```bash
module_run() {
    if dpkg -s popularity-contest >/dev/null 2>&1; then
        run apt-get purge -y -q popularity-contest
        ok "popularity-contest retiré"
    fi

    put "$LABNOIR_ROOT/config/dbus/labnoir-age.conf" /etc/dbus-1/system.d/labnoir-age.conf
    ok "service d'âge bloqué sur le bus système (org.freedesktop.AgeVerification1)"

    put "$LABNOIR_ROOT/config/xdg/UserFeedback.conf" /etc/xdg/kde.org/UserFeedback.org.kde.plasmashell.conf
    put "$LABNOIR_ROOT/config/xdg/UserFeedback.conf" /etc/xdg/kde.org/UserFeedback.org.kde.kinfocenter.conf
    put "$LABNOIR_ROOT/config/xdg/UserFeedback.conf" /etc/xdg/kde.org/UserFeedback.org.kde.systemsettings.conf
…
```

### [PRV-02] labnoir-privacy

Outil de vérification de la confidentialité : nom du service d'âge surveillé et emplacement du garde-fou.

`bin/labnoir-privacy` ligne 4

```bash
AGE_NAME="org.freedesktop.AgeVerification1"
POLICY="/etc/dbus-1/system.d/labnoir-age.conf"
status=0

say() { printf '  %s %s\n' "$1" "$2"; }
```

### [PRV-03] Dates de naissance

Cherche un champ birthDate dans les fiches utilisateurs de systemd (userdbctl).

`bin/labnoir-privacy` ligne 11

```bash
check_userdb() {
    if ! command -v userdbctl >/dev/null 2>&1; then
        say "·" "userdb absent : aucune date de naissance stockée par systemd"
        return
    fi
    local found
    found="$(userdbctl user --output=json 2>/dev/null | grep -o '"birthDate"[^,}]*' || true)"
    if [[ -n "$found" ]]; then
        say "!" "date(s) de naissance présentes dans les fiches utilisateurs :"
        printf '      %s\n' "$found"
        say " " "« sudo labnoir-privacy clear » les retire des fiches de /etc/userdb"
        status=1
…
```

### [PRV-04] Service d'âge

Cherche un service ou un portail AgeVerification dans les fichiers D-Bus et xdg-desktop-portal, et vérifie que le garde-fou est en place.

`bin/labnoir-privacy` ligne 29

```bash
check_age_service() {
    local hits
    hits="$(grep -rlis "AgeVerification" /usr/share/dbus-1 /usr/share/xdg-desktop-portal /etc/xdg-desktop-portal 2>/dev/null || true)"
    if [[ -n "$hits" ]]; then
        say "!" "service de vérification d'âge présent :"
        printf '      %s\n' "$hits"
        status=1
    else
        say "✓" "aucun service de vérification d'âge installé"
    fi
    if [[ -f "$POLICY" ]]; then
        say "✓" "garde-fou actif : $AGE_NAME ne peut pas s'enregistrer sur le bus système"
…
```

### [PRV-05] Télémétrie

Vérifie que popularity-contest n'est pas installé.

`bin/labnoir-privacy` ligne 48

```bash
check_telemetry() {
    local unit
    for unit in apport whoopsie; do
        if systemctl is-enabled "$unit.service" >/dev/null 2>&1; then
            say "!" "$unit actif (rapports envoyés à Canonical)"
            status=1
        fi
    done
    if dpkg -s popularity-contest >/dev/null 2>&1; then
        say "!" "popularity-contest installé (statistiques d'usage envoyées à Debian)"
        status=1
    else
…
```

### [PRV-06] Effacement des dates de naissance

Retire le champ birthDate des fiches /etc/userdb (sudo, avec jq).

`bin/labnoir-privacy` ligne 65

```bash
clear_birthdates() {
    [[ $EUID -eq 0 ]] || { echo "à lancer avec sudo" >&2; exit 1; }
    command -v jq >/dev/null 2>&1 || { echo "jq requis : sudo apt install jq" >&2; exit 1; }
    local f n=0
    for f in /etc/userdb/*.user; do
        [[ -f "$f" ]] || continue
        if jq -e 'has("birthDate")' "$f" >/dev/null 2>&1; then
            jq 'del(.birthDate)' "$f" >"$f.tmp" && mv "$f.tmp" "$f"
            say "✓" "retirée de $f"
            n=$((n + 1))
        fi
    done
…
```

### [PRV-07] Télémétrie d'Ubuntu

Sur Kubuntu : coupe apport, whoopsie, ubuntu-report et les actualités publicitaires du MOTD.

`modules/20-confidentialite.sh` ligne 27

```bash
prv_ubuntu() {
    local unit
    for unit in apport.service whoopsie.service; do
        if systemctl list-unit-files "$unit" >/dev/null 2>&1; then
            run systemctl disable --now "$unit" || true
        fi
    done
    if [[ -f /etc/default/apport ]]; then
        run sed -i 's/^enabled=.*/enabled=0/' /etc/default/apport
    fi
    if [[ -f /etc/default/motd-news ]]; then
        run sed -i 's/^ENABLED=.*/ENABLED=0/' /etc/default/motd-news
…
```


## DSK

Bureau : module, look-and-feel Plasma, première connexion

### [DSK-01] Module bureau

Paquets Plasma, look-and-feel Lab'O Noir, fond d'écran, icône, puis réglages par défaut, SDDM et première connexion.

`modules/30-bureau.sh` ligne 7

```bash
module_run() {
    apt_install_list bureau

    put_dir "$LABNOIR_ROOT/desktop/lookandfeel/$LNF_ID" "/usr/share/plasma/look-and-feel/$LNF_ID"
    put "$LABNOIR_ROOT/desktop/wallpapers/labonoir.jpg" "$WALL_DIR/contents/images/1440x900.jpg"
    put "$LABNOIR_ROOT/desktop/wallpapers/metadata.json" "$WALL_DIR/metadata.json"
    put "$LABNOIR_ROOT/desktop/icons/labonoir.png" /usr/share/icons/hicolor/256x256/apps/labonoir.png
    run gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true

    dsk_render_defaults
    dsk_system_defaults
    dsk_sddm
…
```

### [DSK-02] Couleurs par défaut

Génère le jeu de couleurs et le thème du terminal du thème choisi, et installe le profil Konsole.

`modules/30-bureau.sh` ligne 24

```bash
dsk_render_defaults() {
    local theme
    theme="$(conf_get THEME || true)"
    theme="${theme:-labonoir}"
    run "$LABNOIR_PREFIX/bin/labnoir-theme" render colors "$theme" /usr/share/color-schemes/LabONoir.colors
    run "$LABNOIR_PREFIX/bin/labnoir-theme" render konsole "$theme" /usr/share/konsole/LabONoir.colorscheme
    put "$LABNOIR_ROOT/desktop/konsole/LabONoir.profile" /usr/share/konsole/LabONoir.profile
}
```

### [DSK-03] Réglages par défaut du système

kdeglobals, kwinrc (flou, bordures, boutons réduire, agrandir et fermer à droite), konsolerc et plasmarc dans /etc/xdg : ils valent pour tout nouveau compte.

`modules/30-bureau.sh` ligne 34

```bash
dsk_system_defaults() {
    put "$LABNOIR_ROOT/config/xdg/kdeglobals" /etc/xdg/kdeglobals
    put "$LABNOIR_ROOT/config/xdg/kwinrc" /etc/xdg/kwinrc
    put "$LABNOIR_ROOT/config/xdg/konsolerc" /etc/xdg/konsolerc
    put "$LABNOIR_ROOT/config/xdg/plasmarc" /etc/xdg/plasmarc
}
```

### [DSK-04] Écran de connexion

SDDM avec le thème Breeze et le fond Lab'O Noir.

`modules/30-bureau.sh` ligne 42

```bash
dsk_sddm() {
    put "$LABNOIR_ROOT/config/sddm/10-labonoir.conf" /etc/sddm.conf.d/10-labonoir.conf
    if [[ -d /usr/share/sddm/themes/breeze ]]; then
        if [[ "$LABNOIR_DRY_RUN" == 1 ]]; then
            info "/usr/share/sddm/themes/breeze/theme.conf.user : fond Lab'O Noir"
        else
            printf '[General]\nbackground=%s\ntype=image\n' "$WALL_DIR/contents/images/1440x900.jpg" \
                >/usr/share/sddm/themes/breeze/theme.conf.user
        fi
    fi
}
```

### [DSK-05] Première connexion

Installe le lanceur automatique et remet à zéro le marqueur du compte cible pour réappliquer le bureau.

`modules/30-bureau.sh` ligne 55

```bash
dsk_first_login() {
    put "$LABNOIR_ROOT/config/autostart/labnoir-first-login.desktop" /etc/xdg/autostart/labnoir-first-login.desktop
    link_bin labnoir-first-login
    local home
    home="$(target_home)"
    if [[ -n "$home" && -f "$home/.config/labnoir/first-login.done" ]]; then
        run rm -f "$home/.config/labnoir/first-login.done"
        info "le bureau de $(target_user) sera réappliqué à sa prochaine connexion"
    fi
}
```

### [DSK-06] Fond d'écran

Image Lab'O Noir sur tous les bureaux de l'activité.

`desktop/lookandfeel/fr.blacklab.labonoir/contents/layouts/org.kde.plasma.desktop-layout.js` ligne 1

```js
var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = "org.kde.image";
    desktopsArray[j].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktopsArray[j].writeConfig("Image", "file:///usr/share/wallpapers/LabONoir/contents/images/1440x900.jpg");
}
```

### [DSK-07] Barre du haut

Barre fine : menu des applications, menu global de l'application active, horloge centrée avec la date, zone de notification.

`desktop/lookandfeel/fr.blacklab.labonoir/contents/layouts/org.kde.plasma.desktop-layout.js` ligne 9

```js
var bar = new Panel;
bar.location = "top";
bar.height = Math.round(gridUnit * 1.6);
bar.floating = false;
var menu = bar.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "labonoir");
bar.addWidget("org.kde.plasma.appmenu");
bar.addWidget("org.kde.plasma.panelspacer");
var clock = bar.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "true");
…
```

### [DSK-08] Dock

Panneau flottant centré, à la taille de son contenu, qui s'efface devant les fenêtres, avec les lanceurs favoris.

`desktop/lookandfeel/fr.blacklab.labonoir/contents/layouts/org.kde.plasma.desktop-layout.js` ligne 28

```js
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.2);
dock.lengthMode = "fit";
dock.alignment = "center";
dock.floating = true;
dock.hiding = "dodgewindows";
var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:org.kde.konsole.desktop",
…
```

### [DSK-09] labnoir-first-login

Une seule fois par compte : applique le look-and-feel avec sa disposition, le thème choisi, puis la disposition Orbit Pixel si elle est activée ; journal dans ~/.config/labnoir.

`bin/labnoir-first-login` ligne 4

```bash
STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/labnoir"
DONE="$STATE_DIR/first-login.done"
CONF="/etc/labnoir/labnoir.conf"
PREFIX="${LABNOIR_PREFIX:-/opt/labnoir}"
LOG="$STATE_DIR/first-login.log"

[[ -f "$DONE" ]] && exit 0
mkdir -p "$STATE_DIR"
exec >>"$LOG" 2>&1
echo "== $(date '+%F %T')"

conf() { [[ -f "$CONF" ]] && sed -n "s|^$1=||p" "$CONF" | tail -n1; }
…
```


## THM

Gestionnaire de thèmes labnoir-theme

### [THM-01] Emplacements

Thèmes et fonds cherchés dans ~/.local/share/labnoir, /opt/labnoir puis le dépôt ; fichier du thème actif.

`bin/labnoir-theme` ligne 12

```python
REPO = Path(__file__).resolve().parent.parent
```

### [THM-02] Boutons des fenêtres

Dispositions classique (réduire, agrandir et fermer à droite, par défaut), elementary (fermer à gauche, agrandir à droite) et macos (tout à gauche).

`bin/labnoir-theme` ligne 22

```python
BUTTONS = {
    "elementary": ("X", "A"),
    "macos": ("XIA", ""),
    "classique": ("M", "IAX"),
}
```

### [THM-03] Thème

Nom, mode sombre ou clair, accent, flou et bruit du verre dépoli, opacité du terminal, boutons, fond d'écran, transparence d'Orbit Pixel.

`bin/labnoir-theme` ligne 30

```python
@dataclass
```

### [THM-04] Chargement d'un thème

Lit le fichier TOML, vérifie l'accent (#RRGGBB), le mode et les boutons, borne les valeurs.

`bin/labnoir-theme` ligne 74

```python
def load(ident):
    path = find_theme(ident)
    if not path:
        raise SystemExit(f"thème introuvable : {ident} (voir « labnoir-theme list »)")
    with open(path, "rb") as f:
        data = tomllib.load(f)
    glass = data.get("verre", {})
    accent = str(data.get("accent", "#FF1654"))
    if not HEX.match(accent):
        raise SystemExit(f"{path} : accent invalide « {accent} » (format #RRGGBB)")
    mode = data.get("mode", "sombre")
    if mode not in ("sombre", "clair"):
…
```

### [THM-05] Outils de couleur

Conversion hexadécimale, mélange de deux couleurs, format KDE et luminance.

`bin/labnoir-theme` ligne 105

```python
def rgb(hexa):
    h = hexa.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))
```

### [THM-06] Jeu de couleurs KDE

Palettes sombre et claire, et génération du fichier .colors avec l'accent (sélection, liens, focus) et un texte de sélection lisible.

`bin/labnoir-theme` ligne 129

```python
PALETTES = {
    "sombre": {
        "window": "#111113", "view": "#0B0B0D", "alt": "#17171A", "button": "#1C1C20",
        "header": "#141417", "tooltip": "#0E0E10", "fg": "#E8E8EC", "inactive": "#8C8C95",
        "positive": "#2BD67B", "neutral": "#F5B33F", "negative": "#E5484D",
    },
    "clair": {
        "window": "#F3F3F6", "view": "#FFFFFF", "alt": "#ECECF0", "button": "#FAFAFC",
        "header": "#EDEDF1", "tooltip": "#FFFFFF", "fg": "#1C1C1F", "inactive": "#6B6B74",
        "positive": "#1E9E5A", "neutral": "#B7791F", "negative": "#D93036",
    },
}
…
```

### [THM-07] Thème du terminal

Couleurs Konsole assorties, accent en rouge ANSI, opacité et flou.

`bin/labnoir-theme` ligne 203

```python
def render_konsole(t):
    dark = t.mode == "sombre"
    bg = "#0B0B0D" if dark else "#FBFBFC"
    fg = "#E8E8EC" if dark else "#1C1C1F"
    base = [
        "#1C1C20" if dark else "#3A3A40", t.accent, "#2BD67B" if dark else "#1E9E5A",
        "#F5B33F" if dark else "#B7791F", "#4F8CFF" if dark else "#2563EB", "#B57BFF" if dark else "#8B3FD9",
        "#3CCFCF" if dark else "#0E8A8A", "#C8C8D0" if dark else "#55555C",
    ]
    lines = [
        "[General]",
        f"Description=Lab'O Noir : {t.name}",
…
```

### [THM-08] Outils KDE

Recherche des outils KDE, lecture et écriture de réglages, écriture atomique de fichiers, compte rendu.

`bin/labnoir-theme` ligne 234

```python
def tool(*names):
    for n in names:
        if shutil.which(n):
            return n
    return None
```

### [THM-09] Application

Couleurs (en alternant deux noms pour forcer Plasma à recharger), icônes, terminal, flou et boutons de KWin, accent et transparence d'Orbit Pixel, mémorisation du thème. Le fond d'écran n'est remplacé qu'avec --fond (première connexion), pour garder celui choisi par l'utilisateur.

`bin/labnoir-theme` ligne 269

```python
def apply(t, with_wallpaper=False):
    print(f"Thème « {t.name} »")
    current = kread("kdeglobals", "General", "ColorScheme")
    scheme = "LabONoirB" if current == "LabONoir" else "LabONoir"
    write(DATA_HOME / "color-schemes" / f"{scheme}.colors", render_colors(t, scheme))
    other = DATA_HOME / "color-schemes" / ("LabONoir.colors" if scheme == "LabONoirB" else "LabONoirB.colors")
    exe = tool("plasma-apply-colorscheme")
    if exe:
        r = subprocess.run([exe, scheme], capture_output=True, text=True)
        report(r.returncode == 0, "couleurs", "accent " + t.accent)
    else:
        report(kwrite("kdeglobals", "General", "ColorScheme", scheme), "couleurs", "appliquées à la prochaine session")
…
```

### [THM-10] Commandes

list, current, apply (depuis la session) et render (pour l'installateur).

`bin/labnoir-theme` ligne 323

```python
def main(argv=None):
    ap = argparse.ArgumentParser(prog="labnoir-theme", description="Thèmes du bureau Lab'O Noir")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list", help="liste les thèmes")
    sub.add_parser("current", help="affiche le thème actif")
    a = sub.add_parser("apply", help="applique un thème à la session")
    a.add_argument("theme")
    a.add_argument("--fond", action="store_true", help="remplace aussi le fond d'écran par celui du thème")
    r = sub.add_parser("render", help="écrit un fichier de couleurs (installation)")
    r.add_argument("kind", choices=["colors", "konsole"])
    r.add_argument("theme")
    r.add_argument("output", type=Path)
…
```


## DEV

Module développement

### [DEV-01] Module développement

Compilateurs, Python, Node, Go, rustup, Podman, Distrobox, éditeurs ; chaîne Rust stable pour le compte cible ; VSCodium depuis Flathub.

`modules/40-dev.sh` ligne 4

```bash
module_run() {
    apt_install_list dev
    if command -v rustup >/dev/null 2>&1 && [[ -n "$(target_user)" ]]; then
        as_user rustup default stable || warn "rustup : la chaîne stable s'installera au premier « rustup default stable »"
    fi
    flatpak_install com.vscodium.codium
    ok "poste de dev prêt"
}
```


## DEF

Module défense

### [DEF-01] Module défense

Wireshark sans root pour le compte cible, outils de détection, d'audit et de forensic, Volatility 3 via pipx, mise à jour de ClamAV.

`modules/50-defense.sh` ligne 4

```bash
module_run() {
    if [[ "$LABNOIR_DRY_RUN" != 1 ]]; then
        echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
    fi
    apt_install_list defense

    local u
    u="$(target_user)"
    if [[ -n "$u" ]] && getent group wireshark >/dev/null 2>&1; then
        run usermod -aG wireshark "$u"
        ok "$u peut capturer avec Wireshark sans être root (après reconnexion)"
    fi
…
```


## RED

Red team : module et outil labnoir-redteam

### [RED-01] Module red team

Podman et Distrobox, puis création de la Kali isolée pour le compte cible (LABNOIR_REDTEAM_INIT=0 pour la reporter).

`modules/60-redteam.sh` ligne 4

```bash
module_run() {
    apt_install_list redteam
    local u
    u="$(target_user)"
    [[ -n "$u" ]] || { warn "aucun compte utilisateur : lance « labnoir-redteam init » plus tard"; return 0; }
    if [[ "${LABNOIR_REDTEAM_INIT:-1}" == 1 ]]; then
        info "création du conteneur Kali pour $u (téléchargement de plusieurs centaines de Mo)"
        as_user "$LABNOIR_PREFIX/bin/labnoir-redteam" init || warn "conteneur Kali non créé : relance « labnoir-redteam init »"
    fi
    ok "red team : « labnoir-redteam enter » ouvre la Kali, Arsenal sait y lancer les outils"
}
```

### [RED-02] labnoir-redteam

Nom du conteneur, image Kali officielle et contrôles communs (outil présent, conteneur existant, pas de sudo).

`bin/labnoir-redteam` ligne 4

```bash
BOX="${LABNOIR_KALI_BOX:-kali}"
IMAGE="${LABNOIR_KALI_IMAGE:-docker.io/kalilinux/kali-rolling:latest}"

say() { printf '  %s %s\n' "$1" "$2"; }
```

### [RED-03] Création de la Kali

Crée le conteneur et installe kali-tools-top10, kali-linux-headless (--full) ou kali-linux-large (--large).

`bin/labnoir-redteam` ligne 13

```bash
cmd_init() {
    not_root
    need distrobox distrobox
    need podman podman
    local meta="kali-tools-top10"
    case "${1:-}" in
        --full) meta="kali-linux-headless" ;;
        --large) meta="kali-linux-large" ;;
        "") ;;
        *) say "✗" "option inconnue : $1"; exit 2 ;;
    esac
    if box_exists; then
…
```

### [RED-04] Vérification des VM

KVM, virt-manager, groupe libvirt, lien vers les images Kali officielles, rappel des instantanés, puis ouverture de virt-manager.

`bin/labnoir-redteam` ligne 37

```bash
cmd_vm() {
    local ok=1
    if [[ -e /dev/kvm ]]; then
        say "✓" "KVM disponible"
    else
        say "!" "/dev/kvm absent : active VT-x / AMD-V dans le BIOS"
        ok=0
    fi
    if command -v virt-manager >/dev/null 2>&1; then
        say "✓" "virt-manager installé"
    else
        say "!" "virt-manager absent : sudo ./install.sh --only virtualisation"
…
```

### [RED-05] État

Indique si Distrobox et le conteneur Kali sont présents.

`bin/labnoir-redteam` ligne 67

```bash
cmd_status() {
    if ! command -v distrobox >/dev/null 2>&1; then
        say "!" "distrobox absent"
        return 1
    fi
    if box_exists; then
        say "✓" "conteneur « $BOX » présent"
    else
        say "·" "conteneur « $BOX » absent : « labnoir-redteam init »"
        return 1
    fi
}
…
```


## VIR

Module virtualisation

### [VIR-01] Module virtualisation

QEMU/KVM, libvirt et virt-manager, compte cible ajouté aux groupes libvirt et kvm, avertissement si la virtualisation matérielle est désactivée.

`modules/65-virtualisation.sh` ligne 4

```bash
module_run() {
    apt_install_list virtualisation
    local u
    u="$(target_user)"
    if [[ -n "$u" ]]; then
        run usermod -aG libvirt,kvm "$u"
    fi
    run systemctl enable --now libvirtd.service || true
    if [[ ! -e /dev/kvm ]]; then
        warn "/dev/kvm absent : active la virtualisation (VT-x / AMD-V) dans le BIOS pour des VM rapides"
    fi
    ok "virt-manager prêt (après reconnexion) ; « labnoir-redteam vm » vérifie l'installation"
…
```


## MSG

Module messagerie

### [MSG-01] Module messagerie

SimpleX Chat (aucun identifiant) et Briar (Tor, Wi-Fi, Bluetooth) depuis Flathub.

`modules/70-messagerie.sh` ligne 4

```bash
module_run() {
    flatpak_install chat.simplex.simplex org.briarproject.Briar
    ok "SimpleX (aucun identifiant) et Briar (Tor, Wi-Fi, Bluetooth) installés"
}
```


## ARS

Arsenal, lanceur graphique des outils

### [ARS-01] Module Arsenal

PyQt6, copie d'Arsenal dans /opt/labnoir, commande arsenal et entrée du menu.

`modules/80-arsenal.sh` ligne 4

```bash
module_run() {
    apt_install_list arsenal
    put_dir "$LABNOIR_ROOT/arsenal" "$LABNOIR_PREFIX/arsenal"
    run chmod 0755 "$LABNOIR_PREFIX/arsenal/arsenal.py"
    run ln -sfn "$LABNOIR_PREFIX/arsenal/arsenal.py" /usr/local/bin/arsenal
    put "$LABNOIR_ROOT/config/applications/labnoir-arsenal.desktop" /usr/share/applications/labnoir-arsenal.desktop
    ok "Arsenal : menu des applications ou commande « arsenal »"
}
```

### [ARS-02] Chemins

Fichiers d'Arsenal, nom du conteneur Kali, emplacements des thèmes, libellés des environnements.

`arsenal/arsenal.py` ligne 22

```python
HERE = Path(__file__).resolve().parent
```

### [ARS-03] Catalogue d'outils

Lit tools.json (catégories, outils, paramètres).

`arsenal/arsenal.py` ligne 33

```python
def load_tools():
    with open(TOOLS, encoding="utf-8") as f:
        data = json.load(f)
    return data.get("categories", [])
```

### [ARS-04] Accent du thème

Couleur d'accent du thème Lab'O Noir actif, appliquée à la feuille de style.

`arsenal/arsenal.py` ligne 40

```python
def theme_accent():
    try:
        ident = (CONFIG_HOME / "labnoir" / "theme").read_text(encoding="utf-8").strip()
    except OSError:
        ident = "labonoir"
    for d in THEME_DIRS:
        p = d / f"{ident}.toml"
        if p.is_file():
            try:
                with open(p, "rb") as f:
                    return tomllib.load(f).get("accent", "#FF1654")
            except (OSError, tomllib.TOMLDecodeError):
…
```

### [ARS-05] Environnements

Présence de Distrobox et de la Kali isolée ; pour chaque outil : système, Kali ou automatique (système si l'outil y est installé), disponibilité et raison.

`arsenal/arsenal.py` ligne 57

```python
class Runners:
    def __init__(self):
        self.refresh()

    def refresh(self):
        self.distrobox = shutil.which("distrobox") is not None
        self.kali = False
        if self.distrobox:
            try:
                out = subprocess.run(["distrobox", "list", "--no-color"], capture_output=True, text=True,
                                     timeout=10).stdout
                self.kali = any(line.split("|")[1].strip() == BOX for line in out.splitlines()[1:]
…
```

### [ARS-06] Construction de la commande

Arguments dans l'ordre des paramètres (case, choix, texte avec option, préfixe ou position), champs obligatoires, ~ développé ; options de rapport de la vue juste après le programme ; élévation de la seule commande (pkexec sur le système, sudo dans un terminal ou dans la Kali) quand l'outil ou une option choisie l'exige ; passage par la Kali. Aucun shell : une saisie reste un seul argument.

`arsenal/arsenal.py` ligne 90

```python
def build_args(tool, values):
    args = []
    for p in tool.get("params", []):
        v = values.get(p["id"])
        if p["type"] == "flag":
            if v:
                args += p["args"]
        elif p["type"] == "choice":
            opts = p["options"]
            idx = v if isinstance(v, int) and 0 <= v < len(opts) else p.get("default", 0)
            args += opts[idx]["args"]
        else:
…
```

### [ARS-07] Terminal

Konsole (fenêtre gardée ouverte) ou terminal par défaut pour les outils interactifs ou qui demandent sudo.

`arsenal/arsenal.py` ligne 155

```python
def terminal_command(cmd):
    if shutil.which("konsole"):
        return ["konsole", "--hold", "-e", *cmd]
    if shutil.which("x-terminal-emulator"):
        return ["x-terminal-emulator", "-e", *cmd]
    return None
```

### [ARS-08] Formulaire

Champs générés depuis les paramètres de l'outil, valeurs par défaut, mise à jour de l'aperçu à chaque saisie.

`arsenal/arsenal.py` ligne 164

```python
class ParamForm(QWidget):
    def __init__(self, on_change):
        super().__init__()
        self.on_change = on_change
        self.layout_ = QFormLayout(self)
        self.layout_.setContentsMargins(0, 0, 0, 0)
        self.layout_.setHorizontalSpacing(16)
        self.layout_.setVerticalSpacing(10)
        self.fields = {}

    def build(self, tool):
        while self.layout_.rowCount():
…
```

### [ARS-09] Fenêtre principale

Recherche, liste des outils (grisés s'ils sont indisponibles), état de la Kali, fiche de l'outil, aperçu de la commande, boutons et sortie.

`arsenal/arsenal.py` ligne 212

```python
class Arsenal(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Arsenal")
        self.resize(1180, 760)
        if ICON.exists():
            self.setWindowIcon(QIcon(str(ICON)))
        self.categories = load_tools()
        self.runners = Runners()
        self.tool = None
        self.running_tool = None
        self.running_admin = False
…
```

### [ARS-10] Choix d'un outil

Affiche la fiche, l'environnement, l'avertissement éventuel et le formulaire ; aperçu de la commande exacte.

`arsenal/arsenal.py` ligne 374

```python
def select(self, item, _prev=None):
    tool = item.data(0, Qt.ItemDataRole.UserRole) if item else None
    if not tool:
        return
    self.tool = tool
    runner, ok, why = self.runners.resolve(tool)
    self.name.setText(tool["name"])
    self.desc.setText(tool["description"])
    self.badge.setText(RUNNER_LABEL[runner] + (" · terminal" if tool.get("terminal") else ""))
    self.badge.show()
    self.warning.setText(why)
    self.warning.setVisible(bool(why))
…
```

### [ARS-11] Exécution

Prépare le rapport de la vue, lance l'outil dans un terminal ou avec QProcess (sortie en direct gardée pour la vue, code de retour). Arrêt propre puis forcé après 3 s ; pour une commande administrateur, l'arrêt passe lui aussi par pkexec.

`arsenal/arsenal.py` ligne 439

```python
def run(self):
    if not self.tool or self.proc:
        return
    runner, ok, why = self.runners.resolve(self.tool)
    if not ok:
        self.status.setText(why)
        return
    vue = self.tool.get("vue") or {}
    self.report = vues.scratch(vue["fichier"]) if vue.get("fichier") else None
    try:
        admin = self.admin.isChecked()
        if admin and runner == "host" and not self.tool.get("terminal") and not shutil.which("pkexec"):
…
```

### [ARS-12] Lancement

Application Qt, style, police et feuille de style à l'accent du thème.

`arsenal/arsenal.py` ligne 536

```python
def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Arsenal")
    app.setDesktopFileName("labnoir-arsenal")
    app.setStyle("Fusion")
    if STYLE.exists():
        app.setStyleSheet(STYLE.read_text(encoding="utf-8").replace("#FF1654", theme_accent()))
    app.setFont(QFont("Inter", 10))
    w = Arsenal()
    w.show()
    return app.exec()
```

### [ARS-13] Onglet Vue

Crée la vue graphique de l'outil choisi à côté de l'onglet Sortie, ou la retire s'il n'en a pas.

`arsenal/arsenal.py` ligne 396

```python
def set_view(self, tool):
    if self.view is not None:
        self.tabs.removeTab(1)
        self.view.deleteLater()
        self.view = None
    vue = tool.get("vue")
    if vue:
        self.view = vues.make_view(vue["type"])
        self.tabs.addTab(self.view, "Vue")
    self.tabs.setCurrentIndex(0)
```

### [ARS-14] Affichage de la vue

À la fin de l'exécution, lit le rapport ou la sortie et affiche la vue ; signale un rapport absent ou illisible.

`arsenal/arsenal.py` ligne 496

```python
def show_view(self):
    vue = (self.running_tool or {}).get("vue")
    if not vue or self.view is None or self.running_tool is not self.tool:
        return
    try:
        err = vues.render(vue["type"], self.view, "".join(self.buffer), self.report)
    except (OSError, ValueError, vues.ET.ParseError) as e:
        err = f"rapport illisible : {e}"
    if err:
        self.status.setText(self.status.text() + " " + err)
    else:
        self.tabs.setCurrentIndex(1)
…
```

### [ARS-15] Case Administrateur

Cochée et verrouillée quand l'outil ou l'option choisie exige root (scan SYN ou UDP, détection du système, rkhunter) ; sinon libre, pour un audit Lynis complet par exemple. Seule la commande est élevée, jamais Arsenal lui-même.

`arsenal/arsenal.py` ligne 408

```python
def sync_admin(self):
    needed = needs_admin(self.tool, self.form.values())
    if needed and not self.admin.isChecked():
        self.admin.blockSignals(True)
        self.admin.setChecked(True)
        self.admin.blockSignals(False)
        self.admin_forced = True
    elif not needed and self.admin_forced:
        self.admin.blockSignals(True)
        self.admin.setChecked(False)
        self.admin.blockSignals(False)
        self.admin_forced = False
…
```


## ORB

Module Orbit Pixel

### [ORB-01] Module Orbit Pixel

Dépendances, installation du widget pour tout le système, script de disposition et réglage ORBIT_LAYOUT.

`modules/85-orbit.sh` ligne 6

```bash
module_run() {
    apt_install python3-numpy playerctl curl
    local src="$LABNOIR_ROOT/widgets/orbitpixel"
    if command -v kpackagetool6 >/dev/null 2>&1; then
        run kpackagetool6 --global --type Plasma/Applet --upgrade "$src/$ORBIT_ID" 2>/dev/null \
            || run kpackagetool6 --global --type Plasma/Applet --install "$src/$ORBIT_ID"
    else
        put_dir "$src/$ORBIT_ID" "/usr/share/plasma/plasmoids/$ORBIT_ID"
    fi
    put "$src/place-layout.sh" "$LABNOIR_PREFIX/widgets/orbitpixel/place-layout.sh" 0755
    conf_set ORBIT_LAYOUT "${LABNOIR_ORBIT_LAYOUT:-1}"
    ok "Orbit Pixel installé ; disposition posée à la première connexion (ORBIT_LAYOUT=0 dans $LABNOIR_ETC/labnoir.conf pour l'éviter)"
…
```


## HRD

Module durcissement

### [HRD-01] Module durcissement

Paquets, pare-feu, noyau, mises à jour, SSH et vérification d'AppArmor.

`modules/90-durcissement.sh` ligne 4

```bash
module_run() {
    apt_install_list durcissement
    hrd_firewall
    hrd_sysctl
    hrd_updates
    hrd_ssh
    [[ "$LABNOIR_DRY_RUN" == 1 ]] && return 0
    if command -v aa-enabled >/dev/null 2>&1 && [[ "$(aa-enabled 2>/dev/null)" == Yes ]]; then
        ok "AppArmor actif"
    else
        warn "AppArmor inactif : vérifie la ligne de commande du noyau (apparmor=1 security=apparmor)"
    fi
…
```

### [HRD-02] Pare-feu

ufw : entrées refusées, sorties permises ; SSH laissé ouvert si l'installation passe par SSH.

`modules/90-durcissement.sh` ligne 19

```bash
hrd_firewall() {
    if [[ "$LABNOIR_DRY_RUN" != 1 ]] && ! command -v ufw >/dev/null 2>&1; then
        warn "ufw absent : pare-feu non configuré"
        return 0
    fi
    run ufw default deny incoming
    run ufw default allow outgoing
    if [[ -n "${SSH_CONNECTION:-}" ]]; then
        run ufw allow OpenSSH
        warn "session SSH détectée : le port SSH reste ouvert"
    fi
    run ufw --force enable
…
```

### [HRD-03] Noyau

sysctl : pointeurs et journaux du noyau masqués, BPF non privilégié coupé, ptrace restreint, redirections et routage source refusés, filtrage de chemin inverse.

`modules/90-durcissement.sh` ligne 35

```bash
hrd_sysctl() {
    put "$LABNOIR_ROOT/config/sysctl/99-labnoir.conf" /etc/sysctl.d/99-labnoir.conf
    run sysctl --quiet --system || warn "certains réglages du noyau seront appliqués au redémarrage"
    ok "noyau durci (pointeurs et journaux du noyau masqués, redirections ICMP refusées)"
}
```

### [HRD-04] Mises à jour

Mises à jour de sécurité automatiques chaque jour.

`modules/90-durcissement.sh` ligne 42

```bash
hrd_updates() {
    put "$LABNOIR_ROOT/config/apt/20auto-upgrades" /etc/apt/apt.conf.d/20auto-upgrades
    ok "mises à jour de sécurité automatiques"
}
```

### [HRD-05] SSH

Si un serveur SSH est présent : root interdit, tentatives limitées, fail2ban.

`modules/90-durcissement.sh` ligne 48

```bash
hrd_ssh() {
    if [[ -d /etc/ssh/sshd_config.d ]] && command -v sshd >/dev/null 2>&1; then
        put "$LABNOIR_ROOT/config/ssh/10-labnoir.conf" /etc/ssh/sshd_config.d/10-labnoir.conf
        run systemctl reload ssh.service || true
        apt_install fail2ban
        run systemctl enable --now fail2ban.service || true
        ok "SSH : connexion root interdite, fail2ban actif"
    fi
}
```


## VUE

Vues graphiques d'Arsenal (arsenal/vues.py)

### [VUE-01] Niveaux de risque et cache

Services sensibles s'ils sont exposés (Telnet, FTP, SMB, RDP, VNC, bases de données, Redis…), services attendus (SSH, HTTPS, DNS…), couleurs, dossier ~/.cache/labnoir/arsenal des rapports.

`arsenal/vues.py` ligne 17

```python
RISKY = {
    "telnet", "ftp", "tftp", "microsoft-ds", "netbios-ssn", "smb", "ms-wbt-server", "rdp", "vnc",
    "mysql", "postgresql", "ms-sql-s", "redis", "mongodb", "memcached", "snmp", "rpcbind", "nfs",
    "rlogin", "rsh", "rexec", "x11", "elasticsearch", "docker",
}
```

### [VUE-02] Machines et ports

Port (numéro, protocole, état, service, version) et machine (adresse, nom, système) avec leur niveau : sensible, à vérifier, attendu, fermé.

`arsenal/vues.py` ligne 36

```python
@dataclass
```

### [VUE-03] Lecture du rapport Nmap

Lit le XML de Nmap (-oX) : machines actives, noms, système détecté, ports et versions.

`arsenal/vues.py` ligne 74

```python
def parse_nmap(path):
    root = ET.parse(path).getroot()
    hosts = []
    for h in root.findall("host"):
        status = h.find("status")
        if status is not None and status.get("state") != "up":
            continue
        addr = next((a.get("addr") for a in h.findall("address") if a.get("addrtype") in ("ipv4", "ipv6")), "?")
        name_el = h.find("hostnames/hostname")
        os_el = h.find("os/osmatch")
        host = Host(
            address=addr,
…
```

### [VUE-04] Lecture du rapport Lynis

Lit le rapport de Lynis : indice de durcissement, avertissements et suggestions avec leur détail.

`arsenal/vues.py` ligne 108

```python
def parse_lynis(path):
    index, warnings, suggestions = None, [], []
    for line in Path(path).read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("hardening_index="):
            try:
                index = int(line.split("=", 1)[1])
            except ValueError:
                index = None
        elif line.startswith("warning[]="):
            parts = line.split("=", 1)[1].split("|")
            warnings.append((parts[0], parts[1] if len(parts) > 1 else ""))
        elif line.startswith("suggestion[]="):
…
```

### [VUE-05] Lecture des détections

Détections de ClamAV (« chemin: signature FOUND ») et de YARA (« règle chemin »).

`arsenal/vues.py` ligne 128

```python
FOUND = re.compile(r"^(?P<path>.+): (?P<sig>.+) FOUND$")
```

### [VUE-06] Carte réseau Nmap

Une bulle par machine colorée selon son port le plus sensible, ses ports ouverts autour d'elle, infobulles détaillées, carte ajustée à la fenêtre, et tableau de tous les ports.

`arsenal/vues.py` ligne 145

```python
class NmapView(QWidget):
    def __init__(self):
        super().__init__()
        lay = QVBoxLayout(self)
        lay.setContentsMargins(0, 0, 0, 0)
        self.summary = QLabel(objectName="muted")
        lay.addWidget(self.summary)
        split = QSplitter(Qt.Orientation.Vertical)
        self.scene = QGraphicsScene()
        self.view = QGraphicsView(self.scene)
        self.view.setRenderHint(QPainter.RenderHint.Antialiasing)
        self.view.setObjectName("map")
…
```

### [VUE-07] Rapport Lynis

Jauge de l'indice de durcissement (rouge sous 60, orange sous 80, vert au-delà), avertissements et suggestions.

`arsenal/vues.py` ligne 256

```python
class Gauge(QWidget):
    def __init__(self):
        super().__init__()
        self.value = None
        self.setMinimumSize(200, 200)

    def set_value(self, v):
        self.value = v
        self.update()

    def paintEvent(self, _):
        p = QPainter(self)
…
```

### [VUE-08] Tableau des détections

Fichiers détectés par ClamAV ou YARA avec la signature ou la règle, et ouverture du dossier du fichier.

`arsenal/vues.py` ligne 322

```python
class FindingsView(QWidget):
    def __init__(self):
        super().__init__()
        lay = QVBoxLayout(self)
        lay.setContentsMargins(0, 0, 0, 0)
        self.summary = QLabel(objectName="muted")
        lay.addWidget(self.summary)
        self.table = QTableWidget(0, 2)
        self.table.setHorizontalHeaderLabels(["Fichier", "Détection"])
        self.table.horizontalHeader().setSectionResizeMode(0, QHeaderView.ResizeMode.Stretch)
        self.table.verticalHeader().hide()
        self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
…
```

### [VUE-09] Choix et affichage d'une vue

Crée la vue d'un type (nmap, lynis, clamav, yara) et lui passe le rapport ou la sortie de l'outil.

`arsenal/vues.py` ligne 359

```python
def make_view(kind):
    return {"nmap": NmapView, "lynis": LynisView, "clamav": FindingsView, "yara": FindingsView}[kind]()
```


## OUT

Outils du dépôt (vérifications, CI)

### [OUT-01] Vérification des paquets

Vérifie que chaque paquet des listes existe dans les dépôts du système ; utilisée par la CI sur Debian 13.

`tools/check-packages.sh` ligne 4

```bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
missing=0
total=0
apt-get update -qq >/dev/null 2>&1 || true
for list in "$ROOT"/packages/*.list; do
    name="$(basename "$list")"
    while read -r pkg _; do
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue
        total=$((total + 1))
        if ! apt-cache show "$pkg" >/dev/null 2>&1; then
            printf '%s : %s introuvable\n' "$name" "$pkg"
            missing=$((missing + 1))
…
```
