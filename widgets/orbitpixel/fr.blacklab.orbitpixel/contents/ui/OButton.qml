// Petit bouton au style Orbit.
import QtQuick

Rectangle {
    id: b

    property var theme
    property string label: ""
    property bool highlighted: false
    signal clicked()

    implicitWidth: Math.max(30, txt.implicitWidth + 22)
    implicitHeight: 28
    radius: 4
    color: ma.pressed ? Qt.rgba(1, 1, 1, 0.18) : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.04))
    border.width: 1
    border.color: highlighted && theme ? theme.accent : (theme ? theme.border : "#444444")

    OLabel {
        id: txt
        theme: b.theme
        anchors.centerIn: parent
        plain: true
        pt: 9
        text: b.label
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
