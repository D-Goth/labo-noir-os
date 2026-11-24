#!/usr/bin/env bash
set -uo pipefail

# [INS-01]
LABNOIR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LABNOIR_ROOT
# shellcheck source=lib/common.sh
. "$LABNOIR_ROOT/lib/common.sh"

ONLY=()
SKIP=()
ASSUME_YES=0
FORCE=0

# [INS-02]
usage() {
    cat <<EOF
Lab'O Noir OS : installateur

Transforme une Debian 13 avec KDE Plasma 6 en poste Lab'O Noir.

Usage : sudo ./install.sh [options]

  --list              affiche les modules et quitte
  --only a,b          n'installe que ces modules
  --skip a,b          saute ces modules
  --user NOM          compte à personnaliser (par défaut : celui qui a lancé sudo)
  --dry-run           affiche ce qui serait fait, sans rien modifier
  --yes               ne demande pas de confirmation
  --force             continue même hors de Debian 13
  -h, --help          cette aide
EOF
}

split_csv() {
    local IFS=,
    read -r -a _split <<<"$1"
    printf '%s\n' "${_split[@]}"
}

while (($#)); do
    case "$1" in
        --list) LIST_ONLY=1 ;;
        --only) shift; mapfile -t ONLY < <(split_csv "${1:-}") ;;
        --skip) shift; mapfile -t SKIP < <(split_csv "${1:-}") ;;
        --user) shift; LABNOIR_USER="${1:-}"; export LABNOIR_USER ;;
        --dry-run) LABNOIR_DRY_RUN=1; export LABNOIR_DRY_RUN ;;
        --yes) ASSUME_YES=1 ;;
        --force) FORCE=1 ;;
        -h | --help) usage; exit 0 ;;
        *) usage; die "option inconnue : $1" ;;
    esac
    shift
done

# [INS-03]
module_id() {
    basename "$1" .sh | sed 's/^[0-9]*-//'
}

module_desc() {
    sed -n 's/^MODULE_DESC="\(.*\)"$/\1/p' "$1" | head -n1
}

module_default() {
    ! grep -q '^MODULE_OPTIONAL=1' "$1"
}

contains() {
    local needle="$1" item
    shift
    for item in "$@"; do [[ "$item" == "$needle" ]] && return 0; done
    return 1
}

MODULES=()
for f in "$LABNOIR_ROOT"/modules/[0-9]*.sh; do
    MODULES+=("$f")
done

selected() {
    local id
    id="$(module_id "$1")"
    if ((${#ONLY[@]})); then
        contains "$id" "${ONLY[@]}"
        return
    fi
    ((${#SKIP[@]})) && contains "$id" "${SKIP[@]}" && return 1
    module_default "$1"
}

if [[ "${LIST_ONLY:-0}" == 1 ]]; then
    printf "Modules de Lab'O Noir OS :\n\n"
    for f in "${MODULES[@]}"; do
        mark="  "
        module_default "$f" || mark="○ "
        printf '  %s%-16s %s\n' "$mark" "$(module_id "$f")" "$(module_desc "$f")"
    done
    printf '\n  ○ = facultatif, à demander avec --only\n'
    exit 0
fi

for id in "${ONLY[@]}" "${SKIP[@]}"; do
    [[ -z "$id" ]] && continue
    found=0
    for f in "${MODULES[@]}"; do [[ "$(module_id "$f")" == "$id" ]] && found=1; done
    ((found)) || die "module inconnu : $id (voir --list)"
done

# [INS-04]
[[ $EUID -eq 0 || "$LABNOIR_DRY_RUN" == 1 ]] || die "lance l'installateur avec sudo : sudo ./install.sh"

if ! is_debian13; then
    if ((FORCE)); then
        warn "système détecté : $(os_field PRETTY_NAME). Lab'O Noir vise Debian 13 : on continue (--force)."
    elif [[ "$LABNOIR_DRY_RUN" == 1 ]]; then
        warn "système détecté : $(os_field PRETTY_NAME), pas Debian 13 (simulation seulement)"
    else
        die "Lab'O Noir vise Debian 13 (système détecté : $(os_field PRETTY_NAME)). Relance avec --force pour essayer quand même."
    fi
fi

USER_NAME="$(target_user)"
TODO=()
for f in "${MODULES[@]}"; do
    selected "$f" && TODO+=("$f")
done
((${#TODO[@]})) || die "aucun module sélectionné"

printf "\n%sLab'O Noir OS%s\n\n" "$C_ACC" "$C_OFF"
info "Compte personnalisé : ${USER_NAME:-aucun}"
info "Modules : $(for f in "${TODO[@]}"; do printf '%s ' "$(module_id "$f")"; done)"
[[ "$LABNOIR_DRY_RUN" == 1 ]] && info "Simulation : rien ne sera modifié."

if [[ "$ASSUME_YES" != 1 && "$LABNOIR_DRY_RUN" != 1 && -t 0 ]]; then
    printf '\n  Continuer ? [O/n] '
    read -r answer
    [[ -z "$answer" || "$answer" =~ ^[oOyY] ]] || exit 0
fi

# [INS-05]
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
    id="$(module_id "$f")"
    step "$id · $(module_desc "$f")"
    if (
        set -e
        # shellcheck source=/dev/null
        . "$f"
        module_run
    ); then
        DONE+=("$id")
    else
        FAILED+=("$id")
        warn "le module $id a échoué : voir $LABNOIR_LOG"
    fi
done

# [INS-06]
printf '\n%s●%s Bilan\n' "$C_ACC" "$C_OFF"
((${#DONE[@]})) && ok "terminés : ${DONE[*]}"
((${#FAILED[@]})) && warn "en échec : ${FAILED[*]}"
if [[ -s "$LABNOIR_MISSING_FILE" ]]; then
    warn "paquets introuvables dans les dépôts : $(sort -u "$LABNOIR_MISSING_FILE" | tr '\n' ' ')"
fi
rm -f "$LABNOIR_MISSING_FILE"
if [[ "$LABNOIR_DRY_RUN" != 1 ]]; then
    info "Journal : $LABNOIR_LOG"
    info "Ferme puis rouvre ta session pour appliquer le bureau."
fi
((${#FAILED[@]} == 0))
