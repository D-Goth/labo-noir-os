// Média : 6 anneaux qui réagissent au son qui SORT (haut-parleurs ou oreillette),
// progression du morceau sur le bord, titre / artiste (via playerctl, optionnel).
// Variante « alt » : les arcs partent du haut au lieu du bas, sensibilité 70 au lieu de 90.
import QtQuick

OrbitCircle {
    id: c

    readonly property bool alt: modId === "media-alt"
    readonly property real startAngle: alt ? 270 : 90
    readonly property real sens: alt ? 70 : 90

    title: ""
    accentY: -1

    property string playState: ""
    property string trackTitle: ""
    property string artist: ""
    property real progress: 0

    AudioLevels { id: audio; mode: "out" }

    Poll {
        command: "playerctl metadata --format '{{status}}~|~{{title}}~|~{{artist}}~|~{{position}}~|~{{mpris:length}}' 2>/dev/null | head -n1"
        interval: 1000
        onOutput: (text) => {
            var p = text.trim().split("~|~")
            if (p.length < 5) {
                c.playState = ""
                c.trackTitle = ""
                c.artist = ""
                c.progress = 0
                return
            }
            c.playState = p[0]
            c.trackTitle = p[1]
            c.artist = p[2]
            var pos = parseFloat(p[3]), len = parseFloat(p[4])
            c.progress = (len > 0 && !isNaN(pos)) ? Math.max(0, Math.min(1, pos / len)) : 0
        }
    }

    // piste de progression + progression
    MirrorArc { value: 1; mid: 76; color: c.theme.track; startAngle: c.startAngle }
    MirrorArc { value: c.progress; mid: 76; color: c.theme.accent; startAngle: c.startAngle }

    // 6 anneaux concentriques, un par bande de fréquences (graves à l'extérieur)
    Repeater {
        model: 6
        delegate: MirrorArc {
            required property int index
            value: audio.norm(index, c.sens)
            mid: 67 - 8 * index
            startAngle: c.startAngle
            color: index % 2 === 0 ? c.theme.accent : Qt.rgba(1, 1, 1, 200 / 255)
        }
    }

    // cible au centre : pleine quand ça joue, atténuée sinon
    Item {
        x: 68
        y: 68
        width: 24
        height: 24
        opacity: c.playState === "Playing" ? 1 : 100 / 255
        Rectangle { x: 2; y: 2; width: 20; height: 20; radius: 10; color: "transparent"; border.width: 2; border.color: c.theme.accent }
        Rectangle { x: 6; y: 6; width: 12; height: 12; radius: 6; color: "transparent"; border.width: 1.5; border.color: c.theme.accent }
        Rectangle { x: 10; y: 10; width: 4; height: 4; radius: 2; color: c.theme.accent }
    }

    OText { theme: c.theme; ax: 80; ay: 60; pt: 8; width: 50; elide: Text.ElideRight; fontOverride: "Monospace"; text: c.trackTitle }
    OText { theme: c.theme; ax: 80; ay: 75; pt: 7; width: 50; elide: Text.ElideRight; fontOverride: "Monospace"; muted: true; text: c.artist }
}
