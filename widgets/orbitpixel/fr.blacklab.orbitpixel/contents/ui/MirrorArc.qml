// Deux demi-arcs symétriques qui partent du même point (bas ou haut) et montent chacun
// de value * 180° (équivalent des paires RingXLeft / RingXRight de Rainmeter).
import QtQuick
import QtQuick.Shapes

Item {
    id: arc

    property real value: 0          // 0..1
    property real mid: 67
    property real thickness: 2
    property color color: "#ff1654"
    property real startAngle: 90    // 90 = bas, 270 = haut

    readonly property real sweep: Math.max(0.01, Math.min(1, value) * 180)

    width: 160
    height: 160

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: arc.color
            strokeWidth: arc.thickness
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: 80
                centerY: 80
                radiusX: arc.mid
                radiusY: arc.mid
                startAngle: arc.startAngle
                sweepAngle: arc.sweep
            }
        }

        ShapePath {
            strokeColor: arc.color
            strokeWidth: arc.thickness
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: 80
                centerY: 80
                radiusX: arc.mid
                radiusY: arc.mid
                startAngle: arc.startAngle
                sweepAngle: -arc.sweep
            }
        }
    }
}
