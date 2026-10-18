import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core
import qs.modules.session as M

// A big soft key: the glyph in a round bubble, the label, the number in a
// pill. Current is tinted and outlined in the accent, armed in peach with
// the fuse shrinking along the bottom.
Item {
    id: root

    required property M.SessionKey control
    readonly property bool on: control.current || control.armed
    readonly property color tone: control.armed ? Theme.palette.warn : Theme.palette.accent

    scale: control.pressed ? 0.97 : 1

    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Theme.motion.spring }
    }

    Box {
        anchors.fill: parent
        roundness: 22
        fill: root.on ? Qt.alpha(root.tone, 0.12) : Theme.palette.bgAlt
        stroke: root.on ? root.tone : "transparent"

        Behavior on fill {
            ColorAnimation { duration: 150 }
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 14
            rightMargin: 16
        }
        spacing: 16

        Rectangle {
            implicitWidth: 50
            implicitHeight: 50
            radius: 25
            color: root.on ? root.tone : Theme.palette.surface

            C.StyledText {
                anchors.centerIn: parent
                text: root.control.glyph
                color: root.on ? Theme.palette.shadow : Theme.palette.dim
                font.pixelSize: 26
            }
        }
        C.StyledText {
            Layout.fillWidth: true
            text: root.control.label
            caps: true
            color: root.on ? Theme.palette.fg : Theme.palette.dim
            font.pixelSize: Theme.font.size + 4
            font.bold: true
        }
        Rectangle {
            implicitWidth: number.implicitWidth + 12
            implicitHeight: number.implicitHeight + 4
            radius: height / 2
            color: root.on ? Qt.alpha(root.tone, 0.2) : Theme.palette.surface

            C.StyledText {
                id: number

                anchors.centerIn: parent
                text: root.control.number
                color: root.on ? root.tone : Theme.palette.muted
                font.pixelSize: Theme.font.size - 2
                font.bold: true
            }
        }
    }

    // The fuse.
    Rectangle {
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: 22
            bottomMargin: 8
        }
        height: 4
        radius: 2
        width: (root.width - 44) * root.control.fuse
        color: Theme.palette.warn
        visible: root.control.armed
    }
}
