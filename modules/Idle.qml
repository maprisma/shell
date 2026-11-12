import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris

// Idle: lock, then the screens off, then suspend (shell.json "idle", seconds; 0 = never).
// While media plays nothing happens unless "whilePlaying" is true; apps that inhibit idle
// (a video player, a browser in full screen) are respected.
Scope {
    id: root

    required property var lock
    property var idle: ({ lock: 180, screenOff: 300, suspend: 600, whilePlaying: false })
    readonly property bool playing: Mpris.players.values.some(p => p.isPlaying)
    readonly property bool active: idle.whilePlaying || !playing

    IdleMonitor {
        enabled: root.active && root.idle.lock > 0
        timeout: Math.max(1, root.idle.lock)
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.lock.lock()
    }

    IdleMonitor {
        enabled: root.active && root.idle.screenOff > 0
        timeout: Math.max(1, root.idle.screenOff)
        respectInhibitors: true
        onIsIdleChanged: Hyprland.dispatch("hl.dsp.dpms({ action = \"" + (isIdle ? "disable" : "enable") + "\" })")
    }

    IdleMonitor {
        enabled: root.active && root.idle.suspend > 0
        timeout: Math.max(1, root.idle.suspend)
        respectInhibitors: true
        onIsIdleChanged: {
            if (!isIdle) return
            if (root.idle.lock > 0) root.lock.lock()
            Quickshell.execDetached(["systemctl", "suspend"])
        }
    }
}
