import QtQuick
import qs.components as C
import qs.core

// A small display behind glass, lit in the display color: up to three lines,
// the first brightest. The audio deck's screens, the drive caddies'.
Item {
    id: root

    property string line1
    property string line2
    property string line3
    property int size: 10  // the first line's; the others a little smaller

    width: 96
    height: 34

    Well {
        id: glass

        anchors.fill: parent
        roundness: 3
        fill: Qt.tint("#050807", Qt.alpha(Theme.palette.accent, 0.04))
    }
    Column {
        anchors {
            fill: parent
            margins: 5
        }
        spacing: 1

        C.StyledText {
            width: parent.width
            text: root.line1
            caps: true
            elide: Text.ElideRight
            color: Theme.palette.accent
            glow: true
            font.pixelSize: root.size
            font.bold: true
        }
        C.StyledText {
            width: parent.width
            text: root.line2
            caps: true
            elide: Text.ElideRight
            color: Qt.alpha(Theme.palette.accent, 0.75)
            font.pixelSize: root.size - 1
        }
        C.StyledText {
            width: parent.width
            text: root.line3
            caps: true
            elide: Text.ElideRight
            color: Qt.alpha(Theme.palette.accent, 0.55)
            font.pixelSize: root.size - 2
            visible: text !== ""
        }
    }
    Gloss {
        anchors {
            fill: parent
            margins: 1
        }
        roundness: glass.r
    }
}
