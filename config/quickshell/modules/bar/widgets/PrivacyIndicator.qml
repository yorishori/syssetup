import QtQuick
import qs.core
import qs.services

// Recording indicator: a compartment that slides open while the mic, camera or
// screen (shared or recorded) is in use, with a pulsing REC lamp and a glowing icon per device. Peach
// (attention), not red: recording isn't an error. Hidden when nothing records.
Item {
    id: root

    readonly property bool active: Privacy.micActive || Privacy.cameraActive || Privacy.screenActive

    implicitWidth: active ? box.implicitWidth : 0
    implicitHeight: box.implicitHeight
    clip: true
    visible: implicitWidth > 0

    Behavior on implicitWidth {
        NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
    }

    BarBox {
        id: box

        stroke: Config.colors.warn

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            color: Config.colors.warn

            SequentialAnimation on opacity {
                running: root.active
                loops: Animation.Infinite

                NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
            }
        }
        BarLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F036C}"
            visible: Privacy.micActive
            color: Config.colors.warn
            lit: true
            font.pixelSize: Config.font.size
        }
        BarLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F1483}"
            visible: Privacy.screenActive
            color: Config.colors.warn
            lit: true
            font.pixelSize: Config.font.size
        }
        BarLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F0567}"
            visible: Privacy.cameraActive
            color: Config.colors.warn
            lit: true
            font.pixelSize: Config.font.size
        }
    }
}
