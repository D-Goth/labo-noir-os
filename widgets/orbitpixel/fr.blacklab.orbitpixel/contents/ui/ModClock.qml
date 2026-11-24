// Horloge : un cercle par unité (clock-h, clock-m, clock-s).
import QtQuick

OrbitCircle {
    id: c

    readonly property string part: modId === "clock-h" ? "h" : (modId === "clock-m" ? "m" : "s")

    title: part === "h" ? "HEURES" : (part === "m" ? "MINUTES" : "SECONDES")
    titleY: 25
    accentY: 45

    property string value: "--"

    function tick() {
        var d = new Date()
        var n = part === "h" ? d.getHours() : (part === "m" ? d.getMinutes() : d.getSeconds())
        var s = (n < 10 ? "0" : "") + n
        if (s !== value)
            value = s
    }

    Timer {
        interval: c.part === "s" ? 250 : 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: c.tick()
    }

    OText {
        theme: c.theme
        ax: 80
        ay: 50
        pt: 64
        text: c.value
    }
}
