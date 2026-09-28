pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import qs.core

// Bluetooth via BlueZ (Quickshell.Bluetooth). Named Bluez so it doesn't clash
// with Quickshell's own `Bluetooth` type.
Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false

    // Named devices only (unnamed ones are just addresses nobody recognizes).
    readonly property var devices: (adapter?.devices.values ?? []).filter(d => d.name && d.name !== d.address.replace(/:/g, "-"))
    readonly property var connected: devices.filter(d => d.connected)
    readonly property var paired: devices.filter(d => d.paired && !d.connected)
    readonly property var nearby: devices.filter(d => !d.paired && !d.connected)

    function setEnabled(on: bool): void {
        if (adapter)
            adapter.enabled = on;
    }

    // Discovery floods the air and the list, so it runs for a while and stops.
    function scan(): void {
        if (!adapter || !enabled)
            return;
        adapter.discovering = true;
        stopScan.restart();
    }

    function connect(device: BluetoothDevice): void {
        device.trusted = true;  // so it reconnects on its own later
        device.connect();
    }

    function pair(device: BluetoothDevice): void {
        device.trusted = true;
        device.pair();
    }

    // Glyph for a device, from the type BlueZ reports.
    function glyph(device: BluetoothDevice): string {
        const icon = device?.icon ?? "";
        return icon.includes("headset") || icon.includes("headphone") ? "\u{F02CB}"
            : icon.includes("audio") ? "\u{F04C3}"
            : icon.includes("mouse") ? "\u{F037D}"
            : icon.includes("keyboard") ? "\u{F030C}"
            : icon.includes("gaming") ? "\u{F0297}"
            : icon.includes("phone") ? "\u{F011C}"
            : icon.includes("computer") ? "\u{F07C0}"
            : "\u{F00AF}";
    }

    Timer {
        id: stopScan
        interval: 20000
        onTriggered: {
            if (root.adapter)
                root.adapter.discovering = false;
        }
    }

    HealthCheck {
        source: "bluetooth"
        ok: root.available
        reason: "no Bluetooth adapter (is bluetooth.service running?)"
        grace: 5000
    }

    // qs ipc call bluetooth <toggle|open|close|status|power on/off|scan|connect NAME|disconnect NAME>
    IpcHandler {
        target: "bluetooth"

        function toggle(): void { Panels.toggle("bluetooth"); }
        function open(): void { Panels.open("bluetooth"); }
        function close(): void {
            if (Panels.isOpen("bluetooth"))
                Panels.close();
        }

        function status(): string {
            if (!root.available)
                return "no adapter";
            if (!root.enabled)
                return "off";
            const line = d => `${d.name}${d.batteryAvailable ? ` (${Math.round(d.battery * 100)}%)` : ""}`;
            return `on${root.discovering ? ", scanning" : ""}\nconnected: ${root.connected.map(line).join(", ") || "none"}\npaired: ${root.paired.map(d => d.name).join(", ") || "none"}`;
        }
        function power(on: bool): void { root.setEnabled(on); }
        function scan(): void { root.scan(); }
        function connect(name: string): void {
            const d = root.devices.find(x => x.name.toLowerCase().includes(name.toLowerCase()));
            if (d)
                root.connect(d);
        }
        function disconnect(name: string): void {
            const d = root.connected.find(x => x.name.toLowerCase().includes(name.toLowerCase()));
            d?.disconnect();
        }
    }
}
