# shellcheck shell=bash disable=SC2034
MODULE_DESC="Messagerie sans inscription : SimpleX Chat et Briar"

# [MSG-01]
module_run() {
    flatpak_install chat.simplex.simplex org.briarproject.Briar
    ok "SimpleX (aucun identifiant) et Briar (Tor, Wi-Fi, Bluetooth) installés"
}
