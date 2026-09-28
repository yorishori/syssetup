pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Wi-Fi via iwd and wired links via systemd-networkd, both read over D-Bus.
//
// No polling: state is re-read whenever either daemon emits a D-Bus signal.
// Actions go through busctl, except connecting, which uses iwctl because it
// can supply a passphrase for new networks.
Singleton {
    id: root

    // Wi-Fi (iwd)
    property bool iwdRunning: false
    property string device: ""         // D-Bus path of the Wi-Fi device
    property string interfaceName: ""  // e.g. wlan0
    property bool wifiEnabled: false
    property bool scanning: false
    property string state: ""          // iwd station state: connected, connecting, disconnected, ...
    // Visible networks, strongest first:
    // { path, name, secure, known, knownPath, connected, strength (0-100) }
    property var networks: []
    readonly property var connected: networks.find(n => n.connected) ?? null

    // Wired (systemd-networkd): physical ethernet links it manages.
    property bool networkdRunning: false
    property var wired: []  // { name, connected }
    readonly property bool wiredConnected: wired.some(l => l.connected)

    // Actions: one at a time. `pending` is the network being connected to.
    readonly property bool busy: action.running
    property string pending: ""
    property string error: ""

    function refresh(): void {
        debounce.restart();
    }

    function scan(): void {
        run(["busctl", "--system", "call", "net.connman.iwd", device, "net.connman.iwd.Station", "Scan"]);
    }

    function connect(network: var, passphrase: string): void {
        pending = network.name;
        run(["iwctl", ...(passphrase ? ["--passphrase", passphrase] : []), "station", interfaceName, "connect", network.name]);
    }

    function disconnect(): void {
        run(["busctl", "--system", "call", "net.connman.iwd", device, "net.connman.iwd.Station", "Disconnect"]);
    }

    function forget(network: var): void {
        run(["busctl", "--system", "call", "net.connman.iwd", network.knownPath, "net.connman.iwd.KnownNetwork", "Forget"]);
    }

    function setWifiEnabled(enabled: bool): void {
        run(["busctl", "--system", "set-property", "net.connman.iwd", device, "net.connman.iwd.Device", "Powered", "b", String(enabled)]);
    }

    function run(command: var): void {
        if (action.running)
            return;
        error = "";
        action.command = ["sh", "-c", '"$@" 2>&1; echo "exit:$?"', "sh", ...command];
        action.running = true;
    }

    // iwd reports signal in 1/100 dBm; map -100..-50 dBm to 0..100.
    function quality(signal: int): int {
        return Math.max(0, Math.min(100, 2 * (signal / 100 + 100)));
    }

    function parseIwd(objects: var, ordered: var): void {
        const objs = objects.data[0];
        const props = (path, iface) => {
            const raw = objs[path]?.[`net.connman.iwd.${iface}`];
            if (!raw)
                return null;
            const out = {};
            for (const key in raw)
                out[key] = raw[key].data;
            return out;
        };

        device = Object.keys(objs).find(p => objs[p]["net.connman.iwd.Device"]) ?? "";
        const dev = props(device, "Device");
        const station = props(device, "Station");
        interfaceName = dev?.Name ?? "";
        wifiEnabled = dev?.Powered ?? false;
        scanning = station?.Scanning ?? false;
        state = station?.State ?? "";

        networks = (ordered?.data[0] ?? []).map(([path, signal]) => {
            const net = props(path, "Network") ?? {};
            return {
                path,
                name: net.Name ?? "",
                secure: net.Type !== "open",
                known: !!net.KnownNetwork,
                knownPath: net.KnownNetwork ?? "",
                connected: net.Connected ?? false,
                strength: quality(signal)
            };
        });
    }

    function parseLinks(links: var): void {
        wired = links.Interfaces
            .filter(l => l.Type === "ether" && l.Driver !== "veth" && l.AdministrativeState !== "unmanaged")
            .map(l => ({ name: l.Name, connected: l.OperationalState === "routable" }));
    }

    Timer {
        id: debounce
        interval: 150
        onTriggered: reader.running = true
    }

    // Prints "objects <json>", "ordered <json>" and "links <json>" lines.
    Process {
        id: reader

        running: true
        command: ["sh", "-c", `
            o=$(busctl --system --json=short call net.connman.iwd / org.freedesktop.DBus.ObjectManager GetManagedObjects 2>/dev/null) \
                && echo "objects $o"
            for p in $(busctl --system tree --list net.connman.iwd 2>/dev/null | grep -E '^/net/connman/iwd/[0-9]+/[0-9]+$'); do
                r=$(busctl --system --json=short call net.connman.iwd "$p" net.connman.iwd.Station GetOrderedNetworks 2>/dev/null) \
                    && echo "ordered $r" && break
            done
            l=$(networkctl --json=short list 2>/dev/null) && echo "links $l"
            true`]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = {};
                for (const line of text.split("\n")) {
                    const space = line.indexOf(" ");
                    if (space > 0)
                        lines[line.slice(0, space)] = JSON.parse(line.slice(space + 1));
                }

                root.iwdRunning = !!lines.objects;
                if (lines.objects)
                    root.parseIwd(lines.objects, lines.ordered);
                else
                    root.networks = [];

                root.networkdRunning = !!lines.links;
                if (lines.links)
                    root.parseLinks(lines.links);
            }
        }
    }

    Process {
        id: action

        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.replace(/\x1b\[[0-9;]*m/g, "").trim().split("\n");
                const code = out.pop();
                if (code !== "exit:0")
                    root.error = out.join(" ").trim() || "action failed";
                root.pending = "";
                root.refresh();
            }
        }
    }

    // Any signal from either daemon means something changed.
    component Monitor: Process {
        id: monitor

        required property string dest

        running: true
        command: ["gdbus", "monitor", "--system", "--dest", dest]
        stdout: SplitParser {
            onRead: root.refresh()
        }
        // gdbus exiting is unexpected; bring it back.
        onExited: restartTimer.start()

        readonly property Timer restartTimer: Timer {
            interval: 5000
            onTriggered: monitor.running = true
        }
    }

    Monitor { dest: "net.connman.iwd" }
    Monitor { dest: "org.freedesktop.network1" }

    HealthCheck {
        source: "wifi"
        ok: root.iwdRunning && root.device !== ""
        reason: root.iwdRunning ? "iwd has no Wi-Fi device" : "iwd is not running"
    }

    HealthCheck {
        source: "wired"
        ok: root.networkdRunning
        reason: "systemd-networkd is not reachable"
    }

    // qs ipc call network <toggle|open|close|status|scan|wifi on/off|connect NAME|disconnect>
    IpcHandler {
        target: "network"

        function toggle(): void { Panels.toggle("network"); }
        function open(): void { Panels.open("network"); }
        function close(): void {
            if (Panels.isOpen("network"))
                Panels.close();
        }

        function status(): string {
            const wifi = !root.iwdRunning ? "iwd not running"
                : !root.wifiEnabled ? "off"
                : root.connected ? `${root.connected.name} (${root.connected.strength}%)`
                : root.state || "disconnected";
            const wired = root.wired.map(l => `${l.name}: ${l.connected ? "connected" : "no link"}`).join(", ");
            return `wifi: ${wifi}${wired ? "\nwired: " + wired : ""}`;
        }
        function scan(): void { root.scan(); }
        function wifi(enabled: bool): void { root.setWifiEnabled(enabled); }
        function connect(name: string): void {
            const network = root.networks.find(n => n.name === name);
            if (network)
                root.connect(network, "");
        }
        function disconnect(): void { root.disconnect(); }
    }
}
