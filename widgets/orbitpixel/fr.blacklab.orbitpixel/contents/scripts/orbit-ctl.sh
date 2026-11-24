#!/bin/sh
# Pilote les widgets Orbit Pixel du bureau (utilisé par le Control Center).
#   orbit-ctl.sh list                     modules présents (un par ligne, « disk|/point » pour les disques)
#   orbit-ctl.sh add <module> [point]     ajoute un widget
#   orbit-ctl.sh remove <module> [point]  retire le(s) widget(s) de ce module
cmd="$1"
mod="$2"
mnt="$3"

# on n'accepte que des caractères sûrs (ces valeurs finissent dans un script Plasma)
if printf '%s%s' "$mod" "$mnt" | grep -q '[^A-Za-z0-9._/ -]'; then
    echo "caractères interdits" >&2
    exit 2
fi

case "$cmd" in
list)
    # lecture de la config de Plasma (pas de valeur de retour fiable côté D-Bus).
    # Plasma écrit ce fichier avec quelques secondes de retard ; un module « cpu » (valeur
    # par défaut) n'y figure pas explicitement.
    f="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"
    [ -r "$f" ] || exit 0
    awk '
    BEGIN { FS = "=" }
    /^\[/ {
        key = ""; rest = ""
        if (match($0, /^\[Containments\]\[[0-9]+\]\[Applets\]\[[0-9]+\]/)) {
            key = substr($0, RSTART, RLENGTH); rest = substr($0, RLENGTH + 1)
        }
        next
    }
    key == "" { next }
    rest == "" && $1 == "plugin" && $2 == "fr.blacklab.orbitpixel" { isorb[key] = 1 }
    rest == "[Configuration][General]" && $1 == "moduleId" { mod[key] = $2 }
    rest == "[Configuration][General]" && $1 == "diskMount" { mnt[key] = $2 }
    END {
        for (k in isorb) {
            m = (k in mod) ? mod[k] : "cpu"
            if (m == "disk") print "disk|" ((k in mnt) ? mnt[k] : "/")
            else print m
        }
    }' "$f"
    ;;
add | remove)
    [ -n "$mod" ] || { echo "module manquant" >&2; exit 2; }
    JS=$(cat <<EOF
var d = desktops()[0];
var PLUGIN = "fr.blacklab.orbitpixel";
var CMD = "$cmd", MOD = "$mod", MNT = "$mnt";
function info(w) {
    w.currentConfigGroup = ["General"];
    var m = w.readConfig("moduleId", "cpu");
    return { m: m, mount: (m === "disk") ? w.readConfig("diskMount", "/") : "" };
}
var ws = d.widgets().filter(function (w) { return w.type === PLUGIN; });
if (CMD === "remove") {
    ws.forEach(function (w) {
        var i = info(w);
        if (i.m === MOD && (MOD !== "disk" || MNT === "" || i.mount === MNT)) w.remove();
    });
} else {
    var n = ws.length % 8;
    var size = (MOD === "control") ? 64 : 160;
    var w2 = d.addWidget(PLUGIN, 200 + n * 30, 200 + n * 30, size, size);
    w2.currentConfigGroup = ["General"];
    w2.writeConfig("moduleId", MOD);
    if (MOD === "disk" && MNT !== "") w2.writeConfig("diskMount", MNT);
    w2.reloadConfig();
}
EOF
)
    if [ -n "$ORBIT_CTL_DRYRUN" ]; then printf '%s\n' "$JS"; exit 0; fi
    busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$JS" >/dev/null
    ;;
*)
    echo "usage: orbit-ctl.sh list | add <module> [point] | remove <module> [point]" >&2
    exit 2
    ;;
esac
