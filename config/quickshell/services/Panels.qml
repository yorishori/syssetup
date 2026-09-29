pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Which panel is open (at most one): the single source of truth shared by
// the bar (its drops), the clipboard window, bar keys and IPC.
//
// Every panel answers `qs ipc call <panel> toggle|open|close`. Most
// of those handlers live in the panel's service (audio, network, …); the ones
// without a service of their own are here.
Singleton {
    id: root

    // Panels shown as drops from the bar.
    readonly property var barPanels: ["launcher", "calendar", "tray", "network", "bluetooth", "audio", "notifications", "control", "session", "settings", "keys"]

    property string current: ""

    function open(name: string): void {
        current = name;
    }

    function close(): void {
        current = "";
    }

    function toggle(name: string): void {
        current = current === name ? "" : name;
    }

    function isOpen(name: string): bool {
        return current === name;
    }

    // Panels without a service of their own.
    IpcHandler {
        target: "calendar"

        function toggle(): void { root.toggle("calendar"); }
        function open(): void { root.open("calendar"); }
        function close(): void {
            if (root.isOpen("calendar"))
                root.close();
        }
    }

    IpcHandler {
        target: "control"

        function toggle(): void { root.toggle("control"); }
        function open(): void { root.open("control"); }
        function close(): void {
            if (root.isOpen("control"))
                root.close();
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void { root.toggle("settings"); }
        function open(): void { root.open("settings"); }
        function close(): void {
            if (root.isOpen("settings"))
                root.close();
        }
    }

    // qs ipc call panels <current|close>
    IpcHandler {
        target: "panels"

        function current(): string { return root.current || "none"; }
        function close(): void { root.close(); }
    }
}
