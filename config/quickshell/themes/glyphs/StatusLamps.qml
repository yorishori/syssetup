import QtQuick
import qs.components as C
import qs.core
import qs.modules.bar.widgets as W

// A sleep glyph while idle, and a compartment that slides open while the
// mic, camera or screen is in use, with a pulsing lamp and a glowing icon per
// device. Peach (attention), not red: recording isn't an error. Hidden when
// nothing is on.
Row {
    id: root

    required property W.StatusLamps control
    readonly property bool shown: control.idle || privacy.implicitWidth > 0

    spacing: 8

    W.BarLabel {
        anchors.verticalCenter: parent.verticalCenter
        text: "\u{F04B2}"
        visible: root.control.idle
    }

    Item {
        id: privacy

        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: root.control.privacy ? box.implicitWidth : 0
        implicitHeight: box.implicitHeight
        clip: true
        visible: implicitWidth > 0

        Behavior on implicitWidth {
            NumberAnimation { duration: 260; easing.type: Theme.motion.spring; easing.overshoot: 0.9 }
        }

        W.BarBox {
            id: box

            tone: Theme.palette.warn

            C.Lamp {
                anchors.verticalCenter: parent.verticalCenter
                on: true
                litColor: Theme.palette.warn
                pulse: root.control.privacy
            }
            W.BarLabel {
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{F036C}"
                visible: root.control.mic
                color: Theme.palette.warn
                lit: true
                font.pixelSize: Theme.font.size
            }
            W.BarLabel {
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{F1483}"
                visible: root.control.screen
                color: Theme.palette.warn
                lit: true
                font.pixelSize: Theme.font.size
            }
            W.BarLabel {
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{F0567}"
                visible: root.control.camera
                color: Theme.palette.warn
                lit: true
                font.pixelSize: Theme.font.size
            }
        }
    }
}
