import QtQuick
import qs.components
import qs.services

// The time and date. Click opens the calendar drop (`active` while it's open).
Skinned {
    id: root

    readonly property bool active: Panels.isOpen("calendar")
    readonly property date now: Time.now
    readonly property bool hovered: area.containsMouse


    skin: "Clock"

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.toggle("calendar")
    }
}
