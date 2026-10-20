import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// A tape counter beside a red REC lamp: white digits on rolling drums,
// 00:00 while idle. Recording, the lamp is lit and the drums roll with the
// seconds; click the counter to stop. When it stops, the counter rewinds.
Row {
    id: root

    required property W.RecordingKey control
    readonly property bool shown: true
    readonly property int s: control.seconds

    spacing: 6

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Led {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 11
            on: root.control.recording
            color: Theme.palette.error
        }
        Legend {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.control.recording ? root.control.label : "rec"
            color: root.control.recording ? Theme.palette.error : Theme.palette.dim
        }
    }

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: digits.width + 10
        height: 28

        Well {
            anchors.fill: parent
            roundness: 3
            fill: "#050505"
            ring: root.control.recording && root.control.hovered ? Qt.alpha(Theme.palette.error, 0.7) : "transparent"
        }
        Row {
            id: digits

            anchors.centerIn: parent
            spacing: 1

            Drum { width: 11; height: 20; digit: Math.floor(root.s / 600) % 10 }
            Drum { width: 11; height: 20; digit: Math.floor(root.s / 60) % 10 }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 5
                horizontalAlignment: Text.AlignHCenter
                text: ":"
                color: "#9d9a93"
                font.family: Theme.font.family
                font.pixelSize: 13
                font.bold: true
            }
            Drum { width: 11; height: 20; digit: Math.floor(root.s % 60 / 10); wheel: 6 }
            Drum { width: 11; height: 20; digit: root.s % 10 }
        }
    }
}
