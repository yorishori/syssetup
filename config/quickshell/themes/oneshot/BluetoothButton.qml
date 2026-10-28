import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// Dim when on, lit (connected glyph) while a device is connected, dim red
// when off, pulsing while scanning. Hidden without an adapter.
Glyph {
    id: root

    required property W.BluetoothButton control
    readonly property bool shown: control.available

    text: !control.on ? "\u{F00B2}" : control.connected ? "\u{F00B1}" : "\u{F00AF}"
    readonly property bool lit: control.on && control.connected
    color: !control.on ? Theme.palette.off : lit ? Theme.palette.accent : Theme.palette.dim

    Behavior on color {
        ColorAnimation { duration: 200 }
    }

    SequentialAnimation on opacity {
        running: root.control.discovering
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
    }
}
