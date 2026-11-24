// Orbit Pixel : plasmoïde « un module par instance ».
// Ajoute le widget autant de fois que nécessaire et choisis le module dans sa configuration,
// ou utilise le module « Control Center » (icône engrenage) pour tout gérer depuis un panneau.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string moduleId: Plasmoid.configuration.moduleId
    readonly property bool isControl: moduleId === "control"
    readonly property bool useShared: Plasmoid.configuration.useShared
    readonly property string fallbackFont: Plasmoid.configuration.fontFamily

    // réglages partagés (~/.config/orbitpixelrc, écrits par le Control Center)
    property var shared: ({})

    readonly property color accentColor: (useShared && shared.accent && /^#[0-9a-fA-F]{6}$/.test(shared.accent))
        ? shared.accent : Plasmoid.configuration.accent
    readonly property int bgAlpha: (useShared && shared.bgAlpha !== undefined && !isNaN(parseInt(shared.bgAlpha)))
        ? Math.max(0, Math.min(255, parseInt(shared.bgAlpha))) : Plasmoid.configuration.bgAlpha

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: isControl ? compactRepresentation : fullRepresentation

    function parseRc(text) {
        var o = {}, inGeneral = false
        text.split("\n").forEach(function (l) {
            l = l.trim()
            if (l.charAt(0) === "[") {
                inGeneral = (l === "[General]")
                return
            }
            if (!inGeneral)
                return
            var i = l.indexOf("=")
            if (i > 0)
                o[l.slice(0, i).trim()] = l.slice(i + 1).trim()
        })
        return o
    }

    Poll {
        command: "cat \"${XDG_CONFIG_HOME:-$HOME/.config}/orbitpixelrc\" 2>/dev/null"
        interval: 2000
        onOutput: (text) => {
            var o = root.parseRc(text)
            if (JSON.stringify(o) !== JSON.stringify(root.shared))
                root.shared = o
        }
    }

    // Dépose ta police en contents/fonts/dotmatrix.ttf (voir README).
    // Sinon on tente le nom de police installé sur le système.
    FontLoader {
        id: fontFile
        source: Qt.resolvedUrl("../fonts/dotmatrix.ttf")
    }

    // Équivalent de Variables.inc
    QtObject {
        id: theme
        readonly property var shared: root.shared
        readonly property string fontFamily: fontFile.status === FontLoader.Ready ? fontFile.name : root.fallbackFont
        readonly property color accent: root.accentColor
        readonly property color text: Qt.rgba(1, 1, 1, 1)
        readonly property color muted: Qt.rgba(1, 1, 1, 150 / 255)
        readonly property color border: Qt.rgba(1, 1, 1, 30 / 255)
        readonly property color track: Qt.rgba(1, 1, 1, 20 / 255)
        readonly property color bg: Qt.rgba(10 / 255, 10 / 255, 10 / 255, root.bgAlpha / 255)
    }

    function fileFor(id) {
        if (id.indexOf("clock-") === 0) return "ModClock.qml"
        switch (id) {
        case "calendar": return "ModCalendar.qml"
        case "cpu":
        case "ram":
        case "gpu": return "ModGauge.qml"
        case "disk": return "ModDisk.qml"
        case "network": return "ModNetwork.qml"
        case "volume": return "ModVolume.qml"
        case "energy": return "ModEnergy.qml"
        case "ip": return "ModIp.qml"
        case "weather": return "ModWeather.qml"
        case "media":
        case "media-alt": return "ModMedia.qml"
        case "micro":
        case "micro-alt": return "ModMicro.qml"
        case "control": return "ControlCenter.qml"
        }
        return "ModGauge.qml"
    }

    // Control Center replié : petit cercle avec un engrenage ; un clic ouvre le panneau
    compactRepresentation: Item {
        Layout.minimumWidth: 40
        Layout.minimumHeight: 40
        Layout.preferredWidth: 64
        Layout.preferredHeight: 64

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: theme.bg
            border.width: 1
            border.color: theme.border
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: parent.width * 0.5
            height: width
            source: "configure"
            isMask: true
            color: theme.accent
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: root.isControl ? 560 : 160
        Layout.preferredHeight: root.isControl ? 640 : 160
        Layout.minimumWidth: root.isControl ? 560 : 64
        Layout.minimumHeight: root.isControl ? 640 : 64

        Loader {
            id: loader
            anchors.fill: parent

            function reload() {
                setSource(Qt.resolvedUrl(root.fileFor(root.moduleId)), {
                    "theme": theme,
                    "cfg": Plasmoid.configuration,
                    "modId": root.moduleId
                })
            }

            Component.onCompleted: reload()

            // si un fichier QML ne se charge pas, on le dit au lieu d'afficher du vide
            Text {
                anchors.centerIn: parent
                visible: loader.status === Loader.Error
                width: parent.width - 24
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: "#ff1654"
                text: "Orbit Pixel : erreur de chargement de " + root.fileFor(root.moduleId) + "\n(journalctl --user -b | grep -i orbitpixel)"
            }

            Connections {
                target: root
                function onModuleIdChanged() { loader.reload() }
            }
        }
    }
}
