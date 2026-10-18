import QtQuick

// A boxed item in a list of records (notification history): hover state and
// a click area; `tone` makes it call for attention in that color (critical).
// Content goes in as children, positioned by you; buttons inside keep their
// own clicks.
Skinned {
    id: root

    property color tone: "transparent"
    readonly property bool hovered: area.containsMouse

    default property alias content: body.data

    signal clicked(var mouse)

    skin: "Entry"

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.clicked(mouse)
    }

    Item {
        id: body

        anchors.fill: parent
    }
}
