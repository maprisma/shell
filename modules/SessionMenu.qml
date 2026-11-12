import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Lock, suspend, log out, restart, shut down: a row of buttons in the middle of the screen,
// the rest dimmed. Arrow keys move, Enter picks, Escape or a click outside closes.
Overlay {
    id: root

    required property var lock
    dim: true
    onDismissed: open = false

    readonly property var actions: [
        { glyph: "󰌾", label: "Lock", run: () => root.lock.lock() },
        { glyph: "󰤄", label: "Suspend", run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { glyph: "󰍃", label: "Log out", run: () => Hyprland.dispatch("hl.dsp.exit()") },
        { glyph: "󰜉", label: "Restart", run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { glyph: "󰐥", label: "Shut down", run: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
    ]
    property int current: 0

    function pick(i) {
        open = false
        actions[i].run()
    }

    onOpenChanged: {
        if (!open) return
        current = 0
        Qt.callLater(() => card.forceActiveFocus())
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: buttons.implicitWidth + 32
        height: buttons.implicitHeight + 32
        radius: Settings.radius + 8
        color: Settings.surfaceContainer
        border.color: Qt.alpha(Settings.text, 0.1)
        border.width: 1
        Keys.onLeftPressed: root.current = (root.current + root.actions.length - 1) % root.actions.length
        Keys.onRightPressed: root.current = (root.current + 1) % root.actions.length
        Keys.onReturnPressed: root.pick(root.current)
        Keys.onEnterPressed: root.pick(root.current)
        Keys.onEscapePressed: root.open = false

        MouseArea {
            anchors.fill: parent
        }

        Row {
            id: buttons
            anchors.centerIn: parent
            spacing: 12

            Repeater {
                model: root.actions

                Rectangle {
                    id: button
                    required property var modelData
                    required property int index
                    readonly property bool hot: root.current === index
                    width: 96
                    height: 104
                    radius: Settings.radius
                    color: hot ? Qt.alpha(Settings.primary, 0.18) : Settings.surfaceContainerHigh
                    border.color: hot ? Settings.primary : "transparent"
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 10
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: button.modelData.glyph
                            color: button.index === root.actions.length - 1 ? Settings.error : Settings.primary
                            font.family: Settings.font
                            font.pixelSize: 30
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: button.modelData.label
                            color: Settings.text
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.current = button.index
                        onClicked: root.pick(button.index)
                    }
                }
            }
        }
    }
}
