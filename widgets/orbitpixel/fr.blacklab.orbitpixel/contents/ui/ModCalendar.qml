// Calendrier : mois, jour, lettres L M M J V S D avec repère du jour, année.
import QtQuick

OrbitCircle {
    id: c

    readonly property var months: ["JANVIER", "FEVRIER", "MARS", "AVRIL", "MAI", "JUIN",
                                   "JUILLET", "AOUT", "SEPTEMBRE", "OCTOBRE", "NOVEMBRE", "DECEMBRE"]
    readonly property var letters: ["L", "M", "M", "J", "V", "S", "D"]

    title: ""          // le titre est le mois, géré plus bas
    accentY: -1        // pas de ligne d'accent sur ce module

    property string month: ""
    property int day: 1
    property int dow: 0      // 0 = lundi
    property int year: 2000

    function tick() {
        var d = new Date()
        month = months[d.getMonth()]
        day = d.getDate()
        dow = (d.getDay() + 6) % 7
        year = d.getFullYear()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: c.tick()
    }

    OText { theme: c.theme; ax: 80; ay: 20; pt: 9; muted: true; text: c.month }
    OText { theme: c.theme; ax: 80; ay: 40; pt: 54; text: String(c.day) }

    Repeater {
        model: 7
        delegate: OText {
            required property int index
            theme: c.theme
            ax: 24.5 + index * 19
            ay: 115
            pt: 9
            muted: true
            text: c.letters[index]
        }
    }

    Rectangle {
        x: 22 + c.dow * 19
        y: 130
        width: 5
        height: 2
        color: c.theme.accent
    }

    OText {
        theme: c.theme
        ax: 80
        ay: 133
        pt: 14
        text: String(c.year)
        opacity: 40 / 255
    }
}
