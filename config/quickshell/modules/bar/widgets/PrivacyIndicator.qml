import QtQuick
import qs.components
import qs.core
import qs.services

// Recording indicator: a compartment that slides open while the mic, camera or
// screen (shared or recorded) is in use, with a pulsing lamp and a glowing icon per device. Peach
// (attention), not red: recording isn't an error. Hidden when nothing records.
Item {
    id: root

    readonly property bool active: Privacy.micActive || Privacy.cameraActive || Privacy.screenActive

    implicitWidth: active ? box.implicitWidth : 0
    implicitHeight: box.implicitHeight
    clip: true
    visible: implicitWidth > 0

    Behavior on implicitWidth {
        NumberAnimation { duration: 260; easing.type: Theme.motion.spring; easing.overshoot: 0.9 }
    }

    BarBox {
        id: box

        tone: Theme.palette.warn

        Lamp {
            anchors.verticalCenter: parent.verticalCenter
            on: true
            litColor: Theme.palette.warn
            pulse: root.active
        }
        BarLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F036C}"
            visible: Privacy.micActive
            color: Theme.palette.warn
            lit: true
            font.pixelSize: Theme.font.size
        }
        BarLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F1483}"
            visible: Privacy.screenActive
            color: Theme.palette.warn
            lit: true
            font.pixelSize: Theme.font.size
        }
        BarLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F0567}"
            visible: Privacy.cameraActive
            color: Theme.palette.warn
            lit: true
            font.pixelSize: Theme.font.size
        }
    }
}
