import QtQuick
import qs.core

// Opens the launcher with the mouse. Glows while the launcher is open.
BarLabel {
    id: root

    property bool active: false

    signal clicked

    text: "\u{F08C7}"
    lit: active
    color: active ? Config.colors.accent : area.containsMouse ? Config.colors.fg : Config.colors.dim
    font.pixelSize: Config.font.size + 3

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
