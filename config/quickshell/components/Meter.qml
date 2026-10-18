import QtQuick
import qs.core

// Level meter that doubles as a control (unless `interactive` is off): click
// or drag to set, scroll to step. `segments` is the step count. Emits
// moved(value); the owner decides.
Skinned {
    id: root

    property real value: 0
    property int segments: 20
    property color color: Theme.palette.accent
    property bool interactive: true  // false: a read-only readout
    readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * segments)

    signal moved(real value)

    skin: "Meter"
    implicitWidth: 200
    implicitHeight: 12

    function setFromX(x: real): void {
        moved(Math.max(0, Math.min(segments, Math.ceil(x / width * segments))) / segments);
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.setFromX(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                root.setFromX(mouse.x);
        }
        onWheel: wheel => root.moved(Math.max(0, Math.min(root.segments, root.lit + (wheel.angleDelta.y > 0 ? 1 : -1))) / root.segments)
    }
}
