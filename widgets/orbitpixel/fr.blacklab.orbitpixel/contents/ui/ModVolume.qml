// Volume : anneau + icône. Molette = volume, clic = muet. Nécessite PipeWire (wpctl).
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

OrbitCircle {
    id: c

    title: "VOLUME"
    titleY: 25
    accentY: 40

    property real vol: 0
    property bool muted: false

    Runner { id: runner }

    Poll {
        command: "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null"
        interval: 1000
        onOutput: (text) => {
            var m = /Volume:\s*([0-9.]+)/.exec(text)
            if (m) {
                c.vol = Math.round(parseFloat(m[1]) * 100)
                c.muted = text.indexOf("MUTED") >= 0
            }
        }
    }

    function change(delta) {
        vol = Math.max(0, Math.min(100, vol + delta))
        runner.run("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ " + Math.abs(delta) + "%" + (delta > 0 ? "+" : "-"))
    }

    function toggleMute() {
        muted = !muted
        runner.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
    }

    Ring {
        value: c.vol
        color: c.theme.accent
        trackColor: c.theme.track
        inner: 65
        outer: 70
    }

    Kirigami.Icon {
        x: 58
        y: 62
        width: 44
        height: 44
        isMask: true
        color: c.muted ? c.theme.accent : c.theme.text
        source: c.muted ? "audio-volume-muted-symbolic"
              : c.vol < 34 ? "audio-volume-low-symbolic"
              : c.vol < 67 ? "audio-volume-medium-symbolic"
              : "audio-volume-high-symbolic"
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: c.toggleMute()
        onWheel: (wheel) => c.change(wheel.angleDelta.y > 0 ? 2 : -2)

        QQC2.ToolTip.visible: containsMouse
        QQC2.ToolTip.delay: 600
        QQC2.ToolTip.text: "Molette : volume (" + c.vol + "%) · Clic : muet"
    }
}
