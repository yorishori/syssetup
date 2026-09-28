import QtQuick
import qs.core

// Segmented level meter (tape-deck style) that doubles as a control (unless
// `interactive` is off):
// click or drag to set, scroll to step. Emits moved(value); the owner decides.
Item {
    id: root

    property real value: 0
    property int segments: 20
    property color color: Config.colors.accent
    property bool interactive: true  // false: a read-only readout
    readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * segments)

    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 12

    function setFromX(x: real): void {
        moved(Math.max(0, Math.min(segments, Math.ceil(x / width * segments))) / segments);
    }

    Row {
        anchors.fill: parent
        spacing: 2

        Repeater {
            model: root.segments

            Rectangle {
                required property int index

                width: (root.width - (root.segments - 1) * 2) / root.segments
                height: root.height
                color: index < root.lit ? root.color : Config.colors.surface
                opacity: index < root.lit ? 1 : 0.6

                Behavior on color {
                    ColorAnimation { duration: 90 }
                }
            }
        }
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
