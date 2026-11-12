import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.services

// The lock screen (ext-session-lock): the wallpaper dimmed, the time, and a password field
// checked through PAM (assets/pam.d/passwd: pam_unix with faillock).
// `lock()` from the idle monitor, the session menu or IPC (shell lock).
Scope {
    id: root

    readonly property bool locked: lock.locked
    property string message: ""
    property bool busy: pam.active
    property int attempts: 0     // each finished check clears the fields

    function lock() {
        message = ""
        lock.locked = true
    }

    function unlock() {
        lock.locked = false
        message = ""
    }

    function tryPassword(pw) {
        if (pam.active || pw === "") return
        pam.password = pw
        message = ""
        pam.start()
    }

    PamContext {
        id: pam
        property string password: ""
        config: "passwd"
        configDirectory: Quickshell.shellPath("assets/pam.d")
        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(password)
                password = ""
            }
        }
        onMessageChanged: {
            if (message.startsWith("The account is locked")) root.message = message
        }
        onCompleted: (result) => {
            password = ""
            root.attempts++
            if (result === PamResult.Success) root.unlock()
            else if (root.message === "") root.message = "Wrong password"
        }
        onError: root.message = "Could not check the password"
    }

    WlSessionLock {
        id: lock

        WlSessionLockSurface {
            id: surface
            color: Settings.surface

            Image {
                anchors.fill: parent
                source: Settings.wallpaper !== "" ? "file://" + Settings.wallpaper : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            Rectangle {
                anchors.fill: parent
                color: Settings.surface
                opacity: 0.6
            }

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            Column {
                anchors.centerIn: parent
                spacing: 18

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(clock.date, "HH:mm")
                    color: Settings.text
                    font.pixelSize: 96
                    font.weight: Font.Light
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(clock.date, "dddd, d MMMM")
                    color: Settings.dim
                    font.pixelSize: 20
                }

                Item { width: 1; height: 24 }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 320
                    height: 48
                    radius: 24
                    color: Settings.surfaceContainer
                    border.color: input.activeFocus ? Settings.primary : Qt.alpha(Settings.text, 0.15)
                    border.width: 1

                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        color: Settings.text
                        font.pixelSize: 16
                        focus: true
                        enabled: !root.busy
                        Component.onCompleted: forceActiveFocus()
                        onAccepted: {
                            root.tryPassword(text)
                            text = ""
                        }
                        Keys.onEscapePressed: text = ""
                        Connections {
                            target: root
                            function onAttemptsChanged() { input.text = "" }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: input.text === ""
                        text: root.busy ? "Checking…" : "Password"
                        color: Settings.dim
                        font.pixelSize: 15
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 420
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    visible: root.message !== ""
                    text: root.message
                    color: Settings.error
                    font.pixelSize: 14
                }
            }
        }
    }
}
