# shellcheck shell=bash disable=SC2034
MODULE_DESC="Arsenal : lanceur graphique des outils (système et Kali)"

# [ARS-01]
module_run() {
    apt_install_list arsenal
    put_dir "$LABNOIR_ROOT/arsenal" "$LABNOIR_PREFIX/arsenal"
    run chmod 0755 "$LABNOIR_PREFIX/arsenal/arsenal.py"
    run ln -sfn "$LABNOIR_PREFIX/arsenal/arsenal.py" /usr/local/bin/arsenal
    put "$LABNOIR_ROOT/config/applications/labnoir-arsenal.desktop" /usr/share/applications/labnoir-arsenal.desktop
    ok "Arsenal : menu des applications ou commande « arsenal »"
}
