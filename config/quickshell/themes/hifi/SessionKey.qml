import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.components as C
import qs.core
import qs.modules.session as M

// A big power key: its glyph behind a round lens, the label silk-screened,
// the number on a small display. The current key's lens lights in the
// display color. Armed, it latches in, its lens turns amber, and the fuse
// burns down as an LED ladder along its bottom.
Item {
    id: root

    required property M.SessionKey control
    readonly property bool on: control.current || control.armed
    readonly property color tone: control.armed ? Theme.palette.warn : Theme.palette.accent
    readonly property real offset: key.shift - key.travel / 2

    Key {
        id: key

        anchors.fill: parent
        roundness: (Theme.values.shape?.radius ?? 0) + 4
        down: root.control.pressed || root.control.armed
        hovered: root.control.hovered
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 14
            rightMargin: 16
            topMargin: root.offset * 2
        }
        spacing: 16

        // The lens.
        Item {
            implicitWidth: 46
            implicitHeight: 46

            RectangularShadow {
                anchors {
                    fill: parent
                    margins: 4
                }
                visible: root.on && (Theme.glow.opacity ?? 0) > 0
                radius: width / 2
                blur: 12
                color: Qt.alpha(root.tone, 0.6 * (Theme.glow.opacity ?? 0))
            }
            Well {
                anchors.fill: parent
                roundness: width / 2
                fill: root.on ? Qt.tint(Theme.palette.bgAlt, Qt.alpha(root.tone, 0.12)) : Theme.palette.bgAlt
                ring: root.on ? root.tone : "transparent"
            }
            C.StyledText {
                anchors.centerIn: parent
                text: root.control.glyph
                color: root.on ? root.tone : Theme.palette.muted
                glow: root.on
                font.pixelSize: 24
            }
            Gloss {
                anchors {
                    fill: parent
                    margins: 1
                }
                roundness: width / 2
            }
        }
        Engraved {
            Layout.fillWidth: true
            text: root.control.label
            caps: true
            tracking: 2
            color: root.on ? Theme.palette.fg : Theme.palette.dim
            font.pixelSize: Theme.font.size + 3
            font.bold: true
        }
        Item {
            implicitWidth: number.implicitWidth + 14
            implicitHeight: number.implicitHeight + 6

            Well {
                anchors.fill: parent
                roundness: 3
            }
            C.StyledText {
                id: number

                anchors.centerIn: parent
                text: root.control.number
                color: root.on ? root.tone : Theme.palette.muted
                glow: root.on
                font.pixelSize: Theme.font.size - 1
                font.bold: true
            }
        }
    }

    // The fuse.
    Row {
        id: fuse

        readonly property int n: 16

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 22
            rightMargin: 22
            bottomMargin: 7 + key.travel - key.shift
        }
        height: 3
        spacing: 2
        visible: root.control.armed

        Repeater {
            model: fuse.n

            Rectangle {
                required property int index

                width: (fuse.width - (fuse.n - 1) * fuse.spacing) / fuse.n
                height: fuse.height
                color: index < Math.ceil(root.control.fuse * fuse.n) ? Theme.palette.warn : Qt.alpha(Theme.palette.warn, 0.12)
            }
        }
    }
}
