// Météo : icône, température, état du ciel. Source : Open-Meteo (sans clé API).
// La ville (latitude / longitude) se choisit dans le Control Center.
import QtQuick

OrbitCircle {
    id: c

    title: ""
    accentY: -1

    readonly property string lat: (theme && theme.shared && theme.shared.latitude) ? String(theme.shared.latitude) : ""
    readonly property string lon: (theme && theme.shared && theme.shared.longitude) ? String(theme.shared.longitude) : ""

    property real temp: NaN
    property int code: -1
    property bool day: true
    property bool failed: false

    // codes météo WMO -> symbole (police DejaVu Sans / symboles) et libellé sans accents
    readonly property string glyph: {
        var k = code
        if (k < 0) return "≈"
        if (k === 0) return day ? "☀" : "☽"
        if (k === 1 || k === 2) return day ? "⛅" : "☽"
        if (k === 3) return "☁"
        if (k === 45 || k === 48) return "≈"
        if (k >= 51 && k <= 67) return "☔"
        if ((k >= 71 && k <= 77) || k === 85 || k === 86) return "❄"
        if (k >= 80 && k <= 82) return "☔"
        if (k >= 95) return "⛈"
        return "☁"
    }

    readonly property string label: {
        if (lat === "" || lon === "") return "VILLE ?"
        if (failed && code < 0) return "HORS LIGNE"
        var k = code
        if (k < 0) return "..."
        if (k === 0) return day ? "ENSOLEILLE" : "CIEL DEGAGE"
        if (k === 1) return "PEU NUAGEUX"
        if (k === 2) return "NUAGEUX"
        if (k === 3) return "COUVERT"
        if (k === 45 || k === 48) return "BROUILLARD"
        if (k >= 51 && k <= 55) return "BRUINE"
        if (k === 56 || k === 57 || k === 66 || k === 67) return "VERGLAS"
        if (k >= 61 && k <= 65) return "PLUIE"
        if (k >= 71 && k <= 77) return "NEIGE"
        if (k >= 80 && k <= 82) return "AVERSES"
        if (k === 85 || k === 86) return "AVERSES NEIGE"
        if (k >= 95) return "ORAGE"
        return "VARIABLE"
    }

    function refresh() {
        if (lat === "" || lon === "")
            return
        var x = new XMLHttpRequest()
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE)
                return
            if (x.status === 200) {
                try {
                    var cur = JSON.parse(x.responseText).current
                    c.temp = cur.temperature_2m
                    c.code = cur.weather_code
                    c.day = cur.is_day === 1
                    c.failed = false
                } catch (e) {
                    c.failed = true
                }
            } else {
                c.failed = true
            }
        }
        x.open("GET", "https://api.open-meteo.com/v1/forecast?latitude=" + encodeURIComponent(lat)
               + "&longitude=" + encodeURIComponent(lon)
               + "&current=temperature_2m,weather_code,is_day&timezone=auto")
        x.send()
    }

    onLatChanged: refresh()
    onLonChanged: refresh()

    Timer {
        interval: 900000        // 15 min
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: c.refresh()
    }

    OText {
        theme: c.theme
        ax: 80
        ay: -10
        pt: 48
        fontOverride: "DejaVu Sans"
        color: c.theme.accent
        text: c.glyph
    }

    OText {
        theme: c.theme
        ax: 80
        ay: 62
        pt: 32
        text: isNaN(c.temp) ? "--°C" : Math.round(c.temp) + "°C"
    }

    OText {
        theme: c.theme
        ax: 80
        ay: 115
        pt: 12
        width: 140
        elide: Text.ElideRight
        muted: true
        text: c.label
    }
}
