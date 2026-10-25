pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The panels, and which one is open (at most one): the single source of
// truth shared by the bar (its drops), the clipboard and compose windows, bar
// keys, the keys cheat sheet and IPC (`qs ipc call panel toggle launcher`).
Singleton {
    id: root

    property string current: ""

    // Every panel, once. `label` names it (the keys cheat sheet). `host` is
    // what shows it: "bar" for a drop (modules/<name>/<Name>Panel.qml) hung
    // under the bar widget `under`, flush to a screen edge with `edge`,
    // darkening and blurring the rest of the screen with `blur`, as tall as
    // the screen allows with `tall`; "window" for a module with its own window
    // (a ModuleLoader in shell.qml) that follows isOpen(name). scripts/check.sh
    // checks the files and widgets named here exist.
    readonly property var registry: [
        { name: "session", label: "Session menu", host: "bar", under: "PowerButton", edge: "left", blur: true },
        { name: "calendar", label: "Calendar", host: "bar", under: "Clock" },
        { name: "launcher", label: "Launcher", host: "bar", under: "Workspaces", blur: true },
        { name: "network", label: "Network", host: "bar", under: "NetworkButton" },
        { name: "bluetooth", label: "Bluetooth", host: "bar", under: "BluetoothButton" },
        { name: "audio", label: "Audio", host: "bar", under: "AudioButton" },
        { name: "notifications", label: "Notifications", host: "bar", under: "NotifIndicator" },
        { name: "control", label: "Control center", host: "bar", under: "ControlButton", edge: "right", blur: true, tall: true },
        { name: "settings", label: "Settings", host: "bar", under: "Workspaces", blur: true, tall: true },
        { name: "keys", label: "This cheat sheet", host: "bar", under: "Workspaces", blur: true, tall: true },
        { name: "clipboard", label: "Clipboard history", host: "window" },
        { name: "compose", label: "Compose", host: "window" }
    ]

    // The panels IPC can open. The bar's tray menu is a panel too ("tray"),
    // but opens on an app's icon (`tray menu APP`).
    readonly property var names: registry.map(p => p.name)

    function unknown(name: string): string {
        return `no panel "${name}"; panels: ${names.join(", ")}`;
    }

    // A name that's no panel is a typo somewhere: say so, once.
    property var warned: ({})

    function check(name: string): void {
        if (name === "tray" || names.includes(name) || warned[name])
            return;
        warned[name] = true;
        console.warn(`[panels] ${unknown(name)}`);
    }

    function open(name: string): void {
        check(name);
        current = name;
    }

    function close(): void {
        current = "";
    }

    function toggle(name: string): void {
        check(name);
        current = current === name ? "" : name;
    }

    function isOpen(name: string): bool {
        check(name);
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
