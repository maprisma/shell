import QtQuick
import Quickshell
import qs.services

// A tray item's menu in the theme's colours (instead of Qt's white widget menu), under its
// icon. Submenus open in place with a Back row. A click outside or Escape closes it; so
// does a second click on the icon (it lands outside the menu).
Overlay {
    id: root

    property var item: null      // the SystemTrayItem whose menu is open
    property var stack: []       // the submenus opened below the item's menu
    property real atX: 0         // the icon's centre on this screen
    readonly property var handle: stack.length ? stack[stack.length - 1] : (item ? item.menu : null)

    function show(trayItem, x) {
        item = trayItem
        stack = []
        atX = x
        open = true
    }

    function close() {
        open = false
        item = null
        stack = []
    }

    onDismissed: close()

    QsMenuOpener {
        id: opener
        menu: root.handle
    }

    Rectangle {
        id: card

        readonly property real need: {
            var w = 0
            for (var i = 0; i < rows.count; i++) {
                var r = rows.itemAt(i)
                if (r) w = Math.max(w, r.implicitWidth)
            }
            return w
        }

        width: Math.max(200, need) + 12
        height: column.implicitHeight + 12
        x: Math.max(8, Math.min(parent.width - width - 8, root.atX - width / 2))
        y: Settings.height + 6
        radius: Settings.radius
        color: Settings.surfaceContainer
        border.color: Qt.alpha(Settings.text, 0.1)
        border.width: 1

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column
            x: 6
            y: 6
            width: card.width - 12

            MenuEntry {
                visible: root.stack.length > 0
                width: column.width
                label: "Back"
                lead: "‹"
                onActivated: root.stack = root.stack.slice(0, -1)
            }

            Repeater {
                id: rows
                model: opener.children

                Item {
                    id: row
                    required property var modelData
                    readonly property bool separator: modelData.isSeparator
                    width: column.width
                    height: separator ? 9 : entry.height
                    implicitWidth: separator ? 0 : entry.implicitWidth

                    Rectangle {
                        visible: row.separator
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: Qt.alpha(Settings.text, 0.12)
                    }

                    MenuEntry {
                        id: entry
                        visible: !row.separator
                        width: parent.width
                        label: row.modelData.text
                        icon: row.modelData.icon
                        active: row.modelData.enabled
                        submenu: row.modelData.hasChildren
                        checkable: row.modelData.buttonType !== QsMenuButtonType.None
                        checked: row.modelData.checkState === Qt.Checked
                        onActivated: {
                            if (row.modelData.hasChildren) {
                                root.stack = root.stack.concat([row.modelData])
                            } else {
                                row.modelData.triggered()
                                root.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
