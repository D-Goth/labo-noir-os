// Base d'un module : cercle 160x160 (fond + bordure), titre et ligne d'accent.
// Tout le contenu est dessiné dans l'espace 160x160 de Rainmeter puis mis à l'échelle.
import QtQuick

Item {
    id: circle

    // injectés par main.qml
    property var theme
    property var cfg
    property string modId: ""

    property string title: ""
    property bool titleAlert: false
    property real titleY: 25
    property real accentY: 45
    property real accentX: 65
    property real accentW: 30

    default property alias content: slot.data

    readonly property real u: Math.max(0.1, Math.min(width, height) / 160)

    Item {
        id: stage
        width: 160
        height: 160
        scale: circle.u
        transformOrigin: Item.TopLeft
        x: (circle.width - 160 * circle.u) / 2
        y: (circle.height - 160 * circle.u) / 2

        Rectangle {
            anchors.fill: parent
            radius: 80
            color: circle.theme ? circle.theme.bg : "#bb0a0a0a"
            border.width: 1
            border.color: circle.theme ? circle.theme.border : "#1fffffff"
            antialiasing: true
        }

        OText {
            theme: circle.theme
            ax: 80
            ay: circle.titleY
            pt: 9
            muted: true
            color: circle.titleAlert && circle.theme ? circle.theme.accent : (circle.theme ? circle.theme.muted : "gray")
            text: circle.title
        }

        Rectangle {
            visible: circle.accentY >= 0
            x: circle.accentX
            y: circle.accentY
            width: circle.accentW
            height: 2
            color: circle.theme ? circle.theme.accent : "#ff1654"
        }

        Item {
            id: slot
            anchors.fill: parent
        }
    }
}
