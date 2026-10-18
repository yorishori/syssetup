import QtQuick
import qs.components
import qs.core
import qs.services

// Workspaces as two-digit readouts. The focused one glows, with an indicator
// lamp underneath that slides between them; occupied ones are bright, empty
// ones dim.
Item {
    id: root

    // Always show the configured count, more if a higher workspace exists.
    readonly property int count: Math.max(Config.bar.workspaces, ...Wm.workspaces.map(w => w.id))
    readonly property int cell: 24

    implicitWidth: count * cell
    implicitHeight: Config.bar.height

    Repeater {
        model: root.count

        Item {
            id: cellItem

            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: Wm.activeWorkspace === wsId

            x: index * root.cell
            width: root.cell
            height: root.height

            BarLabel {
                anchors.centerIn: parent
                text: String(cellItem.wsId).padStart(2, "0")
                font.pixelSize: Theme.font.size
                lit: cellItem.active
                color: cellItem.active ? Theme.palette.accent
                    : Wm.isOccupied(cellItem.wsId) ? Theme.palette.fg
                    : Theme.palette.muted

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Wm.focusWorkspace(cellItem.wsId)
            }
        }
    }

    Marker {
        readonly property bool shown: Wm.activeWorkspace >= 1 && Wm.activeWorkspace <= root.count

        x: (Wm.activeWorkspace - 1) * root.cell + 5
        y: root.height - 4
        width: root.cell - 10
        height: 2
        visible: shown

        Behavior on x {
            NumberAnimation { duration: 260; easing.type: Theme.motion.spring; easing.overshoot: Theme.motion.bounce }
        }
    }
}
