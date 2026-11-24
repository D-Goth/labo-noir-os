# shellcheck shell=bash disable=SC2034
MODULE_DESC="Socle : outils de base, Flathub, fichiers Lab'O Noir dans /opt/labnoir"

# [BAS-01]
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
    done

    conf_set VERSION "$(cat "$LABNOIR_ROOT/VERSION")"
    conf_set USER "$(target_user)"
    [[ -n "$(conf_get THEME || true)" ]] || conf_set THEME labonoir
    ok "socle installé dans $LABNOIR_PREFIX"
}
