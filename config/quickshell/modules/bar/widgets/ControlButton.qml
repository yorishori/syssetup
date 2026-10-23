import QtQuick
import qs.components

// Opens the control center (`active` while it's open).
Skinned {
    id: root

    property bool active: false
    readonly property bool hovered: area.containsMouse
    readonly property bool pressed: area.pressed

    signal clicked

    skin: "ControlButton"

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
