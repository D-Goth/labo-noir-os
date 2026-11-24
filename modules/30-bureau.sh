# shellcheck shell=bash disable=SC2034
MODULE_DESC="Bureau : Plasma 6 épuré façon elementary, verre dépoli, thème Lab'O Noir"

LNF_ID="fr.blacklab.labonoir"
WALL_DIR="/usr/share/wallpapers/LabONoir"

# [DSK-01]
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
    dsk_first_login
    ok "bureau prêt : il s'applique à la prochaine ouverture de session"
}

# [DSK-02]
dsk_render_defaults() {
    local theme
    theme="$(conf_get THEME || true)"
    theme="${theme:-labonoir}"
    run "$LABNOIR_PREFIX/bin/labnoir-theme" render colors "$theme" /usr/share/color-schemes/LabONoir.colors
    run "$LABNOIR_PREFIX/bin/labnoir-theme" render konsole "$theme" /usr/share/konsole/LabONoir.colorscheme
    put "$LABNOIR_ROOT/desktop/konsole/LabONoir.profile" /usr/share/konsole/LabONoir.profile
}

# [DSK-03]
dsk_system_defaults() {
    put "$LABNOIR_ROOT/config/xdg/kdeglobals" /etc/xdg/kdeglobals
    put "$LABNOIR_ROOT/config/xdg/kwinrc" /etc/xdg/kwinrc
    put "$LABNOIR_ROOT/config/xdg/konsolerc" /etc/xdg/konsolerc
    put "$LABNOIR_ROOT/config/xdg/plasmarc" /etc/xdg/plasmarc
}

# [DSK-04]
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

# [DSK-05]
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
