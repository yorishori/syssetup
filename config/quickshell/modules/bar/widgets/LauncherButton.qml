import QtQuick
import qs.core

// Opens the launcher with the mouse. Glows while the launcher is open.
BarLabel {
    id: root

    property bool active: false

    signal clicked

    text: "\u{F08C7}"
    lit: active
    color: active ? Theme.palette.accent : area.containsMouse ? Theme.palette.fg : Theme.palette.dim
    font.pixelSize: Theme.font.size + 3

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
