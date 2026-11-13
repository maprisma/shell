import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.services
import qs.modules
import "BarModel.js" as M

// The bar on one screen: left, centre and right zones from bar.json.
// Double-click empty space: clear → glassy → opaque. Drag a widget or a tray
// icon: a line shows where it lands; the order is saved in bar.json.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Settings.height
    color: "transparent"
    WlrLayershell.namespace: "maprisma-bar"
    // Overlay, not Top: another program's full-screen Top surface mapped after
    // the bar would take its clicks (the old Caelestia shell did).
    WlrLayershell.layer: WlrLayer.Overlay
    // Over a fullscreen window the bar is unmapped. Dropping it to Top was not
    // enough: Hyprland still draws Top layers over a fullscreen Chrome window
    // (MagentaTV PWA, HDR video), and an unmapped bar also lets the window
    // get direct scanout.
    visible: !fullscreen

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property bool fullscreen: {
        var ws = monitor ? monitor.activeWorkspace : null
        if (!ws) return false
        return ws.toplevels.values.some(t => t.lastIpcObject && t.lastIpcObject.fullscreen > 1)
    }

    // The tray items with unique keys (two copies of an app share an id).
    readonly property var trayItems: {
        var items = SystemTray.items.values
        var keys = M.uniqueIds(items.map(i => i.id))
        return items.map((item, n) => ({ key: keys[n], item: item }))
    }
    readonly property var trayKeys: trayItems.map(t => t.key)
    readonly property var shown: M.expand(Settings.layout, trayKeys)

    // The open tray menu (one per bar).
    readonly property var trayMenu: menuPopup
    TrayMenu {
        id: menuPopup
        screen: bar.screen
    }

    // The drag in progress.
    property string dragKey: ""
    property var dragTarget: null   // { zone, index, x }
    property point dragPoint
    property string ghostText: ""
    property string ghostIcon: ""

    function slots(row) {
        var out = []
        for (var i = 0; i < row.children.length; i++) {
            var c = row.children[i]
            if (c.isSlot && c.visible && c.key !== dragKey) out.push(c)
        }
        return out
    }

    // The zone whose row is nearest to x (an empty row sits at its anchor),
    // and the place among its widgets.
    function targetAt(p) {
        var rows = { left: leftRow, center: centerRow, right: rightRow }
        var best = null, bestDist = Infinity
        for (var zone in rows) {
            var row = rows[zone]
            var r = row.mapToItem(content, 0, 0)
            var lo = r.x, hi = r.x + row.width
            var dist = p.x < lo ? lo - p.x : p.x > hi ? p.x - hi : 0
            if (dist < bestDist) {
                bestDist = dist
                best = zone
            }
        }
        var row = rows[best]
        var list = slots(row)
        var index = 0
        for (var i = 0; i < list.length; i++) {
            var s = list[i].mapToItem(content, 0, 0)
            if (p.x > s.x + list[i].width / 2) index = i + 1
        }
        var x
        if (list.length === 0) {
            x = row.mapToItem(content, 0, 0).x
        } else if (index < list.length) {
            x = list[index].mapToItem(content, 0, 0).x
        } else {
            var last = list[list.length - 1]
            x = last.mapToItem(content, 0, 0).x + last.width
        }
        return { zone: best, index: index, x: x }
    }

    function beginDrag(slot, p) {
        dragKey = slot.key
        ghostText = slot.widget ? slot.widget.ghostText : ""
        ghostIcon = slot.widget ? slot.widget.ghostIcon : ""
        moveDrag(p)
    }

    function moveDrag(p) {
        dragPoint = p
        dragTarget = targetAt(p)
    }

    function endDrag() {
        var key = dragKey, t = dragTarget
        cancelDrag()
        if (!key || !t) return
        var next = M.move(Settings.layout, trayKeys, key, t.zone, t.index)
        if (JSON.stringify(next) !== JSON.stringify(Settings.layout)) Settings.save(next)
    }

    function cancelDrag() {
        dragKey = ""
        dragTarget = null
    }

    Item {
        id: content
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: Settings.surface
            opacity: Settings.background === "opaque" ? 1 : Settings.background === "glassy" ? 0.45 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }

        // Empty space: a double-click changes the background.
        MouseArea {
            anchors.fill: parent
            onDoubleClicked: Settings.cycleBackground()
        }

        Row {
            id: leftRow
            anchors.left: parent.left
            anchors.leftMargin: 6
            height: parent.height
            Repeater {
                model: bar.shown.left
                Slot { host: bar }
            }
        }

        Row {
            id: centerRow
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height
            Repeater {
                model: bar.shown.center
                Slot { host: bar }
            }
        }

        Row {
            id: rightRow
            anchors.right: parent.right
            anchors.rightMargin: 6
            height: parent.height
            Repeater {
                model: bar.shown.right
                Slot { host: bar }
            }
        }

        // Where the dragged widget lands.
        Rectangle {
            visible: bar.dragKey !== "" && bar.dragTarget !== null
            x: bar.dragTarget ? bar.dragTarget.x - width / 2 : 0
            y: 4
            width: 3
            height: parent.height - 8
            radius: 1.5
            color: Settings.primary
        }

        // The dragged widget under the pointer.
        Rectangle {
            visible: bar.dragKey !== ""
            x: Math.max(0, Math.min(parent.width - width, bar.dragPoint.x - width / 2))
            y: 3
            width: Math.max(26, ghostLabel.implicitWidth + 14)
            height: parent.height - 6
            radius: 6
            color: Settings.surfaceContainer
            border.color: Settings.primary
            border.width: 1
            opacity: 0.9

            Text {
                id: ghostLabel
                anchors.centerIn: parent
                visible: bar.ghostIcon === ""
                text: bar.ghostText
                color: Settings.text
                font.family: Settings.font
                font.pixelSize: 14
            }
            IconImage {
                anchors.centerIn: parent
                visible: bar.ghostIcon !== ""
                implicitSize: 16
                source: bar.ghostIcon
            }
        }
    }
}
