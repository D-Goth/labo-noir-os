// Énergie : anneau de 20 LED (une par palier de 5 %), pulsation, état de la batterie.
// Sur secteur (ou sans batterie) : 20 LED allumées + éclair au lieu du pourcentage.
import QtQuick

OrbitCircle {
    id: c

    title: "ENERGIE"
    titleY: 30
    accentY: 45
    accentX: 71
    accentW: 18

    property bool hasBattery: false
    property int percent: 0
    property string status: ""      // Charging | Discharging | Full | Not charging | Unknown
    property real phase: 0

    readonly property bool charging: hasBattery && status === "Charging"
    readonly property bool critical: hasBattery && status === "Discharging" && percent <= 10
    readonly property bool onBattery: hasBattery && status === "Discharging"
    // secteur sans charge en cours (ou pas de batterie) : tout allumé + éclair
    readonly property bool acMode: !hasBattery || (!charging && !onBattery)

    readonly property color activeColor: charging ? Qt.rgba(0, 220 / 255, 180 / 255, 1)
        : critical ? theme.accent
        : onBattery ? Qt.rgba(1, 150 / 255, 50 / 255, 1)
        : theme.accent

    readonly property string statusText: !hasBattery ? "POWER MODE"
        : charging ? "CHARGING"
        : critical ? "CRITICAL BATTERY"
        : onBattery ? "ON BATTERY"
        : "AC POWER"

    Poll {
        command: "cat /sys/class/power_supply/BAT*/capacity /sys/class/power_supply/BAT*/status 2>/dev/null"
        interval: 5000
        onOutput: (text) => {
            var l = text.trim().split("\n")
            if (l.length >= 2 && !isNaN(parseInt(l[0]))) {
                c.hasBattery = true
                c.percent = parseInt(l[0])
                c.status = l[1].trim()
            } else {
                c.hasBattery = false
            }
        }
    }

    // pulsation : même courbe que Rainmeter (période 5 s), à 10 images/s pour rester léger
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: c.phase += 2
    }

    Repeater {
        model: 20
        delegate: Rectangle {
            id: led
            required property int index
            readonly property real ang: (-90 + index * 18) * Math.PI / 180
            readonly property bool lit: c.acMode || c.percent >= (index + 1) * 5
            readonly property real alpha: (80 + 175 * (0.5 + 0.5 * Math.sin(c.phase * 0.0628 + index * 0.3141))) / 255

            x: 80 + 61 * Math.cos(ang) - 4.5
            y: 80 + 61 * Math.sin(ang) - 2
            width: 9
            height: 4
            radius: 2
            antialiasing: true
            color: lit ? Qt.rgba(c.activeColor.r, c.activeColor.g, c.activeColor.b, alpha)
                       : Qt.rgba(40 / 255, 40 / 255, 40 / 255, 1)
            border.width: 0.5
            border.color: Qt.rgba(1, 1, 1, 30 / 255)
        }
    }

    OText {
        visible: !c.acMode
        theme: c.theme
        ax: 80
        ay: 59
        pt: 29
        font.weight: Font.Bold
        text: c.percent + "%"
    }

    // éclair dessiné à la main (évite une dépendance à une police d'icônes)
    Canvas {
        id: bolt
        visible: c.acMode
        x: 62
        y: 57
        width: 36
        height: 40
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = "#ffffff"
            ctx.beginPath()
            ctx.moveTo(21, 0)
            ctx.lineTo(6, 22)
            ctx.lineTo(16, 22)
            ctx.lineTo(13, 40)
            ctx.lineTo(30, 16)
            ctx.lineTo(19, 16)
            ctx.closePath()
            ctx.fill()
        }
    }

    OText {
        theme: c.theme
        ax: 80
        ay: 105
        pt: 7
        muted: true
        color: c.acMode || c.critical ? (c.critical ? c.theme.accent : c.theme.muted) : c.activeColor
        text: c.statusText
    }
}
