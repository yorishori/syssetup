import QtQuick
import qs.core
import qs.services

// Caffeinate: an empty cup, dim; click fills it (accent) and the screen
// neither locks nor turns off on idle until it's clicked again.
BarLabel {
    id: root

    text: Idle.caffeinated ? "\u{F0176}" : "\u{F06CA}"
    lit: Idle.caffeinated
    color: Idle.caffeinated ? Config.colors.accent : area.containsMouse ? Config.colors.fg : Config.colors.dim

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Idle.caffeinated = !Idle.caffeinated
    }
}
