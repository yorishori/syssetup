import QtQuick
import qs.components
import qs.services

// Bluetooth: on or off, a device connected, scanning. Click opens the
// Bluetooth drop; a skin with a power switch (`toggleArea`, in this item's
// coordinates) turns it on and off when that's clicked. The skin may hide it
// without an adapter (`shown`).
Skinned {
    id: root

    readonly property bool available: Bluez.available
    readonly property bool on: Bluez.enabled
    readonly property bool connected: Bluez.connected.length > 0
    readonly property bool discovering: Bluez.discovering
    readonly property bool hovered: area.containsMouse
    readonly property rect toggleArea: view?.toggleArea ?? Qt.rect(0, 0, 0, 0)
    readonly property bool overToggle: hovered && inToggle(area.mouseX, area.mouseY)

    signal toggleDrop

    function inToggle(x: real, y: real): bool {
        const r = toggleArea;
        return available && x >= r.x && x < r.x + r.width && y >= r.y && y < r.y + r.height;
    }

    skin: "BluetoothButton"
    visible: view?.shown ?? true

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (root.inToggle(mouse.x, mouse.y))
                Bluez.setEnabled(!root.on);
            else
                root.toggleDrop();
        }
    }
}
