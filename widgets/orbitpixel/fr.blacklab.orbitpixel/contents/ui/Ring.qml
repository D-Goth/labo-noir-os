// Jauge circulaire (équivalent du Roundline Rainmeter) : piste + arc de progression.
import QtQuick
import QtQuick.Shapes

Item {
    id: ring

    property real value: 0          // 0..100
    property color color: "#ff1654"
    property color trackColor: "#14ffffff"
    property real inner: 70
    property real outer: 76
    readonly property real mid: (inner + outer) / 2

    width: 160
    height: 160

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: ring.trackColor
            strokeWidth: ring.outer - ring.inner
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: 80
                centerY: 80
                radiusX: ring.mid
                radiusY: ring.mid
                startAngle: -90
                sweepAngle: 359.99
            }
        }

        ShapePath {
            strokeColor: ring.color
            strokeWidth: ring.outer - ring.inner
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: 80
                centerY: 80
                radiusX: ring.mid
                radiusY: ring.mid
                startAngle: -90
                sweepAngle: Math.max(0.01, Math.min(100, ring.value) * 3.5999)
            }
        }
    }
}
