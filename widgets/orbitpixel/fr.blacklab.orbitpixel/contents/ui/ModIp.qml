// Système : nom de machine, IP locale, IP publique (via api.ipify.org, 1 requête/heure), uptime.
import QtQuick

OrbitCircle {
    id: c

    title: "SYSTEME"
    titleY: 20
    accentY: 35

    property string host: "--"
    property string localIp: "--"
    property string publicIp: "--"
    property real bootMs: 0
    property string uptime: "--"

    function pad(n) { return (n < 10 ? "0" : "") + n }

    function updateUptime() {
        if (bootMs <= 0)
            return
        var s = Math.floor((Date.now() - bootMs) / 1000)
        var d = Math.floor(s / 86400)
        s -= d * 86400
        var h = Math.floor(s / 3600)
        s -= h * 3600
        var m = Math.floor(s / 60)
        uptime = d + "J - " + pad(h) + ":" + pad(m) + ":" + pad(s - m * 60)
    }

    Poll {
        command: "hostname; hostname -I | awk '{print $1}'; cut -d. -f1 /proc/uptime"
        interval: 60000
        onOutput: (text) => {
            var l = text.trim().split("\n")
            if (l.length >= 3) {
                c.host = l[0].toUpperCase()
                c.localIp = l[1] !== "" ? l[1] : "--"
                c.bootMs = Date.now() - parseInt(l[2]) * 1000
                c.updateUptime()
            }
        }
    }

    Poll {
        command: "curl -s --max-time 5 https://api.ipify.org"
        interval: 3600000
        onOutput: (text) => {
            var t = text.trim()
            c.publicIp = /^[0-9a-fA-F.:]+$/.test(t) ? t : "--"
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: c.updateUptime()
    }

    OText { theme: c.theme; ax: 80; ay: 48; pt: 10; width: 120; elide: Text.ElideRight; text: c.host }

    OText { theme: c.theme; align: "left"; ax: 12; ay: 75; pt: 9; color: c.theme.accent; text: "INT" }
    OText { theme: c.theme; align: "left"; ax: 45; ay: 75; pt: 9; width: 100; elide: Text.ElideRight; text: c.localIp }

    OText { theme: c.theme; align: "left"; ax: 12; ay: 95; pt: 9; color: c.theme.accent; text: "EXT" }
    OText { theme: c.theme; align: "left"; ax: 45; ay: 95; pt: 9; width: 100; elide: Text.ElideRight; muted: true; text: c.publicIp }

    OText { theme: c.theme; ax: 80; ay: 118; pt: 10; width: 140; elide: Text.ElideRight; muted: true; text: c.uptime }
}
