import QtQuick
import Quickshell
import qs.services

// The session menu (lock, suspend, log out, restart, shut down).
Glyph {
    text: "󰐥"
    color: Settings.error
    onClicked: Actions.session()
}
