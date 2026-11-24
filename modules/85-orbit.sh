# shellcheck shell=bash disable=SC2034
MODULE_DESC="Orbit Pixel : modules circulaires pour le bureau (horloge, système, son, météo)"

ORBIT_ID="fr.blacklab.orbitpixel"

# [ORB-01]
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
}
