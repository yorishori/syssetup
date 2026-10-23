import QtQuick
import qs.components
import qs.services

// Opens / closes the session menu.
Skinned {
    id: root

    readonly property bool open: Panels.isOpen("session")
    readonly property bool hovered: area.containsMouse
    readonly property bool pressed: area.pressed

    skin: "PowerButton"

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.toggle("session")
    }
}
