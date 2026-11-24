// Micro : VU-mètre à 5 colonnes de pixels (3 bandes de fréquences) sur ce que capte le micro.
// Clic = couper / réactiver le micro. Titre en accent « MICRO MUTE » quand il est coupé.
// Variante « alt » : graves à l'extérieur, aigus au centre (l'inverse de la normale).
import QtQuick
import QtQuick.Controls as QQC2

OrbitCircle {
    id: c

    readonly property bool alt: modId === "micro-alt"

    title: muted ? "MICRO MUTE" : "MICRO"
    titleAlert: muted
    titleY: 15
    accentY: 31

    property bool muted: false

    // plage de dB cartographiée sur 0..1 : 35 dans la version Rainmeter (micro Windows),
    // 55 ici car les micros de portable Linux sortent beaucoup moins fort. Plus grand = plus sensible.
    readonly property real micRange: 55

    readonly property var alphas: [75, 97, 120, 143, 165, 187, 210, 233, 255]
    // groupe de colonnes : 1 = extérieur (x 32 et 120), 2 = milieu (x 54 et 98), 3 = centre (x 76)
    readonly property var columns: [
        { x: 32, g: 1 }, { x: 54, g: 2 }, { x: 76, g: 3 }, { x: 98, g: 2 }, { x: 120, g: 1 }
    ]

    AudioLevels { id: audio; mode: "in" }
    Runner { id: runner }

    Poll {
        command: "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null"
        interval: 2000
        onOutput: (text) => {
            if (text.indexOf("Volume") >= 0)
                c.muted = text.indexOf("MUTED") >= 0
        }
    }

    // niveau 0..9 d'un groupe de colonnes (même formule que Rainmeter : min(9, floor(bande * 80)))
    // bandes du démon : 0 = graves, 1 = médiums, 2 = aigus
    function level(group) {
        if (muted)
            return 0
        var band = alt ? group - 1 : 3 - group
        return Math.min(9, Math.floor(audio.norm(band, micRange) * 80))
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            c.muted = !c.muted
            runner.run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
        }
        QQC2.ToolTip.visible: containsMouse
        QQC2.ToolTip.delay: 600
        QQC2.ToolTip.text: "Clic : couper / réactiver le micro"
        hoverEnabled: true
    }

    Repeater {
        model: c.columns
        delegate: Item {
            id: col
            required property var modelData
            readonly property int lvl: c.level(modelData.g)

            // niveau k : 1 pixel au centre (y 76), puis une paire de pixels par niveau (±5 px)
            Repeater {
                model: 17
                delegate: Rectangle {
                    required property int index
                    readonly property int k: Math.abs(index - 8) + 1
                    x: col.modelData.x
                    y: 76 + (index - 8) * 5
                    width: 8
                    height: 4
                    visible: k <= col.lvl
                    color: Qt.rgba(c.theme.accent.r, c.theme.accent.g, c.theme.accent.b, c.alphas[k - 1] / 255)
                }
            }
        }
    }

    Image {
        x: 70
        y: 124
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
