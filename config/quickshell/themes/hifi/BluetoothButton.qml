import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// A toggle switch printed BT: flip it to power the radio. Its tip glows while
// a device is connected and blinks while scanning; without an adapter it's
// dead. The printed label opens the Bluetooth drop.
Row {
    id: root

    required property W.BluetoothButton control
    readonly property bool shown: true
    readonly property rect toggleArea: Qt.rect(toggle.x, toggle.y, toggle.width, toggle.height)

    spacing: 5

    Toggle {
        id: toggle

        on: root.control.on
        dead: !root.control.available
        hovered: root.control.overToggle
        tipLit: root.control.connected
        tipBlink: root.control.discovering
    }
    Legend {
        anchors.verticalCenter: parent.verticalCenter
        text: "bt"
        color: root.control.hovered && !root.control.overToggle ? Theme.palette.fg : Theme.palette.dim
    }
}
