import QtQuick
import Quickshell
import qs.services

// Left: Maprisma Launcher (shows or hides it). Right: the app launcher (fuzzel).
Glyph {
    text: "󰣇"
    color: Settings.primary
    pixelSize: 16
    onClicked: (button) => {
        if (button === Qt.RightButton)
            Actions.launcher()
        else
            Quickshell.execDetached([Settings.home + "/.local/bin/maprisma-launcher", "--toggle"])
    }
}
