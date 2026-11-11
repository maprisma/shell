import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Wired, Wi-Fi strength or offline, from nmcli every 10 s; a click opens
// Maprisma WLAN Monitor, a right click the connection editor.
Glyph {
    id: root
    property string kind: "none"
    property int signal: 0
    text: kind === "ethernet" ? "󰈀" : kind === "wifi"
        ? (signal > 75 ? "󰤨" : signal > 50 ? "󰤥" : signal > 25 ? "󰤢" : "󰤟")
        : "󰤮"
    color: kind === "none" ? Settings.dim : Settings.text

    onClicked: (button) => {
        if (button === Qt.RightButton)
            Quickshell.execDetached(["nm-connection-editor"])
        else if (button === Qt.LeftButton)
            Quickshell.execDetached([Settings.home + "/.local/bin/maprisma-wlan-monitor", "--window"])
    }

    Process {
        id: devices
        command: ["nmcli", "-t", "-f", "TYPE,STATE", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                var wired = lines.some(l => l.indexOf("ethernet:connected") === 0)
                var wifi = lines.some(l => l.indexOf("wifi:connected") === 0)
                root.kind = wired ? "ethernet" : wifi ? "wifi" : "none"
                if (wifi && !wired) strength.running = true
            }
        }
    }
    Process {
        id: strength
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.split("\n").find(l => l.indexOf("*:") === 0)
                root.signal = line ? parseInt(line.slice(2)) || 0 : 0
            }
        }
    }
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: devices.running = true
    }
}
