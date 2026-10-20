import QtQuick
import qs.components
import qs.services

// Caffeinate: while on, the screen neither locks nor turns off on idle.
// Click toggles it.
Skinned {
    id: root

    readonly property bool on: Idle.caffeinated
    readonly property bool hovered: area.containsMouse
    readonly property bool pressed: area.pressed

    skin: "CaffeineButton"

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Idle.caffeinated = !Idle.caffeinated
    }
}
