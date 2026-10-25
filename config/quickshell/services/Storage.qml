pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Mounted filesystems (capacity), removable drives that can be mounted, and
// connected USB devices. Refreshed every 3s while something shows them (a
// `Live { target: Storage }`, e.g. the control center while open), so plugging
// something in shows up right away; idle otherwise.
Singleton {
    id: root

    property int users: 0
    readonly property bool active: users > 0

    // [{ device, name, mount, fstype, size, used, avail, removable }]
    property var mounted: []
    // Filesystems on removable drives that aren't mounted: [{ device, name, fstype, size }]
    property var mountable: []
    // [{ name, id }], hubs left out
    property var usb: []
    // Network shares (NFS, SMB, sshfs, …) managed by systemd mount/automount
    // units: [{ mount, source, fstype, state: "mounted"|"idle"|"failed"|"off",
    //           reason, size, used, avail, description }]
    property var network: []

    property string error: ""

    function refresh(): void {
        if (!reader.running)
            reader.running = true;
    }

    function mount(device: string): void { action(["udisksctl", "mount", "-b", device]); }

    // Wake an automounted share by opening its path, like a file manager
    // would (no root needed); then refresh.
    function connect(mountPoint: string): void {
        action(["timeout", "15", "ls", mountPoint]);
    }
    function unmount(device: string): void { action(["udisksctl", "unmount", "-b", device]); }

    // Unmount, then power off the whole drive so it can be pulled safely.
    function eject(device: string): void {
        action(["sh", "-c", `udisksctl unmount -b "$1" && udisksctl power-off -b "/dev/$(lsblk -no PKNAME "$1")"`, "sh", device]);
    }

    function action(command: var): void {
        error = "";
        runner.run(command);
    }

    function human(bytes: real): string {
        const units = ["B", "K", "M", "G", "T"];
        let i = 0;
        while (bytes >= 1024 && i < units.length - 1) {
            bytes /= 1024;
            i++;
        }
        return `${bytes.toFixed(bytes < 10 && i > 0 ? 1 : 0)}${units[i]}`;
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: reader

        command: ["sh", Quickshell.shellPath("scripts/storage-scan.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                const usb = [], network = [];
                for (const line of text.split("\n")) {
                    if (line.startsWith("net\t")) {
                        const [, mount, source, fstype, active, result, auto, sizes, description] = line.split("\t");
                        const [size, used, avail] = (sizes ?? "").trim().split(/\s+/).map(Number);
                        network.push({
                            mount, source, fstype, description,
                            state: active === "active" ? "mounted"
                                : active === "failed" || result !== "success" ? "failed"
                                : auto === "active" ? "idle" : "off",
                            reason: result,
                            size: size || 0, used: used || 0, avail: avail || 0
                        });
                        continue;
                    }
                    if (line.startsWith("lsblk "))
                        root.parseBlocks(line.slice(6));
                    else if (line.startsWith("usb ")) {
                        const m = line.match(/ID (\w+:\w+) (.*)$/);
                        if (m && !/hub/i.test(m[2]))
                            usb.push({ id: m[1], name: m[2].replace(/,? (Inc\.|Co\., Ltd\.|Ltd\.|Corp\.|Corporation|GmbH|& Consulting)/g, "").replace(/\s+/g, " ") });
                    }
                }
                root.usb = usb;
                root.network = network.sort((a, b) => a.mount.localeCompare(b.mount));
            }
        }
    }

    function parseBlocks(json: string): void {
        let data;
        try {
            data = JSON.parse(json);
        } catch (e) {
            return;
        }
        const mounted = [], mountable = [];
        const walk = (nodes, removable) => {
            for (const n of nodes ?? []) {
                const rem = removable || n.rm || n.hotplug;
                const fs = n.fstype && !["LVM2_member", "swap", "crypto_LUKS"].includes(n.fstype);
                if (n.mountpoint && n.mountpoint !== "[SWAP]" && n.fsused !== null)
                    mounted.push({
                        device: n.path, name: n.label || n.name, mount: n.mountpoint, fstype: n.fstype,
                        size: Number(n.size), used: Number(n.fsused), avail: Number(n.fsavail), removable: rem
                    });
                else if (!n.mountpoint && fs && rem && n.type === "part")
                    mountable.push({ device: n.path, name: n.label || n.name, fstype: n.fstype, size: Number(n.size) });
                walk(n.children, rem);
            }
        };
        walk(data.blockdevices, false);
        mounted.sort((a, b) => a.mount.localeCompare(b.mount));
        root.mounted = mounted;
        root.mountable = mountable;
    }

    Action {
        id: runner

        keepStdout: false
        onDone: (ok, output) => {
            if (!ok)
                root.error = output || "failed";
            root.refresh();
        }
    }
}
