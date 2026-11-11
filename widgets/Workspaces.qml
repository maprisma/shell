import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// This monitor's workspaces in the group of ten that holds its active one
// (Caelestia's groups: 1-10, 11-20, …): five cells, more while a higher one
// exists. A click goes there, the wheel to the next or previous one.
Item {
    id: root
    property var screen
    readonly property string ghostText: "1 2 3"
    readonly property string ghostIcon: ""
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property int active: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1
    readonly property int base: active > 0 ? Math.floor((active - 1) / 10) * 10 : 0
    readonly property var used: Hyprland.workspaces.values
        .filter(w => w.id > base && w.id <= base + 10 && (!monitor || w.monitor === monitor))
        .map(w => w.id - base)
    readonly property int count: Math.max(5, Math.max.apply(null, used.concat([0])))
    readonly property real cell: 22

    signal clicked(int button, real x, real y)
    signal wheel(var event)

    implicitWidth: count * cell + 8
    implicitHeight: Settings.height

    function go(target) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + target + "\" })")
    }

    onClicked: (button, x) => {
        if (button !== Qt.LeftButton) return
        var n = Math.floor((x - 4) / cell) + 1
        if (n >= 1 && n <= count) go(String(root.base + n))
    }
    onWheel: (event) => go(event.angleDelta.y > 0 ? "m-1" : "m+1")

    Row {
        anchors.centerIn: parent
        Repeater {
            model: root.count
            Text {
                required property int index
                readonly property int number: index + 1
                width: root.cell
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                text: number
                font.family: Settings.font
                font.pixelSize: 13
                font.bold: root.base + number === root.active
                color: root.base + number === root.active ? Settings.primary : Settings.dim
                opacity: root.base + number === root.active || root.used.indexOf(number) >= 0 ? 1 : 0.5
            }
        }
    }
}
