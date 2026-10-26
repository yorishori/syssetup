import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// Workspaces as little tags, each on its own length of twine from the
// bough, like a wind chime. The current one is lantern amber and swings
// on its twine when you arrive; occupied ones are cream, empty ones dim.
Item {
    id: root

    required property W.Workspaces control

    readonly property int px: Theme.get("pixel.scale") ?? 3
    readonly property int tag: 8 * px
    readonly property int cell: tag + 2 * px
    // Where the bough's underside is, in here: this item is bar-tall and
    // sits `offset` below the bar's top.
    readonly property int bough: (Theme.get("bar.bough") ?? 18) - (Theme.get("bar.offset") ?? 0)
    // Each tag's extra drop below the line, in art pixels; repeats.
    readonly property var drops: [0, 2, -1, 1, 3, 0, 2, -1]

    // The arriving tag swings on its twine like a pendulum, settling.
    property real swing: 0

    SequentialAnimation {
        id: swingAnim

        NumberAnimation { target: root; property: "swing"; to: 9; duration: 140; easing.type: Easing.OutSine }
        NumberAnimation { target: root; property: "swing"; to: -6; duration: 260; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "swing"; to: 3; duration: 240; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "swing"; to: -1.5; duration: 220; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "swing"; to: 0; duration: 200; easing.type: Easing.InOutSine }
    }

    function workspaceAt(x: real): int {
        const id = Math.floor(x / cell) + 1;
        return id >= 1 && id <= control.count ? id : 0;
    }

    implicitWidth: control.count * cell
    implicitHeight: Theme.barHeight

    Connections {
        target: root.control

        function onActiveChanged() {
            swingAnim.restart();
        }
    }

    Repeater {
        model: root.control.count

        Item {
            id: cellItem

            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: root.control.active === wsId
            readonly property bool hovered: root.control.hovered === wsId
            readonly property int tagTop: Math.round((root.height - root.tag) / 2 / root.px + root.drops[index % root.drops.length]) * root.px
            x: index * root.cell
            // Swinging from where its twine meets the bough.
            transform: Rotation {
                origin.x: root.cell / 2
                origin.y: root.bough
                angle: cellItem.active ? root.swing : 0
            }
            width: root.cell
            height: root.height

            // Twine.
            Rectangle {
                x: Math.round(root.cell / 2 / root.px) * root.px - root.px
                y: root.bough
                width: root.px
                height: cellItem.tagTop - root.bough
                color: "#a08c62"
            }

            // The tag: dark outline (corners cut), a frame, the number.
            Rectangle {
                x: root.px * 2
                y: cellItem.tagTop
                width: root.tag - 2 * root.px
                height: root.tag
                color: Theme.palette.shadow
            }
            Rectangle {
                x: root.px
                y: cellItem.tagTop + root.px
                width: root.tag
                height: root.tag - 2 * root.px
                color: Theme.palette.shadow
            }
            Rectangle {
                x: root.px * 2
                y: cellItem.tagTop + root.px
                width: root.tag - 2 * root.px
                height: root.tag - 2 * root.px
                color: cellItem.active ? Theme.palette.border : cellItem.hovered ? Theme.palette.dim : "#4a4068"

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: root.px
                    color: cellItem.active ? Theme.palette.accent : Theme.palette.surface

                    W.BarLabel {
                        anchors.centerIn: parent
                        text: cellItem.wsId
                        font.pixelSize: Theme.font.size
                        color: cellItem.active ? Theme.palette.shadow
                            : root.control.occupied(cellItem.wsId) ? Theme.palette.fg
                            : Theme.palette.muted
                    }
                }
            }
        }
    }
}
