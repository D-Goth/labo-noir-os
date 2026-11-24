# shellcheck shell=bash disable=SC2034
MODULE_DESC="Virtualisation : QEMU/KVM et virt-manager pour les VM d'attaque et d'analyse"

# [VIR-01]
module_run() {
    apt_install_list virtualisation
    local u
    u="$(target_user)"
    if [[ -n "$u" ]]; then
        run usermod -aG libvirt,kvm "$u"
    fi
    run systemctl enable --now libvirtd.service || true
    if [[ ! -e /dev/kvm ]]; then
        warn "/dev/kvm absent : active la virtualisation (VT-x / AMD-V) dans le BIOS pour des VM rapides"
    fi
    ok "virt-manager prêt (après reconnexion) ; « labnoir-redteam vm » vérifie l'installation"
}
