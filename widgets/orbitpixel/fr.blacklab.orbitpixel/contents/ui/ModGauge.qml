// Jauges texte : CPU, RAM, GPU (valeur en % au centre).
import QtQuick

OrbitCircle {
    id: c

    title: modId.toUpperCase()
    titleY: 25
    accentY: 45

    property real value: -1
    property var samples: []
    property real lastTotal: 0
    property real lastIdle: 0

    readonly property string cmd: modId === "cpu" ? "head -n1 /proc/stat"
        : modId === "ram" ? "awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{print t, a}' /proc/meminfo"
        : "v=$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -n1); [ -z \"$v\" ] && v=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1); echo \"$v\""

    // CPU : moyenne glissante sur 10 mesures (AverageSize=10 dans la version Rainmeter)
    function pushAvg(v) {
        var s = samples.slice(-9)
        s.push(v)
        samples = s
        var sum = 0
        for (var i = 0; i < s.length; i++)
            sum += s[i]
        value = sum / s.length
    }

    Poll {
        command: c.cmd
        interval: 1000
        onOutput: (text) => {
            var t = text.trim()
            if (t === "") {
                c.value = -1
                return
            }
            if (c.modId === "cpu") {
                // user nice system idle iowait irq softirq steal (guest déjà inclus dans user)
                var p = t.split(/\s+/).slice(1, 9).map(Number)
                if (p.length < 4)
                    return
                var idle = p[3] + (p[4] || 0)
                var total = p.reduce(function (a, b) { return a + b }, 0)
                if (c.lastTotal > 0 && total > c.lastTotal)
                    c.pushAvg(100 * (1 - (idle - c.lastIdle) / (total - c.lastTotal)))
                c.lastTotal = total
                c.lastIdle = idle
            } else if (c.modId === "ram") {
                var q = t.split(/\s+/).map(Number)
                if (q.length >= 2 && q[0] > 0)
                    c.value = 100 * (q[0] - q[1]) / q[0]
            } else {
                var g = parseFloat(t)
                c.value = isNaN(g) ? -1 : g
            }
        }
    }

    OText {
        theme: c.theme
        ax: 80
        ay: 60
        pt: 44
        text: c.value < 0 ? "--%" : Math.round(c.value) + "%"
    }
}
