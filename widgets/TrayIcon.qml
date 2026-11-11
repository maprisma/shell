import QtQuick
import Quickshell
import Quickshell.Widgets
import QtQuick.Effects
import qs.services

// One tray icon (a StatusNotifierItem): left activates (or opens the menu of
// a menu-only item), middle is the secondary action, right opens the menu.
Item {
    id: root
    property var item
    property var window
    readonly property string ghostText: ""
    readonly property string ghostIcon: item ? item.icon : ""

    signal clicked(int button, real x, real y)
    signal wheel(var event)

    implicitWidth: 30
    implicitHeight: Settings.height

    function menu(x) {
        if (root.item && root.item.hasMenu) {
            var p = root.mapToItem(null, x, 0)
            root.item.display(root.window, p.x, Settings.height)
        }
    }

    onClicked: (button, x) => {
        if (!root.item) return
        if (button === Qt.RightButton || (button === Qt.LeftButton && root.item.onlyMenu))
            menu(x)
        else if (button === Qt.MiddleButton)
            root.item.secondaryActivate()
        else
            root.item.activate()
    }
    onWheel: (event) => {
        // The raw wheel delta (120 a notch), as other tray hosts send it.
        if (!root.item) return
        var horizontal = event.angleDelta.x !== 0 && event.angleDelta.y === 0
        var delta = horizontal ? event.angleDelta.x : event.angleDelta.y
        if (delta !== 0) root.item.scroll(delta, horizontal)
    }

    // Symbolic icons take the bar's text colour, as GTK draws them; others keep theirs.
    readonly property bool symbolic: !!(item && /-symbolic(\?|$)/.test(String(item.icon)))

    IconImage {
        id: icon
        anchors.centerIn: parent
        implicitSize: 16
        source: root.item ? root.item.icon : ""
        layer.enabled: root.symbolic
        layer.effect: MultiEffect {
            brightness: 1
            colorization: 1
            colorizationColor: Settings.text
        }
    }
}
