import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.services

// The default output: left opens the mixer, right mutes, the wheel sets the volume.
Glyph {
    tipText: "Volume"
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: !!(sink && sink.audio && sink.audio.muted)
    text: muted ? "󰝟" : volume < 0.34 ? "󰕿" : volume < 0.67 ? "󰖀" : "󰕾"
    color: muted ? Settings.dim : Settings.text

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    onClicked: (button) => {
        if (button === Qt.RightButton) {
            if (root.sink && root.sink.audio) root.sink.audio.muted = !root.muted
        } else if (button === Qt.LeftButton) {
            // A second click closes the mixer again, like a popup.
            Quickshell.execDetached(["sh", "-c", "pkill -x pwvucontrol || exec pwvucontrol"])
        }
    }
    onWheel: (event) => {
        if (!root.sink || !root.sink.audio) return
        var step = event.angleDelta.y > 0 ? 0.05 : -0.05
        root.sink.audio.muted = false
        root.sink.audio.volume = Math.max(0, Math.min(1, root.volume + step))
    }
}
