import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Left: Maprisma Launcher (shows or hides it). Right: the app launcher (fuzzel).
// White like every Maprisma bar icon; the theme accent while the Launcher window is
// open (the family's "on" colour, as TrayIcon draws -active-symbolic icons).
Glyph {
    tipText: "Maprisma Launcher"
    readonly property bool open: ToplevelManager.toplevels.values.some(t => t.appId === "com.maprisma.Launcher")
    text: "󰣇"
    color: open ? Settings.primary : Settings.text
    pixelSize: 16
    onClicked: (button) => {
        if (button === Qt.RightButton)
            Actions.launcher()
        else
            Quickshell.execDetached([Settings.home + "/.local/bin/maprisma-launcher", "--toggle"])
    }
}
