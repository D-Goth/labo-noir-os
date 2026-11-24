#!/usr/bin/env bash
# Installe ou met à jour le plasmoïde Orbit Pixel pour l'utilisateur courant.
# Usage : ./install.sh [--font /chemin/vers/LED_Dot-Matrix.ttf]
set -euo pipefail
cd "$(dirname "$0")"

PKG="fr.blacklab.orbitpixel"

if [[ "${1:-}" == "--font" && -n "${2:-}" ]]; then
    cp -v "$2" "$PKG/contents/fonts/dotmatrix.ttf"
fi

if [[ ! -f "$PKG/contents/fonts/dotmatrix.ttf" ]]; then
    echo "⚠  Pas de police dans $PKG/contents/fonts/dotmatrix.ttf"
    echo "   Le rendu utilisera la police de secours (réglable dans la config du widget)."
fi

kpackagetool6 -t Plasma/Applet -u "$PKG" 2>/dev/null || kpackagetool6 -t Plasma/Applet -i "$PKG"

echo
echo "Installé. Pour tester dans une fenêtre, sans toucher au bureau :"
echo "    plasmawindowed $PKG"
echo "Si « Orbit Pixel » n'apparaît pas dans la liste des widgets :"
echo "    systemctl --user restart plasma-plasmashell.service"
