# shellcheck shell=bash disable=SC2034
MODULE_DESC="Confidentialité : aucune date de naissance, garde-fou contre le service d'âge, pas de télémétrie"

# [PRV-01]
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
    ok "retours d'usage de KDE désactivés par défaut"

    is_ubuntu && prv_ubuntu

    conf_set PRIVACY_GUARD 1
    if [[ "$LABNOIR_DRY_RUN" != 1 && -x "$LABNOIR_PREFIX/bin/labnoir-privacy" ]]; then
        "$LABNOIR_PREFIX/bin/labnoir-privacy" check || true
    fi
}

# [PRV-07]
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
    fi
    if command -v ubuntu-report >/dev/null 2>&1; then
        as_user ubuntu-report -f send no || true
    fi
    ok "Ubuntu : rapports de plantage, whoopsie, ubuntu-report et actualités du MOTD coupés"
}
