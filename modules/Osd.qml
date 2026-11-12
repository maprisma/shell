import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs.services

// A small card at the bottom of the focused screen when the volume or the brightness
// changes (keys, the bar's wheel, any mixer). Brightness goes through brightnessctl, so it
// works where there is a backlight (laptops); `brightness(+5)` is the IPC entry.
Scope {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: !!(sink && sink.audio && sink.audio.muted)

    property string kind: "volume"
    property real value: 0
    property bool ready: false   // no card for the values read at start

    function show(k, v) {
        if (!ready) return
        kind = k
        value = Math.max(0, Math.min(1, v))
        win.visible = true
        hide.restart()
    }

    function brightness(step) {
        bright.command = ["sh", "-c", "brightnessctl -q set " + (step >= 0 ? step + "%+" : (-step) + "%-")
            + " && brightnessctl -m | cut -d, -f4 | tr -d %"]
        bright.running = true
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Timer {
        running: true
        interval: 1500
        onTriggered: root.ready = true
    }

    onVolumeChanged: show("volume", volume)
    onMutedChanged: show("volume", volume)

    Process {
        id: bright
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(text)
                if (!isNaN(v)) root.show("brightness", v / 100)
            }
        }
    }

    Timer {
        id: hide
        interval: 1500
        onTriggered: win.visible = false
    }

    PanelWindow {
        id: win
        visible: false
        screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
        anchors.bottom: true
        margins.bottom: 80
        implicitWidth: 280
        implicitHeight: 52
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "maprisma-shell-osd"
        WlrLayershell.layer: WlrLayer.Overlay

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Settings.surfaceContainer
            border.color: Qt.alpha(Settings.text, 0.1)
            border.width: 1

            Text {
                id: glyph
                x: 18
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                text: root.kind === "brightness" ? "󰃠"
                    : root.muted ? "󰝟" : root.value < 0.34 ? "󰕿" : root.value < 0.67 ? "󰖀" : "󰕾"
                color: Settings.primary
                font.family: Settings.font
                font.pixelSize: 20
            }

            Rectangle {
                id: track
                anchors.left: glyph.right
                anchors.leftMargin: 10
                anchors.right: pct.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: 3
                color: Qt.alpha(Settings.text, 0.15)

                Rectangle {
                    width: parent.width * root.value
                    height: parent.height
                    radius: 3
                    color: root.kind === "volume" && root.muted ? Settings.dim : Settings.primary
                    Behavior on width { NumberAnimation { duration: 80 } }
                }
            }

            Text {
                id: pct
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                horizontalAlignment: Text.AlignRight
                text: Math.round(root.value * 100)
                color: Settings.text
                font.pixelSize: 13
            }
        }
    }
}
