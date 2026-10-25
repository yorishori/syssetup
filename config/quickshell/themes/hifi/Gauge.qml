import QtQuick
import qs.components as C
import qs.core

// A battery cell: a glass window of segments, lit up to the charge, with the
// terminal nub on its end.
Item {
    id: root

    required property C.Gauge control
    readonly property int n: Math.max(1, control.segments)
    readonly property int lit: Math.round(Math.max(0, Math.min(1, control.value)) * n)

    implicitWidth: 22
    implicitHeight: 10

    Well {
        id: cell

        width: parent.width - 2
        height: parent.height
        roundness: 2
    }
    Rectangle {
        x: cell.width
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: parent.height / 2
        radius: 1
        color: Theme.palette.border
    }
    Row {
        id: cells

        anchors {
            fill: cell
            margins: 2
        }
        spacing: 1

        Repeater {
            model: root.n

            Rectangle {
                required property int index

                width: (cells.width - (root.n - 1) * cells.spacing) / root.n
                height: parent.height
                color: index < root.lit ? root.control.color : Qt.alpha(root.control.color, 0.12)
            }
        }
    }
}
