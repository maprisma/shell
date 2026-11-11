pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../BarModel.js" as M

// bar.json (layout and background) and the colours, both followed live.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/maprisma-bar"
    readonly property string configPath: configDir + "/bar.json"
    readonly property string schemePath: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/caelestia/scheme.json"

    property var layout: M.normalize(null)
    readonly property string background: layout.background

    // Caelestia's scheme; these are its dark defaults until the file is read.
    property color surface: "#0a0f0f"
    property color surfaceContainer: "#131b1a"
    property color text: "#dce8e6"
    property color dim: "#a2adac"
    property color primary: "#9bd0cc"
    property color error: "#fa746f"

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int height: 30

    function save(cfg) {
        root.layout = M.normalize(cfg)
        file.setText(JSON.stringify(root.layout, null, 2) + "\n")
    }

    function cycleBackground() {
        var cfg = JSON.parse(JSON.stringify(root.layout))
        cfg.background = M.nextBackground(root.layout.background)
        save(cfg)
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.configDir]
    }

    FileView {
        id: file
        path: root.configPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.layout = M.normalize(M.parse(text()))
        onLoadFailed: root.layout = M.normalize(null)
    }

    FileView {
        path: root.schemePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            var scheme = M.parse(text())
            var c = scheme && scheme.colours
            if (!c) return
            function hex(name, fallback) {
                return /^[0-9a-fA-F]{6}$/.test(c[name] || "") ? "#" + c[name] : fallback
            }
            root.surface = hex("surface", root.surface)
            root.surfaceContainer = hex("surfaceContainer", root.surfaceContainer)
            root.text = hex("onSurface", root.text)
            root.dim = hex("onSurfaceVariant", root.dim)
            root.primary = hex("primary", root.primary)
            root.error = hex("error", root.error)
        }
    }
}
