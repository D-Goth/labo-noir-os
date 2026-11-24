// Réseau : débit entrant / sortant (toutes interfaces physiques) + logo Black-Lab.
import QtQuick

OrbitCircle {
    id: c

    title: "RESEAU"
    titleY: 20
    accentY: 35

    property real rxRate: 0
    property real txRate: 0
    property real lastRx: -1
    property real lastTx: -1
    property real lastT: 0

    function rate(b) {
        var u = ["B", "KB", "MB", "GB"]
        var i = 0
        while (b >= 1024 && i < u.length - 1) {
            b /= 1024
            i++
        }
        return b.toFixed(1) + " " + u[i] + "/S"
    }

    // sed : le noyau colle parfois "iface:octets" sans espace ; on ignore lo et les interfaces virtuelles
    Poll {
        command: "sed 's/:/ /' /proc/net/dev | awk 'NR>2 && $1 !~ /^(lo|docker|veth|br-|virbr)/ {rx+=$2; tx+=$10} END{print rx+0, tx+0}'"
        interval: 1000
        onOutput: (text) => {
            var p = text.trim().split(/\s+/).map(Number)
            if (p.length < 2 || isNaN(p[0]) || isNaN(p[1]))
                return
            var now = Date.now()
            if (c.lastRx >= 0 && now > c.lastT) {
                var dt = (now - c.lastT) / 1000
                c.rxRate = Math.max(0, (p[0] - c.lastRx) / dt)
                c.txRate = Math.max(0, (p[1] - c.lastTx) / dt)
            }
            c.lastRx = p[0]
            c.lastTx = p[1]
            c.lastT = now
        }
    }

    OText { theme: c.theme; align: "left"; ax: 18; ay: 70; pt: 10; muted: true; text: "IN" }
    OText { theme: c.theme; align: "right"; ax: 140; ay: 65; pt: 12; text: c.rate(c.rxRate) }
    OText { theme: c.theme; align: "left"; ax: 12; ay: 100; pt: 10; muted: true; text: "OUT" }
    OText { theme: c.theme; align: "right"; ax: 140; ay: 95; pt: 12; color: c.theme.accent; text: c.rate(c.txRate) }

    Image {
        x: 70
        y: 125
        width: 20
        height: 20
        smooth: true
        mipmap: true
        source: Qt.resolvedUrl("../images/logo.png")

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally("https://www.black-lab.fr")
        }
    }
}
