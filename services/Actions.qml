pragma Singleton

import QtQuick
import Quickshell

// What bar widgets ask the shell for (shell.qml does it).
Singleton {
    signal session()
    signal launcher()
}
