import QtQuick
import qs.components as C
import qs.core

// A row (or column) of blocks that light up, like an old game's HP bar;
// when it can be set, the last lit block is framed in cream.
Item {
    id: root

    required property C.Meter control
    readonly property int px: Theme.get("pixel.scale") ?? 3
    readonly property int count: Math.max(1, control.segments)
    readonly property real length: control.vertical ? height : width
    readonly property real block: (length - (count - 1) * px) / count

    Repeater {
        model: root.count

        Rectangle {
            required property int index
            readonly property int n: root.control.vertical ? root.count - 1 - index : index
            readonly property bool lit: n < root.control.lit
            readonly property bool knob: root.control.interactive && n === root.control.lit - 1

            x: root.control.vertical ? 0 : Math.round(n * (root.block + root.px))
            y: root.control.vertical ? Math.round(index * (root.block + root.px)) : 0
            width: root.control.vertical ? root.width : Math.max(1, Math.round(root.block))
            height: root.control.vertical ? Math.max(1, Math.round(root.block)) : root.height
            color: knob ? Theme.palette.border : lit ? root.control.color : Theme.palette.surface

            Rectangle {
                anchors.fill: parent
                anchors.margins: Math.min(root.px, Math.floor(Math.min(parent.width, parent.height) / 3))
                color: root.control.color
                visible: parent.knob
            }
        }
    }
}
