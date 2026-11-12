import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.services
import "../NotifyModel.js" as N

// The notification server, and its popups on the focused screen. shell.json
// "notifications" (Settings.notifications) sets do not disturb, where the popups sit,
// how long a normal one stays (critical ones stay until dismissed) and how many show at
// once (the oldest leave first; they stay tracked). Click: the default action; ✕ or a
// right-click dismisses it. `clear()` dismisses all (IPC: shell clearNotifs).
// While do not disturb is on nothing pops up, but every notification is still received
// and tracked (Maprisma Notifier records them from the bus).
Scope {
    id: root

    readonly property var cfg: Settings.notifications
    readonly property bool doNotDisturb: cfg.dnd
    readonly property var list: server.trackedNotifications.values
    // The notifications shown as popups, oldest first.
    property var popups: []

    function setDnd(on) { return Settings.setDnd(on) }
    function toggleDnd() { return Settings.setDnd(!root.doNotDisturb) }

    function clear() {
        var all = root.list.slice()
        for (var i = 0; i < all.length; i++) all[i].dismiss()
        root.popups = []
    }

    function show(n) {
        root.popups = N.push(root.popups, n, root.cfg.max).shown
        n.closed.connect(() => root.popups = N.remove(root.popups, n))
    }

    // Do not disturb clears what is up; a smaller max trims the oldest.
    onDoNotDisturbChanged: if (doNotDisturb) root.popups = []
    onCfgChanged: root.popups = N.trim(root.popups, root.cfg.max).shown

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: (n) => {
            n.tracked = true
            if (!root.doNotDisturb) root.show(n)
        }
    }

    PanelWindow {
        id: win

        readonly property var place: N.placement(root.cfg.position, Settings.height)

        visible: root.popups.length > 0 && !root.doNotDisturb
        screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
        anchors {
            top: place.top
            bottom: place.bottom
            left: place.left
            right: place.right
        }
        margins.top: place.marginTop
        margins.bottom: place.marginBottom
        margins.left: place.marginLeft
        margins.right: place.marginRight
        implicitWidth: 380
        implicitHeight: Math.max(1, column.implicitHeight)
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "maprisma-shell-notifications"
        WlrLayershell.layer: WlrLayer.Overlay

        Column {
            id: column
            width: parent.width
            spacing: 8

            Repeater {
                // The tracked notifications themselves (a stable model: a new one arriving
                // doesn't rebuild the others and restart their timers); shown: the popups.
                model: server.trackedNotifications

                Rectangle {
                    id: card
                    required property var modelData
                    readonly property var n: modelData
                    readonly property bool critical: n.urgency === NotificationUrgency.Critical
                    readonly property string image: n.image || ""
                    readonly property string icon: n.appIcon ? Quickshell.iconPath(n.appIcon, true) : ""

                    visible: root.popups.indexOf(n) >= 0
                    width: column.width
                    height: body.implicitHeight + 24
                    radius: Settings.radius
                    color: Settings.surfaceContainer
                    border.color: critical ? Settings.error : Qt.alpha(Settings.text, 0.1)
                    border.width: 1

                    Timer {
                        running: card.visible && !card.critical && !area.containsMouse
                        interval: card.n.expireTimeout > 0 ? card.n.expireTimeout : root.cfg.timeout * 1000
                        onTriggered: card.n.expire()
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                var act = card.n.actions.find(a => a.identifier === "default")
                                if (act) act.invoke()
                            }
                            card.n.dismiss()
                        }
                    }

                    Row {
                        id: body
                        x: 12
                        y: 12
                        width: parent.width - 24
                        spacing: 12

                        IconImage {
                            visible: source !== ""
                            implicitSize: 40
                            source: card.image !== "" ? card.image : card.icon
                        }

                        Column {
                            width: body.width - (card.image !== "" || card.icon !== "" ? 52 : 0)
                            spacing: 4

                            Row {
                                width: parent.width
                                Text {
                                    width: parent.width - close.width
                                    text: card.n.appName || ""
                                    color: Settings.dim
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                                Text {
                                    id: close
                                    text: "✕"
                                    color: closeArea.containsMouse ? Settings.text : Settings.dim
                                    font.pixelSize: 13
                                    MouseArea {
                                        id: closeArea
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        hoverEnabled: true
                                        onClicked: card.n.dismiss()
                                    }
                                }
                            }
                            Text {
                                width: parent.width
                                text: card.n.summary
                                color: Settings.text
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: card.n.body
                                textFormat: Text.StyledText
                                color: Settings.dim
                                font.pixelSize: 13
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                            }
                            Flow {
                                width: parent.width
                                spacing: 6
                                visible: card.n.actions.some(a => a.identifier !== "default")
                                Repeater {
                                    model: card.n.actions.filter(a => a.identifier !== "default")
                                    Rectangle {
                                        required property var modelData
                                        width: label.implicitWidth + 20
                                        height: 28
                                        radius: 14
                                        color: actArea.containsMouse ? Qt.alpha(Settings.primary, 0.25) : Qt.alpha(Settings.primary, 0.12)
                                        Text {
                                            id: label
                                            anchors.centerIn: parent
                                            text: parent.modelData.text
                                            color: Settings.primary
                                            font.pixelSize: 13
                                        }
                                        MouseArea {
                                            id: actArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                parent.modelData.invoke()
                                                card.n.dismiss()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
