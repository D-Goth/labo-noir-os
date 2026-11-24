# shellcheck shell=bash

# [LIB-01]
LABNOIR_ROOT="${LABNOIR_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LABNOIR_PREFIX="${LABNOIR_PREFIX:-/opt/labnoir}"
LABNOIR_ETC="${LABNOIR_ETC:-/etc/labnoir}"
LABNOIR_LOG="${LABNOIR_LOG:-/var/log/labnoir-install.log}"
LABNOIR_DRY_RUN="${LABNOIR_DRY_RUN:-0}"
LABNOIR_MISSING_FILE="${LABNOIR_MISSING_FILE:-/tmp/labnoir-missing.$$}"

# [LIB-02]
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

step() { printf '\n%s●%s %s\n' "$C_ACC" "$C_OFF" "$*"; _log "== $*"; }
info() { printf '  %s\n' "$*"; _log "   $*"; }
ok() { printf '  %s✓%s %s\n' "$C_OK" "$C_OFF" "$*"; _log "ok $*"; }
warn() { printf '  %s!%s %s\n' "$C_WARN" "$C_OFF" "$*" >&2; _log "!! $*"; }
die() { printf '  %s✗%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2; _log "xx $*"; exit 1; }

# [LIB-03]
run() {
    if [[ "$LABNOIR_DRY_RUN" == 1 ]]; then
        printf '  %s$ %s%s\n' "$C_DIM" "$*" "$C_OFF"
        return 0
    fi
    _log "\$ $*"
    "$@"
}

# [LIB-04]
read_list() {
    local file="$LABNOIR_ROOT/packages/$1.list"
    [[ -f "$file" ]] || die "liste de paquets introuvable : $file"
    grep -Ev '^[[:space:]]*($|#)' "$file" | awk '{print $1}'
}

# [LIB-05]
apt_ready() {
    if [[ "${_LABNOIR_APT_UPDATED:-0}" != 1 ]]; then
        run apt-get update -qq || warn "apt-get update a échoué : les paquets seront cherchés dans l'index existant"
        _LABNOIR_APT_UPDATED=1
        export _LABNOIR_APT_UPDATED
    fi
}

apt_has() {
    apt-cache show "$1" >/dev/null 2>&1
}

apt_install() {
    local available=() missing=() pkg
    apt_ready
    for pkg in "$@"; do
        if apt_has "$pkg"; then
            available+=("$pkg")
        else
            missing+=("$pkg")
        fi
    done
    if ((${#missing[@]})); then
        warn "absents des dépôts : ${missing[*]}"
        printf '%s\n' "${missing[@]}" >>"$LABNOIR_MISSING_FILE"
    fi
    if ((${#available[@]})); then
        info "${#available[@]} paquet(s) : ${available[*]}"
        DEBIAN_FRONTEND=noninteractive run apt-get install -y -q --no-install-recommends "${available[@]}"
    fi
}

apt_install_list() {
    local pkgs=()
    mapfile -t pkgs < <(read_list "$1")
    apt_install "${pkgs[@]}"
}

# [LIB-06]
target_user() {
    local u="${LABNOIR_USER:-${SUDO_USER:-}}"
    if [[ -z "$u" || "$u" == root ]]; then
        u="$(awk -F: '$3 >= 1000 && $3 < 60000 && $7 !~ /nologin|false/ {print $1; exit}' /etc/passwd)"
    fi
    printf '%s' "$u"
}

target_home() {
    getent passwd "$(target_user)" | cut -d: -f6
}

# [LIB-07]
as_user() {
    local u
    u="$(target_user)"
    [[ -n "$u" ]] || { warn "aucun compte utilisateur trouvé pour : $*"; return 1; }
    local uid
    uid="$(id -u "$u")"
    run sudo -u "$u" -H env XDG_RUNTIME_DIR="/run/user/$uid" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" "$@"
}

# [LIB-08]
put() {
    local src="$1" dest="$2" mode="${3:-0644}"
    run install -D -m "$mode" "$src" "$dest"
}

put_dir() {
    local src="$1" dest="$2"
    run mkdir -p "$dest"
    run cp -a "$src/." "$dest/"
}

link_bin() {
    run ln -sfn "$LABNOIR_PREFIX/bin/$1" "/usr/local/bin/$1"
}

# [LIB-09]
flatpak_ready() {
    command -v flatpak >/dev/null 2>&1 || apt_install flatpak
    run flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

flatpak_install() {
    flatpak_ready
    local app
    for app in "$@"; do
        if [[ "$LABNOIR_DRY_RUN" != 1 ]] && flatpak info --system "$app" >/dev/null 2>&1; then
            ok "$app déjà installé"
            continue
        fi
        run flatpak install -y --noninteractive --system flathub "$app" || warn "Flathub : $app non installé"
    done
}

# [LIB-10]
os_field() {
    sed -n "s/^$1=//p" /etc/os-release 2>/dev/null | head -n1 | tr -d '"'
}

is_debian13() {
    [[ "$(os_field ID)" == debian && "$(os_field VERSION_ID)" == 13 ]]
}

is_ubuntu() {
    [[ "$(os_field ID)" == ubuntu ]]
}

is_supported() {
    is_debian13 || { is_ubuntu && [[ "$(os_field VERSION_ID)" == 26.04 ]]; }
}

# [LIB-11]
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
    fi
}

conf_get() {
    local file="$LABNOIR_ETC/labnoir.conf"
    [[ -f "$file" ]] && sed -n "s|^$1=||p" "$file" | tail -n1
}
