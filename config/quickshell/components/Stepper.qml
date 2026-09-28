import QtQuick
import QtQuick.Layouts
import qs.core

// Integer setting: [−] 013 PX [+]. Scroll works too. Emits moved(value).
RowLayout {
    id: root

    property int value: 0
    property int from: 0
    property int to: 100
    property int step: 1
    property string suffix: ""

    signal moved(int value)

    function nudge(n: int): void {
        const v = Math.max(from, Math.min(to, value + n * step));
        if (v !== value)
            moved(v);
    }

    spacing: 4

    IconButton {
        size: 24
        icon: "\u{F0374}"
        enabled: root.value > root.from
        opacity: enabled ? 1 : 0.35
        onClicked: root.nudge(-1)
    }
    StyledText {
        Layout.minimumWidth: 44
        horizontalAlignment: Text.AlignHCenter
        text: String(root.value).padStart(2, "0") + (root.suffix ? " " + root.suffix.toUpperCase() : "")
        color: Config.colors.accent
        glow: true
        font.bold: true

        MouseArea {
            anchors.fill: parent
            onWheel: wheel => root.nudge(wheel.angleDelta.y > 0 ? 1 : -1)
        }
    }
    IconButton {
        size: 24
        icon: "\u{F0415}"
        enabled: root.value < root.to
        opacity: enabled ? 1 : 0.35
        onClicked: root.nudge(1)
    }
}
