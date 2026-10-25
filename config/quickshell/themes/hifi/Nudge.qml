import QtQuick
import qs.core

// A small key with a glyph on it.
Item {
    id: nudge

    property string glyph
    signal pressed

    width: 26
    height: 22

    Key {
        anchors.fill: parent
        down: nudgeArea.pressed
        hovered: nudgeArea.containsMouse
    }
    Text {
        anchors.centerIn: parent
        text: nudge.glyph
        color: Theme.palette.fg
        font.family: Theme.font.family
        font.pixelSize: 10
    }
    MouseArea {
        id: nudgeArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: nudge.pressed()
    }
}
