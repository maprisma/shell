import QtQuick
import Quickshell
import qs.services

// Caelestia's session menu (lock, log out, restart, shut down).
Glyph {
    text: "󰐥"
    color: Settings.error
    onClicked: Quickshell.execDetached(["caelestia", "shell", "drawers", "toggle", "session"])
}
