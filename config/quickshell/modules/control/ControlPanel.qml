import QtQuick
import qs.components
import qs.core
import qs.services

// Control center: system readouts, pending updates, storage, USB devices and
// tool keys. The skin (ControlMenu) lays it out, and scrolls if it's taller
// than the screen allows (`maxHeight`). Live readings only run while it's
// open.
Skinned {
    id: root

    property bool open: false
    property real maxHeight: 900

    // Emitted after launching something, so the bar closes and the new window
    // gets focus.
    signal done

    // What the skin shows. The services stay private to the panel: a skin
    // reads these, so renaming something in a service changes this file, not
    // every theme.

    // The machine (Sysinfo). Usage is 0..1; temperatures °C (-1 = unknown);
    // memory KiB, VRAM MiB.
    readonly property string os: Sysinfo.os
    readonly property string kernel: Sysinfo.kernel
    readonly property bool rebootPending: Sysinfo.rebootPending
    readonly property string board: Sysinfo.board
    readonly property string cpuName: Sysinfo.cpu
    readonly property string gpuName: Sysinfo.gpu.replace(/^NVIDIA /, "")
    readonly property real cpuUsage: Sysinfo.cpuUsage
    readonly property real gpuUsage: Sysinfo.gpuUsage
    readonly property int cpuTemp: Sysinfo.cpuTemp
    readonly property int gpuTemp: Sysinfo.gpuTemp
    // Hot enough to say so.
    readonly property int hotTemp: 85
    readonly property bool cpuHot: cpuTemp >= hotTemp
    readonly property bool gpuHot: gpuTemp >= hotTemp
    readonly property real memUsed: Sysinfo.memUsed
    readonly property real memTotal: Sysinfo.memTotal
    readonly property real gpuMemUsed: Sysinfo.gpuMemUsed
    readonly property real gpuMemTotal: Sysinfo.gpuMemTotal

    // Pending updates (Updates). `updateCounts`: { core, extra, multilib, aur }.
    readonly property bool updatesChecking: Updates.checking
    readonly property bool updatesFailed: Updates.failed
    readonly property int updateCount: Updates.count
    readonly property var updateCounts: Updates.counts
    readonly property string aurHelper: Updates.aurHelper
    readonly property string lastUpgrade: Updates.lastUpgrade  // ISO date, "" = never

    // Disks, shares and USB devices (Storage); see Storage for each list's
    // fields. `storageError` is the last mount/eject failure.
    readonly property var mounted: Storage.mounted
    readonly property var mountable: Storage.mountable
    readonly property var shares: Storage.network
    readonly property var usb: Storage.usb
    readonly property string storageError: Storage.error

    // This machine (Session).
    readonly property string hostname: Session.hostname
    readonly property string uptimeText: Session.uptimeText

    // Your tools (Setup.tools: [{ label, command }]).
    readonly property var tools: Setup.tools

    skin: "ControlMenu"

    function run(command: string): void {
        Launcher.runInTerminal(command);
        done();
    }
    // The mount point is outside text (a drive's label), so never part of a
    // command line.
    function inspect(mountPoint: string): void {
        Launcher.execInTerminal(["ncdu", "-x", mountPoint]);
        done();
    }
    function upgrade(): void {
        Updates.upgrade();
        done();
    }
    function checkUpdates(): void {
        Updates.check(true);
    }
    function openSettings(): void {
        Panels.open("settings");
    }
    function mount(device: string): void {
        Storage.mount(device);
    }
    function eject(device: string): void {
        Storage.eject(device);
    }
    function connect(mountPoint: string): void {
        Storage.connect(mountPoint);
    }

    // Sizes as the skin shows them: "1.5G", memory as "7.8" (GiB).
    function sizeText(bytes: real): string {
        return Storage.human(bytes);
    }
    function gib(kib: real): string {
        return Sysinfo.gib(kib);
    }

    function percent(v: real): string {
        return String(Math.round(Math.max(0, Math.min(1, v)) * 100)).padStart(3, "0");
    }

    function ago(iso: string): string {
        if (!iso)
            return "never";
        const days = Math.floor((Date.now() - new Date(iso).getTime()) / 86400000);
        return days <= 0 ? "today" : days === 1 ? "yesterday" : `${days} days ago`;
    }

    // Live readings while open.
    Live { target: Sysinfo; when: root.open }
    Live { target: Storage; when: root.open }

    onOpenChanged: {
        if (open) {
            Session.refresh();
            Updates.check(false);
        }
    }
}
