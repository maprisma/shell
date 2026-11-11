import QtQuick
import Quickshell
import qs.services

// Left: Maprisma Launcher (shows or hides it). Right: Caelestia's app launcher.
Glyph {
    text: "󰣇"
    color: Settings.primary
    pixelSize: 16
    onClicked: (button) => {
        if (button === Qt.RightButton)
            Quickshell.execDetached(["caelestia", "shell", "drawers", "toggle", "launcher"])
        else
            Quickshell.execDetached([Settings.home + "/.local/bin/maprisma-launcher", "--toggle"])
    }
}
