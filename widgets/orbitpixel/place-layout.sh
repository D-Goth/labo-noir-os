#!/usr/bin/env bash
# Place automatiquement les modules Orbit Pixel sur le bureau (script Plasma via D-Bus).
# Supprime d'abord les instances Orbit Pixel existantes, puis recrée la disposition.
# Usage : ./place-layout.sh [largeur_écran]     (défaut : 1920)
set -euo pipefail

W="${1:-1920}"

read -r -d '' JS <<EOF || true
var W = $W;
var M = 16, P = 168;            // marge, pas entre les cercles (160 + 8)
var d = desktops()[0];

d.widgets().forEach(function (w) {
    if (w.type === "fr.blacklab.orbitpixel") w.remove();
});

function add(mod, x, y, extra, size) {
    size = size || 160;
    var w = d.addWidget("fr.blacklab.orbitpixel", x, y, size, size);
    w.currentConfigGroup = ["General"];
    w.writeConfig("moduleId", mod);
    if (extra) { for (var k in extra) w.writeConfig(k, extra[k]); }
    w.reloadConfig();
}

// haut gauche : calendrier + horloge
add("calendar", M,        M);
add("clock-h",  M + P,    M);
add("clock-m",  M + 2*P,  M);
add("clock-s",  M + 3*P,  M);
// colonne gauche : système
add("cpu", M, M + P);
add("ram", M, M + 2*P);
add("gpu", M, M + 3*P);
// haut centre : son de sortie, volume, micro
add("media",  W/2 - 252, M);
add("volume", W/2 - 84,  M);
add("micro",  W/2 + 84,  M);
// colonne droite
add("weather", W - M - 160 - 2*P, M);
add("energy",  W - M - 160 - P, M);
add("network", W - M - 160, M);
add("ip",      W - M - 160, M + P);
add("disk",    W - M - 160, M + 2*P, { diskMount: "/" });
// Control Center (engrenage), bas gauche
add("control", M, M + 4*P, null, 64);
EOF

busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$JS"
echo "Disposition envoyée à Plasma."
