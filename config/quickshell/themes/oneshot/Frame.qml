import QtQuick
import qs.core

// The RPG window: a dark outline with its corners cut a pixel, a cream
// frame, a plum face. Everything framed in the theme (panels, signs) is
// one of these, on the art-pixel grid.
Item {
    id: root

    property int px: Theme.get("pixel.scale") ?? 3
    property color face: Theme.palette.bg
    property color frame: Theme.palette.border
    property color outline: Theme.palette.shadow

    Rectangle {
        x: root.px
        width: parent.width - 2 * root.px
        height: parent.height
        color: root.outline
    }
    Rectangle {
        y: root.px
        width: parent.width
        height: parent.height - 2 * root.px
        color: root.outline
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: root.px
        color: root.frame

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.px
            color: root.face
        }
    }
}
