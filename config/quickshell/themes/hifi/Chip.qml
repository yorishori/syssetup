import QtQuick
import qs.components as C
import qs.core

// A small latching key with an LED: on, it's latched in and the LED is lit;
// off, it stands out, dark, its label struck through.
Item {
    id: root

    required property C.Chip control

    implicitWidth: row.implicitWidth + 22
    implicitHeight: 26

    Key {
        id: key

        anchors.fill: parent
        down: root.control.on
        hovered: root.control.hovered
    }
    Row {
        id: row

        anchors.centerIn: parent
        anchors.verticalCenterOffset: key.shift - key.travel / 2
        spacing: 7

        Led {
            anchors.verticalCenter: parent.verticalCenter
            size: 7
            on: root.control.on
        }
        Engraved {
            text: root.control.text
            caps: true
            color: root.control.on ? Theme.palette.fg : Theme.palette.off
            font.pixelSize: Theme.font.size - 2
            font.bold: true
            font.strikeout: !root.control.on
        }
    }
}
