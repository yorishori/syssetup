import QtQuick
import qs.components
import qs.services

// Opens the launcher with the mouse (`active` while it's open).
Skinned {
    id: root

    readonly property bool active: Panels.isOpen("launcher")
    readonly property bool hovered: area.containsMouse
    readonly property bool pressed: area.pressed


    skin: "LauncherButton"

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.toggle("launcher")
    }
}
