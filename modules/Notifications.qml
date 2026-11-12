import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.services

// The notification server, and its popups at the top right of the focused screen.
// A popup goes after its timeout (5 s, critical ones stay); click: its default action;
// ✕ or a right-click dismisses it. `clear()` dismisses all (IPC: shell clearNotifs).
Scope {
    id: root

    property bool doNotDisturb: false
    readonly property var list: server.trackedNotifications.values

    function clear() {
        var all = root.list.slice()
        for (var i = 0; i < all.length; i++) all[i].dismiss()
    }

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
        }
    }

    PanelWindow {
        id: win

        visible: column.children.length > 1 && !root.doNotDisturb
        screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
        anchors {
            top: true
            right: true
        }
        margins.top: Settings.height + 6
        margins.right: 8
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
                model: root.list

                Rectangle {
                    id: card
                    required property var modelData
                    readonly property var n: modelData
                    readonly property bool critical: n.urgency === NotificationUrgency.Critical
                    readonly property string image: n.image || ""
                    readonly property string icon: n.appIcon ? Quickshell.iconPath(n.appIcon, true) : ""

                    width: column.width
                    height: body.implicitHeight + 24
                    radius: Settings.radius
                    color: Settings.surfaceContainer
                    border.color: critical ? Settings.error : Qt.alpha(Settings.text, 0.1)
                    border.width: 1

                    Timer {
                        running: !card.critical && !area.containsMouse
                        interval: card.n.expireTimeout > 0 ? card.n.expireTimeout : 5000
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
