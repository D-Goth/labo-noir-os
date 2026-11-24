# shellcheck shell=bash disable=SC2034
MODULE_DESC="Red team : Kali isolée dans un conteneur Distrobox (outils prêts à l'emploi)"

# [RED-01]
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
