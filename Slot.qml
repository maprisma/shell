import QtQuick
import Quickshell.Services.SystemTray
import qs.services
import qs.widgets

// One entry of the bar: its widget plus the mouse. A press and a move of more
// than a few pixels starts a drag (the bar draws the separator and the
// ghost); otherwise the click and the wheel go to the widget.
Item {
    id: slot

    required property var modelData
    property var host
    readonly property bool isSlot: true
    readonly property string key: modelData.key
    readonly property var widget: loader.item

    visible: !modelData.hidden
    width: visible && widget ? widget.implicitWidth : 0
    height: Settings.height
    opacity: host && host.dragKey === key ? 0.3 : 1

    function trayItem(id) {
        var items = host ? host.trayItems : []
        for (var i = 0; i < items.length; i++)
            if (items[i].key === id) return items[i].item
        return null
    }

    Loader {
        id: loader
        anchors.fill: parent
        active: !slot.modelData.hidden
        sourceComponent: {
            if (slot.modelData.kind === "tray") return tray
            switch (slot.modelData.id) {
            case "launcher": return launcher
            case "workspaces": return workspaces
            case "clock": return clock
            case "bluetooth": return bluetooth
            case "network": return network
            case "audio": return audio
            case "power": return power
            }
            return null
        }
    }

    Component { id: launcher; Launcher {} }
    Component { id: workspaces; Workspaces { screen: slot.host ? slot.host.screen : null } }
    Component { id: clock; Clock {} }
    Component { id: bluetooth; Bluetooth {} }
    Component { id: network; Network {} }
    Component { id: audio; Audio {} }
    Component { id: power; Power {} }
    Component { id: tray; TrayIcon { item: slot.trayItem(slot.modelData.id); window: slot.host } }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        property point start
        property bool dragging: false
        property bool dragged: false

        onPressed: (mouse) => {
            start = Qt.point(mouse.x, mouse.y)
            dragging = false
            dragged = false
        }
        onPositionChanged: (mouse) => {
            if (!pressed || !(mouse.buttons & Qt.LeftButton) || !slot.host) return
            var p = mapToItem(slot.host.contentItem, mouse.x, mouse.y)
            if (!dragging && (Math.abs(mouse.x - start.x) > 6 || Math.abs(mouse.y - start.y) > 6)) {
                dragging = true
                dragged = true
                slot.host.beginDrag(slot, p)
            }
            if (dragging) slot.host.moveDrag(p)
        }
        onReleased: (mouse) => {
            if (dragging) {
                dragging = false
                slot.host.endDrag()
            }
        }
        onCanceled: {
            if (dragging) {
                dragging = false
                slot.host.cancelDrag()
            }
        }
        onClicked: (mouse) => {
            if (dragged || !slot.widget) return
            slot.widget.clicked(mouse.button, mouse.x, mouse.y)
        }
        onWheel: (wheel) => {
            if (slot.widget) slot.widget.wheel(wheel)
        }
    }
}
