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

    // What it shows: CPU, GPU, memory, board, kernel (Sysinfo); pending
    // updates per repository (Updates); disks, shares and USB devices
    // (Storage); the hostname and uptime (Session); your tools (Setup.tools:
    // [{ label, command }]).
    readonly property var system: Sysinfo
    readonly property var updates: Updates
    readonly property var storage: Storage
    readonly property var session: Session
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

    function percent(v: real): string {
        return String(Math.round(Math.max(0, Math.min(1, v)) * 100)).padStart(3, "0");
    }

    function ago(iso: string): string {
        if (!iso)
            return "never";
        const days = Math.floor((Date.now() - new Date(iso).getTime()) / 86400000);
        return days <= 0 ? "today" : days === 1 ? "yesterday" : `${days} days ago`;
    }

    onOpenChanged: {
        Sysinfo.active = open;
        Storage.active = open;
        if (open) {
            Session.refresh();
            Updates.check(false);
        }
    }
}
