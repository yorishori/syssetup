import QtQuick
import Quickshell.Bluetooth
import qs.components
import qs.services

// Bluetooth: power and scan, then the devices, CONNECTED (with battery),
// PAIRED, NEARBY (found by a scan), and for one of them its actions. The
// skin (BluetoothMenu) lays it out and keeps which device is picked.
Skinned {
    id: root

    property bool open: false

    readonly property bool powered: Bluez.enabled
    readonly property bool discovering: Bluez.discovering
    readonly property string adapterName: Bluez.adapter?.name ?? ""
    readonly property var devices: Bluez.devices
    readonly property var connected: Bluez.enabled ? Bluez.connected : []
    readonly property var paired: Bluez.enabled ? Bluez.paired : []
    readonly property var nearby: Bluez.enabled ? Bluez.nearby : []
    readonly property bool busy: Bluez.busy
    // Why the last pair or connect failed, as BlueZ put it, and on which
    // device (its address).
    readonly property string error: Bluez.error
    readonly property string errorFor: Bluez.errorFor

    skin: "BluetoothMenu"

    function glyph(device: BluetoothDevice): string {
        return Bluez.glyph(device);
    }
    // Pairing, connecting or disconnecting.
    function busyWith(device: BluetoothDevice): bool {
        return !!device && (Bluez.pending === device.address || device.pairing
            || device.state === BluetoothDeviceState.Connecting
            || device.state === BluetoothDeviceState.Disconnecting);
    }
    function failed(device: BluetoothDevice): bool {
        return !!device && !busyWith(device) && Bluez.errorFor === device.address;
    }
    function scan(): void {
        Bluez.scan();
    }
    function setEnabled(on: bool): void {
        Bluez.setEnabled(on);
    }
    function connect(device: BluetoothDevice): void {
        Bluez.connect(device);
    }
    function pair(device: BluetoothDevice): void {
        Bluez.pair(device);
    }
    function disconnect(device: BluetoothDevice): void {
        device.disconnect();
    }
    function forget(device: BluetoothDevice): void {
        device.forget();
    }
}
