# shellcheck shell=bash disable=SC2034
MODULE_DESC="Développement : compilateurs, Python, Node, Go, Rust, conteneurs, éditeurs"

# [DEV-01]
module_run() {
    apt_install_list dev
    if command -v rustup >/dev/null 2>&1 && [[ -n "$(target_user)" ]]; then
        as_user rustup default stable || warn "rustup : la chaîne stable s'installera au premier « rustup default stable »"
    fi
    flatpak_install com.vscodium.codium
    ok "poste de dev prêt"
}
