//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Maprisma Bar: one bar per screen, next to Caelestia's shell.
ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
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
