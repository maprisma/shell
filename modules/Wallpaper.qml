import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// The wallpaper on every screen (Background layer): shell.json's "wallpaper", which
// Maprisma Theme sets; a calm gradient in the theme's colours until there is one.
Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "maprisma-shell-wallpaper"
        WlrLayershell.layer: WlrLayer.Background
        color: Settings.surface

        Rectangle {
            anchors.fill: parent
            visible: image.status !== Image.Ready
            gradient: Gradient {
                GradientStop { position: 0; color: Settings.surface }
                GradientStop { position: 1; color: Qt.darker(Settings.surfaceContainerHigh, 1.1) }
            }
        }

        Image {
            id: image
            anchors.fill: parent
            source: Settings.wallpaper !== "" ? "file://" + Settings.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            smooth: true
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }
    }
}
