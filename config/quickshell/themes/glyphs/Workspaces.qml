import QtQuick
import qs.components as C
import qs.core
import qs.modules.bar.widgets as W

// Workspaces as two-digit readouts. The focused one glows, with an indicator
// lamp underneath that slides between them; occupied ones are bright, empty
// ones dim.
Item {
    id: root

    required property W.Workspaces control
    readonly property int cell: 24

    function workspaceAt(x: real): int {
        const id = Math.floor(x / cell) + 1;
        return id >= 1 && id <= control.count ? id : 0;
    }

    implicitWidth: control.count * cell
    implicitHeight: Theme.barHeight

    Repeater {
        model: root.control.count

        Item {
            id: cellItem

            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: root.control.active === wsId

            x: index * root.cell
            width: root.cell
            height: root.height

            W.BarLabel {
                anchors.centerIn: parent
                text: String(cellItem.wsId).padStart(2, "0")
                font.pixelSize: Theme.font.size
                lit: cellItem.active
                color: cellItem.active ? Theme.palette.accent
                    : root.control.occupied(cellItem.wsId) ? Theme.palette.fg
                    : Theme.palette.muted

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }
    }

    C.Marker {
        readonly property bool shown: root.control.active >= 1 && root.control.active <= root.control.count

        x: (root.control.active - 1) * root.cell + 5
        y: root.height - 4
        width: root.cell - 10
        height: 2
        visible: shown

        Behavior on x {
            NumberAnimation { duration: 260; easing.type: Theme.motion.spring; easing.overshoot: Theme.motion.bounce }
        }
    }
}
