//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.modules

// Maprisma Shell: the whole desktop shell of the Hyprland session in one Quickshell
// config: a bar per screen, wallpaper, notifications, volume/brightness card, lock screen,
// idle, session menu. Hyprland keys reach it as global shortcuts (maprisma:<name>), scripts
// through `qs -c maprisma-shell ipc call shell <name>`.
ShellRoot {
    id: shell

    Wallpaper {}

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Notifications {
        id: notifications
    }

    Osd {
        id: osd
    }

    Lock {
        id: locker
    }

    Idle {
        lock: locker
        idle: Settings.idle
    }

    SessionMenu {
        id: sessionMenu
        lock: locker
        screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
    }

    Connections {
        target: Actions
        function onSession() { sessionMenu.open = !sessionMenu.open }
        function onLauncher() { shell.launcher() }
    }

    function launcher() {
        Quickshell.execDetached(["sh", "-c", "pkill -x fuzzel || exec fuzzel"])
    }

    // Hyprland binds: hl.dsp.global("maprisma:<name>")
    component Key: GlobalShortcut {
        appid: "maprisma"
    }
    Key { name: "lock"; description: "Lock the screen"; onPressed: locker.lock() }
    Key { name: "session"; description: "Session menu"; onPressed: sessionMenu.open = !sessionMenu.open }
    Key { name: "clearNotifs"; description: "Dismiss all notifications"; onPressed: notifications.clear() }
    Key { name: "launcher"; description: "App launcher"; onPressed: shell.launcher() }
    Key { name: "brightnessUp"; description: "Brightness up"; onPressed: osd.brightness(5) }
    Key { name: "brightnessDown"; description: "Brightness down"; onPressed: osd.brightness(-5) }

    IpcHandler {
        target: "shell"
        function lock(): void { locker.lock() }
        function unlock(): void { locker.unlock() }
        function session(): void { sessionMenu.open = !sessionMenu.open }
        function clearNotifs(): void { notifications.clear() }
        // Do not disturb persists in shell.json notifications.dnd (Maprisma Notifier/Manager too).
        function doNotDisturb(): void { notifications.toggleDnd() }
        function setDnd(on: bool): void { notifications.setDnd(on) }
        function getDnd(): string { return Settings.notifications.dnd ? "true" : "false" }
        function launcher(): void { shell.launcher() }
        function brightness(step: int): void { osd.brightness(step) }
    }

    // Glassy needs Hyprland to blur behind the bar. The rule is set at start
    // and again after every config reload (a reload drops rules set at run time).
    Process {
        id: blurRule
        running: true
        command: ["hyprctl", "eval", "hl.layer_rule({ match = { namespace = \"^maprisma-bar$\" }, blur = true, ignore_alpha = 0.2 })"]
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") blurRule.running = true
            // The bar's fullscreen check reads each window's IPC state.
            if (["fullscreen", "openwindow", "closewindow", "movewindow", "workspace", "focusedmon"].includes(event.name)) {
                Hyprland.refreshToplevels()
                Hyprland.refreshWorkspaces()
            }
        }
    }
}
