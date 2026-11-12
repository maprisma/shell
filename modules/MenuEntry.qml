import QtQuick
import Quickshell.Widgets
import qs.services

// One row of a menu: an optional check mark (or a leading glyph) and icon, the label, and
// an arrow for a submenu. Hover tints it with the theme's primary colour.
Item {
    id: e

    property string label: ""
    property string icon: ""
    property string lead: ""
    property bool active: true
    property bool submenu: false
    property bool checkable: false
    property bool checked: false
    property color tint: Settings.text
    signal activated()

    height: 34
    implicitWidth: content.implicitWidth + 24 + (submenu ? 20 : 0)

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Settings.primary
        opacity: mouse.containsMouse && e.active ? 0.16 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Row {
        id: content
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Text {
            visible: e.checkable || e.lead !== ""
            width: 16
            text: e.lead !== "" ? e.lead : e.checked ? "✓" : ""
            color: Settings.primary
            font.family: e.lead !== "" ? Settings.font : ""
            font.pixelSize: 15
            anchors.verticalCenter: parent.verticalCenter
        }
        IconImage {
            visible: e.icon !== ""
            implicitSize: 16
            source: e.icon
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            // DBusMenu mnemonics: "_" marks the access key, "__" is a literal underscore.
            text: e.label.replace(/__/g, "\u0000").replace(/_/g, "").replace(/\u0000/g, "_")
            color: e.active ? e.tint : Settings.dim
            opacity: e.active ? 1 : 0.6
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Text {
        visible: e.submenu
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: "›"
        color: Settings.dim
        font.pixelSize: 16
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: e.active
        cursorShape: Qt.PointingHandCursor
        onClicked: e.activated()
    }
}
