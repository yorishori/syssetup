import QtQuick
import qs.core
import qs.services

// Opens / closes the session menu. Glows while it's open.
BarLabel {
    text: "\u{F0425}"
    lit: Panels.isOpen("session")
    color: Panels.isOpen("session") ? Config.colors.accent : area.containsMouse ? Config.colors.fg : Config.colors.dim

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.toggle("session")
    }
}
