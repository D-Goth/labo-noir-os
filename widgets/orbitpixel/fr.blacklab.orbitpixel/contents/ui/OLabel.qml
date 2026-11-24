// Texte pour les mises en page (Control Center) : contrairement à OText, il se laisse placer
// par les Layouts. plain = police système (accents), sinon la police pixel du thème.
import QtQuick

Text {
    property var theme
    property real pt: 10
    property bool muted: false
    property bool accent: false
    property bool plain: false

    color: theme ? (accent ? theme.accent : (muted ? theme.muted : theme.text)) : "white"
    font.family: (plain || !theme) ? Qt.application.font.family : theme.fontFamily
    font.pixelSize: Math.round(pt * 4 / 3)
    textFormat: Text.PlainText
    renderType: Text.QtRendering
}
