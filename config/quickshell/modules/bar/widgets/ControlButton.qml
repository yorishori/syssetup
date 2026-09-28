import QtQuick
import qs.core

// Opens the control center. Glows while it's open.
BarLabel {
    id: root

    property bool active: false

    signal clicked

    text: "\u{F062E}"
    lit: active
    color: active ? Config.colors.accent : area.containsMouse ? Config.colors.fg : Config.colors.dim

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
