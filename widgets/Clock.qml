import QtQuick
import Quickshell
import qs.services

// "Wednesday 18:09"; a click shows the date instead, and back.
Glyph {
    id: root
    property bool showDate: false
    bold: true
    pixelSize: 13
    text: Qt.formatDateTime(clock.date, showDate ? "dd.MM.yyyy" : "dddd HH:mm")
    onClicked: (button) => { if (button === Qt.LeftButton) root.showDate = !root.showDate }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
