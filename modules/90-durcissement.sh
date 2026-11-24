# shellcheck shell=bash disable=SC2034
MODULE_DESC="Durcissement : pare-feu, mises à jour de sécurité, noyau, AppArmor"

# [HRD-01]
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
}

# [HRD-02]
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
    ok "pare-feu actif : tout refusé en entrée, tout permis en sortie"
}

# [HRD-03]
hrd_sysctl() {
    put "$LABNOIR_ROOT/config/sysctl/99-labnoir.conf" /etc/sysctl.d/99-labnoir.conf
    run sysctl --quiet --system || warn "certains réglages du noyau seront appliqués au redémarrage"
    ok "noyau durci (pointeurs et journaux du noyau masqués, redirections ICMP refusées)"
}

# [HRD-04]
hrd_updates() {
    put "$LABNOIR_ROOT/config/apt/20auto-upgrades" /etc/apt/apt.conf.d/20auto-upgrades
    ok "mises à jour de sécurité automatiques"
}

# [HRD-05]
hrd_ssh() {
    if [[ -d /etc/ssh/sshd_config.d ]] && command -v sshd >/dev/null 2>&1; then
        put "$LABNOIR_ROOT/config/ssh/10-labnoir.conf" /etc/ssh/sshd_config.d/10-labnoir.conf
        run systemctl reload ssh.service || true
        apt_install fail2ban
        run systemctl enable --now fail2ban.service || true
        ok "SSH : connexion root interdite, fail2ban actif"
    fi
}
