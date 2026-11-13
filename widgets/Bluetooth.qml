import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.services

// Off, on, or connected; a click opens Maprisma Bluetooth Monitor.
Glyph {
    tipText: "Bluetooth"
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: !!(adapter && adapter.enabled)
    readonly property bool connected: on && Bluetooth.devices.values.some(d => d.connected)
    text: !on ? "󰂲" : connected ? "󰂱" : "󰂯"
    color: on ? Settings.text : Settings.dim
    onClicked: (button) => {
        if (button === Qt.LeftButton)
            Quickshell.execDetached([Settings.home + "/.local/bin/maprisma-bluetooth-monitor", "--window"])
    }
}
