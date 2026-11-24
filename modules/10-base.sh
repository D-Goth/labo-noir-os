# shellcheck shell=bash disable=SC2034
MODULE_DESC="Socle : outils de base, Flathub, fichiers Lab'O Noir dans /opt/labnoir"

# [BAS-01]
module_run() {
    apt_install_list base
    flatpak_ready
    bas_guest_tools
    bas_browser

    run mkdir -p "$LABNOIR_PREFIX" "$LABNOIR_ETC"
    put_dir "$LABNOIR_ROOT/bin" "$LABNOIR_PREFIX/bin"
    put_dir "$LABNOIR_ROOT/themes" "$LABNOIR_PREFIX/themes"
    put_dir "$LABNOIR_ROOT/desktop" "$LABNOIR_PREFIX/desktop"
    put "$LABNOIR_ROOT/CREDITS.md" "$LABNOIR_PREFIX/CREDITS.md"
    put "$LABNOIR_ROOT/VERSION" "$LABNOIR_PREFIX/VERSION"
    run chmod 0755 "$LABNOIR_PREFIX"/bin/*
    local tool
    for tool in labnoir-theme labnoir-privacy labnoir-redteam labnoir-about; do
        link_bin "$tool"
    done

    conf_set VERSION "$(cat "$LABNOIR_ROOT/VERSION")"
    conf_set USER "$(target_user)"
    [[ -n "$(conf_get THEME || true)" ]] || conf_set THEME labonoir
    ok "socle installé dans $LABNOIR_PREFIX"
}

# [BAS-02]
bas_guest_tools() {
    local virt
    virt="$(systemd-detect-virt 2>/dev/null || true)"
    case "$virt" in
        vmware) apt_install open-vm-tools open-vm-tools-desktop ;;
        kvm | qemu) apt_install spice-vdagent qemu-guest-agent ;;
        oracle) apt_install virtualbox-guest-x11 virtualbox-guest-utils ;;
        *) return 0 ;;
    esac
    ok "machine virtuelle $virt : outils invités installés (taille d'écran automatique après redémarrage)"
}

# [BAS-03]
bas_browser() {
    flatpak_install app.zen_browser.zen
    if [[ -n "$(target_user)" ]]; then
        as_user xdg-settings set default-web-browser app.zen_browser.zen.desktop \
            || warn "Zen non défini comme navigateur par défaut : Configuration du système > Applications par défaut"
    fi
    ok "Zen Browser installé et choisi comme navigateur par défaut"
}
