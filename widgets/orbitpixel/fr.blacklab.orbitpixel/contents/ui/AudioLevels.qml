// Fournit les niveaux audio (dBFS par bande) calculés par scripts/orbit-audio.py.
// mode : "out" = sortie (haut-parleurs / oreillette), "in" = micro.
// Le démon sert les niveaux sur 127.0.0.1 (port aléatoire + jeton) : on les lit par requêtes HTTP
// ~25 fois/s, sans lancer de processus à chaque lecture (c'était ça, la latence).
import QtQuick

Item {
    id: al

    visible: false

    property string mode: "out"
    property var levels: []

    property int port: 0
    property string token: ""
    property bool busy: false
    property real busySince: 0

    readonly property string script: decodeURIComponent(Qt.resolvedUrl("../scripts/orbit-audio.py").toString().replace(/^file:\/\//, ""))

    // convertit des dBFS en 0..1 (sens = plage de dB, comme « Sensitivity » dans Rainmeter)
    function norm(i, sens) {
        var v = levels[i]
        if (v === undefined || isNaN(v))
            return 0
        return Math.max(0, Math.min(1, (v + sens) / sens))
    }

    // lance le démon s'il ne tourne pas (le verrou évite les doublons) et récupère port + jeton
    Poll {
        interval: al.port > 0 ? 5000 : 1000
        command: "setsid -f python3 '" + al.script + "' " + al.mode + " >/dev/null 2>&1; cat \"$XDG_RUNTIME_DIR/orbit-audio-" + al.mode + ".port\" 2>/dev/null"
        onOutput: (text) => {
            var p = text.trim().split(/\s+/)
            var n = parseInt(p[0])
            if (p.length >= 2 && n > 0) {
                al.port = n
                al.token = p[1]
            } else {
                al.port = 0
            }
        }
    }

    Timer {
        interval: 40
        repeat: true
        running: al.port > 0

        onTriggered: {
            if (al.busy) {
                if (Date.now() - al.busySince < 1000)
                    return
                al.busy = false      // requête restée bloquée : on abandonne
                al.port = 0
                return
            }
            al.busy = true
            al.busySince = Date.now()
            var x = new XMLHttpRequest()
            x.onreadystatechange = function () {
                if (x.readyState !== XMLHttpRequest.DONE)
                    return
                al.busy = false
                if (x.status === 200) {
                    var p = x.responseText.trim().split(/\s+/).map(parseFloat)
                    if (p.length > 0 && !isNaN(p[0]))
                        al.levels = p
                } else {
                    al.port = 0      // démon arrêté : on relance via le Poll
                }
            }
            x.open("GET", "http://127.0.0.1:" + al.port + "/" + al.token)
            x.send()
        }
    }
}
