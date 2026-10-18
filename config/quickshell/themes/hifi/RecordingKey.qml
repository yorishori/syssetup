import QtQuick
import qs.components as C
import qs.core
import qs.modules.bar.widgets as W

// The record key, latched in while it runs: a pulsing amber LED and
// "REC 00:12" backlit beside it. Press to stop.
Item {
    id: root

    required property W.RecordingKey control

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 24

    Key {
        id: key

        anchors.fill: parent
        down: true
        hovered: root.control.hovered
        glowColor: root.control.hovered ? Theme.palette.warn : "transparent"
    }
    Row {
        id: row

        anchors.centerIn: parent
        anchors.verticalCenterOffset: key.shift - key.travel / 2
        spacing: 7

        Led {
            anchors.verticalCenter: parent.verticalCenter
            size: 8
            on: true
            color: Theme.palette.warn
            pulse: true
        }
        C.StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: `${root.control.label} ${root.control.elapsed}`
            caps: true
            color: Theme.palette.warn
            glow: true
            font.pixelSize: Theme.font.size - 2
            font.bold: true
        }
    }
}
