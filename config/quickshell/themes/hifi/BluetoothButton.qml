import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// An illuminated rocker labelled BT: flip it to power the radio. Its lens
// glows while a device is connected and blinks while scanning; without an
// adapter it's dead. The label opens the Bluetooth drop.
Row {
    id: root

    required property W.BluetoothButton control
    readonly property bool shown: true
    readonly property rect toggleArea: Qt.rect(toggle.x, toggle.y, toggle.width, toggle.height)

    spacing: 5

    Rocker {
        id: toggle

        on: root.control.on
        dead: !root.control.available
        hovered: root.control.overToggle
        lit: root.control.connected
        blink: root.control.discovering
    }
    Legend {
        anchors.verticalCenter: parent.verticalCenter
        text: "bt"
        hovered: root.control.hovered && !root.control.overToggle
    }
}
