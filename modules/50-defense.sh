# shellcheck shell=bash disable=SC2034
MODULE_DESC="Défense : analyse réseau, détection, forensic, audit (blue team)"

# [DEF-01]
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

    if command -v pipx >/dev/null 2>&1 && [[ -n "$u" ]]; then
        as_user pipx install --quiet volatility3 || warn "volatility3 : installation pipx impossible"
    fi

    if systemctl list-unit-files clamav-freshclam.service >/dev/null 2>&1; then
        run systemctl enable --now clamav-freshclam.service || true
    fi
    ok "outils de défense installés (Suricata reste à configurer selon ton réseau)"
}
