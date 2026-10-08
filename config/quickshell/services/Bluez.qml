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

    // Pair and connect go through busctl rather than the device's own pair() /
    // connect(), which drop BlueZ's reply: this way a failure comes back as text.
    // One at a time. `pending` is the address being worked on; `error` is the
    // last failure and `errorFor` the address it belongs to (shown under its row).
    readonly property bool busy: action.running
    property string pending: ""
    property string error: ""
    property string errorFor: ""

    function connect(device: BluetoothDevice): void {
        device.trusted = true;  // so it reconnects on its own later
        run(device, ["Connect"]);
    }

    // Pairing alone leaves the device bonded but disconnected, so follow through.
    function pair(device: BluetoothDevice): void {
        device.trusted = true;
        run(device, ["Pair", "Connect"]);
    }

    // Calls each Device1 method in order, stopping at the first that fails.
    function run(device: BluetoothDevice, methods: var): void {
        if (action.running)
            return;
        const path = device.dbusPath || `/org/bluez/${adapter?.adapterId || "hci0"}/dev_${device.address.replace(/:/g, "_")}`;
        pending = device.address;
        error = "";
        errorFor = "";
        action.command = ["sh", "-c", '"$@" 2>&1; echo "exit:$?"', "sh",
            "sh", "-c", 'p=$1; shift; for m; do busctl --system --timeout=60 call org.bluez "$p" org.bluez.Device1 "$m" || exit; done', "sh",
            path, ...methods];
        action.running = true;
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

    Process {
        id: action

        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim().split("\n");
                const code = out.pop();
                if (code !== "exit:0") {
                    root.error = out.join(" ").replace(/^Call failed:\s*/, "").trim() || "action failed";
                    root.errorFor = root.pending;
                    console.warn(`bluetooth: ${root.pending}: ${root.error}`);
                }
                root.pending = "";
            }
        }
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
