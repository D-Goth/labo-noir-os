// Texte « façon Rainmeter » : position (ax, ay) dans le repère 160x160,
// taille en points Rainmeter (pt), alignement left | center | right.
import QtQuick

Text {
    id: t

    property var theme
    property real ax: 80
    property real ay: 0
    property real pt: 10
    property string align: "center"
    property bool muted: false
    property string fontOverride: ""

    x: align === "center" ? ax - width / 2 : (align === "right" ? ax - width : ax)
    y: ay

    color: theme ? (muted ? theme.muted : theme.text) : "white"
    font.family: fontOverride !== "" ? fontOverride : (theme ? theme.fontFamily : "sans-serif")
    font.pixelSize: Math.round(pt * 4 / 3)
    horizontalAlignment: align === "center" ? Text.AlignHCenter : (align === "right" ? Text.AlignRight : Text.AlignLeft)
    textFormat: Text.PlainText
    renderType: Text.QtRendering
    antialiasing: true
}
