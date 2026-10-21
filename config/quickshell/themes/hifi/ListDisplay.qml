import QtQuick
import qs.components as C
import qs.core

// A list on a display behind glass, in the display color: a title line, then
// rows, `current` one marked with a pointer and lit brighter; group headings
// among them print smaller. Scrolling or clicking a row picks it
// (picked(index)); it scrolls to keep `current` in view. Under it, `status`
// (in red when `alarm`).
//
// Rows: { text, glyph, tail, lit, heading }. A heading isn't pickable.
Item {
    id: root

    property string title
    property var rows: []
    property int current: -1
    property string status
    property bool alarm: false
    readonly property real row: 18
    // Whether any row has a glyph (they get a column).
    readonly property bool glyphs: rows.some(r => r.glyph)

    signal picked(int index)

    // The next pickable row from `from`, `step` at a time; `from` if none.
    function next(from: int, step: int): int {
        for (let i = from + step; i >= 0 && i < rows.length; i += step)
            if (!rows[i].heading)
                return i;
        return from;
    }

    onCurrentChanged: if (current >= 0) list.positionViewAtIndex(current, ListView.Contain)

    Well {
        id: glass

        anchors.fill: parent
        roundness: 3
        fill: Qt.tint("#050807", Qt.alpha(Theme.palette.accent, 0.04))
    }
    C.StyledText {
        x: 10
        y: 7
        width: parent.width - 20
        text: root.title
        caps: true
        elide: Text.ElideRight
        color: Theme.palette.accent
        glow: true
        font.pixelSize: 11
        font.bold: true
    }
    ListView {
        id: list

        x: 10
        y: 27
        width: parent.width - 20
        // Whole rows only, above the status line.
        height: Math.floor((parent.height - y - 22) / root.row) * root.row
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.rows

        delegate: Item {
            id: line

            required property var modelData
            required property int index
            readonly property bool here: index === root.current

            width: ListView.view.width
            height: root.row

            C.StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "▸"
                color: Theme.palette.accent
                glow: true
                visible: line.here
            }
            // The glyphs in a column of their own, so the names line up.
            C.StyledText {
                x: 14
                width: 16
                anchors.verticalCenter: parent.verticalCenter
                text: line.modelData.glyph ?? ""
                color: Qt.alpha(Theme.palette.accent, line.here || line.modelData.lit ? 1 : 0.7)
                glow: line.here || !!line.modelData.lit
                font.pixelSize: 11
                visible: !line.modelData.heading
            }
            C.StyledText {
                x: line.modelData.heading ? 0 : root.glyphs ? 34 : 14
                width: parent.width - x - tail.width - 8
                anchors.verticalCenter: parent.verticalCenter
                text: line.modelData.text
                caps: true
                elide: Text.ElideRight
                color: Qt.alpha(Theme.palette.accent, line.modelData.heading ? 0.45 : line.here || line.modelData.lit ? 1 : 0.7)
                glow: line.here || !!line.modelData.lit
                font.pixelSize: line.modelData.heading ? 9 : 11
                font.bold: line.here || !!line.modelData.heading
            }
            C.StyledText {
                id: tail

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                text: line.modelData.tail ?? ""
                caps: true
                color: Qt.alpha(Theme.palette.accent, line.here ? 0.9 : 0.55)
                font.pixelSize: 10
            }
            MouseArea {
                anchors.fill: parent
                enabled: !line.modelData.heading
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(line.index)
            }
        }
    }
    C.StyledText {
        x: 10
        y: parent.height - 18
        width: parent.width - 20
        text: root.status
        caps: true
        elide: Text.ElideRight
        color: root.alarm ? Theme.palette.error : Qt.alpha(Theme.palette.accent, 0.6)
        font.pixelSize: 10
    }
    Gloss {
        anchors {
            fill: parent
            margins: 1
        }
        roundness: glass.r
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => root.picked(root.next(root.current, wheel.angleDelta.y > 0 ? -1 : 1))
    }
}
