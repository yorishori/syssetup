pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Which panel is open (at most one): the single source of truth shared by
// the bar (its drops), the clipboard and compose windows, bar keys and IPC
// (`qs ipc call panel toggle launcher`).
Singleton {
    id: root

    property string current: ""

    // The panels IPC can open (a tray menu opens with `tray menu APP`).
    readonly property var names: ["session", "calendar", "launcher", "network", "bluetooth", "audio",
        "notifications", "control", "settings", "keys", "clipboard", "compose"]

    function unknown(name: string): string {
        return `no panel "${name}"; panels: ${names.join(", ")}`;
    }

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

    // A panel doesn't follow a workspace switch (keys, Super+Tab, the bar),
    // so it closes.
    Connections {
        target: Wm

        function onActiveWorkspaceChanged(): void {
            root.close();
        }
    }

    // qs ipc call panel <toggle NAME|open NAME|close|current>
    IpcHandler {
        target: "panel"

        function toggle(name: string): string {
            if (!root.names.includes(name))
                return root.unknown(name);
            root.toggle(name);
            return "";
        }
        function open(name: string): string {
            if (!root.names.includes(name))
                return root.unknown(name);
            root.open(name);
            return "";
        }
        function close(): void { root.close(); }
        function current(): string { return root.current || "none"; }
    }
}
