import QtQuick
import qs.components
import qs.services

// Opens the control center (`active` while it's open).
Skinned {
    id: root

    readonly property bool active: Panels.isOpen("control")
    readonly property bool hovered: area.containsMouse
    readonly property bool pressed: area.pressed


    skin: "ControlButton"

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.toggle("control")
    }
}
