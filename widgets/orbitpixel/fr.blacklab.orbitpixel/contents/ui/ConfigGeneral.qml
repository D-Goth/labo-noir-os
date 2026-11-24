import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property string cfg_moduleId
    property string cfg_moduleIdDefault
    property bool cfg_useShared
    property bool cfg_useSharedDefault
    property string cfg_accent
    property string cfg_accentDefault
    property int cfg_bgAlpha
    property int cfg_bgAlphaDefault
    property string cfg_fontFamily
    property string cfg_fontFamilyDefault
    property string cfg_diskMount
    property string cfg_diskMountDefault
    property string cfg_diskLabel
    property string cfg_diskLabelDefault

    readonly property var moduleList: [
        { text: "Horloge : heures", value: "clock-h" },
        { text: "Horloge : minutes", value: "clock-m" },
        { text: "Horloge : secondes", value: "clock-s" },
        { text: "Calendrier", value: "calendar" },
        { text: "CPU", value: "cpu" },
        { text: "RAM", value: "ram" },
        { text: "GPU", value: "gpu" },
        { text: "Disque", value: "disk" },
        { text: "Réseau", value: "network" },
        { text: "Volume", value: "volume" },
        { text: "Média : son de sortie", value: "media" },
        { text: "Média : son de sortie (variante, départ en haut)", value: "media-alt" },
        { text: "Micro (VU-mètre)", value: "micro" },
        { text: "Micro (variante, graves à l'extérieur)", value: "micro-alt" },
        { text: "Énergie (batterie)", value: "energy" },
        { text: "Système / IP", value: "ip" },
        { text: "Météo", value: "weather" },
        { text: "Control Center (engrenage)", value: "control" }
    ]

    // Même palette que le Control Center Rainmeter
    readonly property var palette: ["#ff1654", "#ff0000", "#ff8000", "#ffff00", "#00ff00", "#008080", "#0080ff", "#8000ff", "#ffffff"]

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: moduleBox
            Kirigami.FormData.label: "Module :"
            model: page.moduleList
            textRole: "text"
            valueRole: "value"
            Component.onCompleted: currentIndex = indexOfValue(page.cfg_moduleId)
            onActivated: page.cfg_moduleId = currentValue
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: "Réglages partagés :"
            text: "Suivre le Control Center (couleur, transparence)"
            checked: page.cfg_useShared
            onToggled: page.cfg_useShared = checked
        }

        RowLayout {
            Kirigami.FormData.label: "Couleur d'accent :"
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: page.palette
                delegate: Rectangle {
                    id: swatch
                    required property string modelData
                    implicitWidth: Kirigami.Units.gridUnit * 1.5
                    implicitHeight: implicitWidth
                    radius: width / 2
                    color: modelData
                    border.width: page.cfg_accent.toLowerCase() === modelData ? 3 : 1
                    border.color: Kirigami.Theme.textColor

                    MouseArea {
                        anchors.fill: parent
                        onClicked: page.cfg_accent = swatch.modelData
                    }
                }
            }
        }

        QQC2.TextField {
            Kirigami.FormData.label: "Accent (hex) :"
            text: page.cfg_accent
            onEditingFinished: page.cfg_accent = text
        }

        RowLayout {
            Kirigami.FormData.label: "Transparence du fond :"
            QQC2.Slider {
                from: 0
                to: 255
                stepSize: 5
                value: page.cfg_bgAlpha
                onMoved: page.cfg_bgAlpha = value
            }
            QQC2.Label { text: page.cfg_bgAlpha + " / 255" }
        }

        QQC2.TextField {
            Kirigami.FormData.label: "Police de secours :"
            text: page.cfg_fontFamily
            onEditingFinished: page.cfg_fontFamily = text
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.TextField {
            Kirigami.FormData.label: "Disque : point de montage :"
            visible: page.cfg_moduleId === "disk"
            text: page.cfg_diskMount
            placeholderText: "/ ou /home ou /media/…"
            onEditingFinished: page.cfg_diskMount = text
        }

        QQC2.TextField {
            Kirigami.FormData.label: "Disque : nom affiché :"
            visible: page.cfg_moduleId === "disk"
            text: page.cfg_diskLabel
            placeholderText: "optionnel (sinon le point de montage)"
            onEditingFinished: page.cfg_diskLabel = text
        }
    }
}
