// Disque : anneau de remplissage, % utilisé et espace libre.
import QtQuick

OrbitCircle {
    id: c

    readonly property string mount: ((cfg && cfg.diskMount) ? cfg.diskMount : "/").replace(/'/g, "")
    readonly property string label: (cfg && cfg.diskLabel) ? cfg.diskLabel : mount

    title: "DISQUE " + label.toUpperCase()
    titleY: 24
    accentY: 45

    property real pct: 0
    property real free: 0
    property bool online: false

    function fmt(b) {
        var u = ["B", "KB", "MB", "GB", "TB", "PB"]
        var i = 0
        while (b >= 1024 && i < u.length - 1) {
            b /= 1024
            i++
        }
        return Math.round(b) + " " + u[i]
    }

    Poll {
        command: "df -B1 --output=size,used,avail '" + c.mount + "' 2>/dev/null | tail -n1"
        interval: 15000
        onOutput: (text) => {
            var p = text.trim().split(/\s+/).map(Number)
            if (p.length >= 3 && p[0] > 0 && !isNaN(p[1]) && !isNaN(p[2])) {
                c.pct = 100 * p[1] / (p[1] + p[2])
                c.free = p[2]
                c.online = true
            } else {
                c.online = false
            }
        }
    }

    Ring {
        value: c.online ? c.pct : 0
        color: c.theme.accent
        trackColor: c.theme.track
        inner: 70
        outer: 76
    }

    OText {
        visible: c.online
        theme: c.theme
        ax: 80
        ay: 58
        pt: 36
        text: Math.round(c.pct) + "%"
    }

    OText {
        visible: c.online
        theme: c.theme
        ax: 80
        ay: 110
        pt: 9
        muted: true
        text: c.fmt(c.free) + " LIBRE"
    }

    OText {
        visible: !c.online
        theme: c.theme
        ax: 80
        ay: 65
        pt: 16
        text: "OFFLINE"
        color: c.theme.accent
    }
}
