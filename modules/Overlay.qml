import QtQuick
import Quickshell
import Quickshell.Wayland

// A full-screen, see-through Overlay surface that holds one popup (a menu, the session
// menu). A click outside the popup or Escape closes it. One surface per popup instead of a
// Wayland popup: nothing else's layers or grabs can come between the pointer and the menu.
// Popup cards put a MouseArea under their content so clicks on them don't close them.
PanelWindow {
    id: root

    property bool open: false
    property bool dim: false     // darken the screen behind (the session menu)
    default property alias content: holder.data
    signal dismissed()

    visible: open
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "maprisma-shell-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: if (open) holder.forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.dim ? 0.45 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: root.dismissed()
    }

    Item {
        id: holder
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.dismissed()
    }
}
