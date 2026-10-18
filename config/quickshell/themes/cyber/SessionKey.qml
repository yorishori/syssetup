import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core
import qs.modules.session as M

// A big hardware key: glyph, stencilled label, index code in the corner.
// Current is outlined in accent, armed in peach with the fuse along the
// bottom.
Item {
    id: root

    required property M.SessionKey control
    readonly property bool on: control.current || control.armed
    readonly property color tone: control.armed ? Theme.palette.warn : Theme.palette.accent

    scale: control.pressed ? 0.97 : 1

    Behavior on scale {
        NumberAnimation { duration: 180; easing.type: Easing.OutBack }
    }

    Chamfer {
        anchors.fill: parent
        cut: 10
        fill: root.control.armed ? Qt.alpha(Theme.palette.warn, 0.12) : root.control.current ? Theme.palette.surface : Theme.palette.bgAlt
        stroke: root.on ? root.tone : Theme.palette.border
        strokeWidth: root.on ? 2 : 1
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 20
            rightMargin: 18
        }
        spacing: 18

        C.StyledText {
            text: root.control.glyph
            color: root.on ? root.tone : Theme.palette.dim
            glow: root.on
            font.pixelSize: 38
        }
        C.StyledText {
            Layout.fillWidth: true
            text: root.control.label
            caps: true
            color: root.on ? Theme.palette.fg : Theme.palette.dim
            font.pixelSize: Theme.font.size + 5
            font.bold: true
            tracking: 3
        }
        // Index code, like a label on a hardware key.
        C.StyledText {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 10
            text: String(root.control.number).padStart(2, "0")
            color: root.control.current ? root.tone : Theme.palette.muted
            font.pixelSize: Theme.font.size - 2
            font.bold: true
        }
    }

    // The fuse.
    Rectangle {
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: 14
            bottomMargin: 10
        }
        height: 3
        width: (root.width - 28) * root.control.fuse
        color: Theme.palette.warn
        visible: root.control.armed
    }
}
