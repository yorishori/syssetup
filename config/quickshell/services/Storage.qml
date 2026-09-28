pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Mounted filesystems (capacity), removable drives that can be mounted, and
// connected USB devices. Refreshed every 3s while `active` (control center
// open), so plugging something in shows up right away; idle otherwise.
Singleton {
    id: root

    property bool active: false

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
        runner.command = ["sh", "-c", '"$@" 2>&1 >/dev/null; echo "exit:$?"', "sh", ...command];
        runner.running = true;
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

        command: ["sh", "-c", `
            echo "lsblk $(lsblk -J -b -o PATH,NAME,SIZE,FSUSED,FSAVAIL,MOUNTPOINT,FSTYPE,LABEL,RM,HOTPLUG,TYPE 2>/dev/null | tr -d '\\n')"
            lsusb 2>/dev/null | sed 's/^/usb /'
            # Network shares from systemd units. Only unit state is read, never
            # the path, so looking can't trigger an automount; capacity is only
            # asked for when already mounted, with a timeout for dead servers.
            for unit in $(systemctl list-units --all --plain --no-legend --type=automount,mount | awk '{print $1}'); do
                case "$unit" in *.automount) m="\${unit%.automount}.mount" ;; *.mount) m="$unit" ;; esac
                case "$m" in -*) continue ;; esac  # "-.mount" is / (and looks like an option)
                echo "$seen" | grep -qx "$m" && continue
                seen="$seen
$m"
                info=$(systemctl show "$m" -p Type -p Where -p What -p ActiveState -p Result -p Description)
                type=$(echo "$info" | sed -n 's/^Type=//p')
                case "$type" in nfs|nfs4|cifs|smb3|fuse.sshfs|davfs|9p) ;; *) continue ;; esac
                where=$(echo "$info" | sed -n 's/^Where=//p')
                state=$(echo "$info" | sed -n 's/^ActiveState=//p')
                sizes=""
                [ "$state" = active ] && sizes=$(timeout 2 df -B1 --output=size,used,avail "$where" 2>/dev/null | tail -1)
                auto=$(systemctl is-active "\${m%.mount}.automount" 2>/dev/null)
                printf 'net\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$where" \
                    "$(echo "$info" | sed -n 's/^What=//p')" "$type" "$state" \
                    "$(echo "$info" | sed -n 's/^Result=//p')" "$auto" "$sizes" \
                    "$(echo "$info" | sed -n 's/^Description=//p')"
            done`]
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

    Process {
        id: runner

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.pop() !== "exit:0")
                    root.error = lines.join(" ").trim() || "failed";
                root.refresh();
            }
        }
    }
}
