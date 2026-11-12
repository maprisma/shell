pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../BarModel.js" as M
import "../NotifyModel.js" as N

// The shell's files, all followed live:
// - bar.json: the bar's layout and background (Maprisma Manager writes it too)
// - shell.json: idle timeouts, the wallpaper (by hand, or the wallpaper by Maprisma Theme) and
//   the notifications (do not disturb, popup position/timeout/max; Maprisma Notifier and
//   Manager write it too)
// - scheme.json (state): the colours Maprisma Theme writes
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || home + "/.local/state"
    readonly property string configDir: configHome + "/maprisma-shell"
    readonly property string stateDir: stateHome + "/maprisma-shell"
    readonly property string configPath: configDir + "/bar.json"
    readonly property string shellPath: configDir + "/shell.json"
    readonly property string schemePath: stateDir + "/scheme.json"

    property var layout: M.normalize(null)
    readonly property string background: layout.background

    // shell.json with its defaults.
    property var shell: defaults()
    readonly property string wallpaper: shell.wallpaper || ""
    readonly property var idle: shell.idle
    readonly property var notifications: shell.notifications

    function defaults() {
        return {
            wallpaper: "",
            idle: {
                lock: 180,          // seconds idle until the screen locks (0: never)
                screenOff: 300,     // until the screens turn off
                suspend: 600,       // until the computer suspends
                whilePlaying: false // idle while media plays
            },
            notifications: N.defaults()  // { dnd, position, timeout, max }
        }
    }

    // The colours; dark defaults until a scheme is read.
    property color surface: "#0a0f0f"
    property color surfaceContainer: "#131b1a"
    property color surfaceContainerHigh: "#1d2625"
    property color text: "#dce8e6"
    property color dim: "#a2adac"
    property color outline: "#6c7776"
    property color primary: "#9bd0cc"
    property color primaryText: "#00201e"   // scheme "onPrimary" (a property called onX would be a handler)
    property color error: "#fa746f"

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int height: 30
    readonly property int radius: 12

    function save(cfg) {
        root.layout = M.normalize(cfg)
        file.setText(JSON.stringify(root.layout, null, 2) + "\n")
    }

    function cycleBackground() {
        var cfg = JSON.parse(JSON.stringify(root.layout))
        cfg.background = M.nextBackground(root.layout.background)
        save(cfg)
    }

    function applyScheme(textValue) {
        var scheme = M.parse(textValue)
        var c = scheme && scheme.colours
        if (!c) return
        function hex(name, fallback) {
            return /^[0-9a-fA-F]{6}$/.test(c[name] || "") ? "#" + c[name] : fallback
        }
        root.surface = hex("surface", root.surface)
        root.surfaceContainer = hex("surfaceContainer", root.surfaceContainer)
        root.surfaceContainerHigh = hex("surfaceContainerHigh", root.surfaceContainerHigh)
        root.text = hex("onSurface", root.text)
        root.dim = hex("onSurfaceVariant", root.dim)
        root.outline = hex("outline", root.outline)
        root.primary = hex("primary", root.primary)
        root.primaryText = hex("onPrimary", root.primaryText)
        root.error = hex("error", root.error)
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.configDir, root.stateDir]
    }

    FileView {
        id: file
        path: root.configPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        // A file caught half written (an editor saving) keeps the last good layout.
        onLoaded: {
            var cfg = M.parse(text())
            if (cfg && typeof cfg === "object") root.layout = M.normalize(cfg)
        }
    }

    // Do not disturb lives in shell.json (the shell keeps nothing in memory only):
    // re-read the file, change notifications.dnd, keep every other key, write atomically.
    // A file that isn't valid JSON is left alone.
    function setDnd(on) {
        shellWriter.reload()
        var next = N.withDnd(shellWriter.text(), on === true)
        if (next === null) {
            console.warn("shell.json is not valid JSON; do not disturb not saved")
            return false
        }
        var s = JSON.parse(JSON.stringify(root.shell))
        s.notifications = N.normalize(JSON.parse(next))
        root.shell = s
        shellWriter.setText(next)
        return true
    }

    FileView {
        id: shellWriter
        path: root.shellPath
        blockAllReads: true
        atomicWrites: true
        printErrors: false
    }

    FileView {
        path: root.shellPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            var cfg = M.parse(text())
            var d = root.defaults()
            if (!cfg || typeof cfg !== "object") return
            var idle = cfg.idle && typeof cfg.idle === "object" ? cfg.idle : {}
            function num(v, fallback) {
                return typeof v === "number" && v >= 0 ? v : fallback
            }
            root.shell = {
                wallpaper: typeof cfg.wallpaper === "string" ? cfg.wallpaper : "",
                idle: {
                    lock: num(idle.lock, d.idle.lock),
                    screenOff: num(idle.screenOff, d.idle.screenOff),
                    suspend: num(idle.suspend, d.idle.suspend),
                    whilePlaying: idle.whilePlaying === true
                },
                notifications: N.normalize(cfg)
            }
        }
        onLoadFailed: root.shell = root.defaults()
    }

    FileView {
        path: root.schemePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.applyScheme(text())
    }
}
