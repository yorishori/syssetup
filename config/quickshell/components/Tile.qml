import QtQuick

// A cell in a grid of choices (symbols, compose results): `current` is the
// keyboard selection. Content goes in as children, over the whole tile.
Skinned {
    id: root

    property bool current: false
    readonly property bool hovered: area.containsMouse

    default property alias content: body.data

    signal clicked(var mouse)
    signal entered

    skin: "Tile"

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.entered()
        onClicked: mouse => root.clicked(mouse)
    }

    Item {
        id: body

        anchors.fill: parent
    }
}
