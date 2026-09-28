import QtQuick
import qs.core
import qs.services

// Bluetooth at a glance: dim when on, lit (connected glyph) while a device is
// connected, dim red when off, pulsing while scanning. Click opens the drop.
BarLabel {
    id: root

    signal toggleDrop

    visible: Bluez.available
    text: !Bluez.enabled ? "\u{F00B2}" : Bluez.connected.length > 0 ? "\u{F00B1}" : "\u{F00AF}"
    lit: Bluez.enabled && Bluez.connected.length > 0
    color: !Bluez.enabled ? Config.colors.off : lit ? Config.colors.accent : Config.colors.dim

    Behavior on color {
        ColorAnimation { duration: 200 }
    }

    SequentialAnimation on opacity {
        running: Bluez.discovering
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleDrop()
    }
}
