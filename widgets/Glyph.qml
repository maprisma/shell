import QtQuick
import qs.services

// A bar widget drawn as one Nerd Font glyph (or a short text). The slot around
// it calls clicked(button, x, y) and wheel(event); ghostText is what the
// dragged copy shows.
Item {
    id: root

    property string text: ""
    property color color: Settings.text
    property int pixelSize: 15
    property real padding: 9
    property bool bold: false
    readonly property string ghostText: text
    readonly property string ghostIcon: ""
    // The name in the hover tooltip (Slot); empty = no tooltip.
    property string tipText: ""

    signal clicked(int button, real x, real y)
    signal wheel(var event)

    implicitWidth: label.implicitWidth + padding * 2
    implicitHeight: Settings.height

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.color
        font.family: Settings.font
        font.pixelSize: root.pixelSize
        font.bold: root.bold
    }
}
