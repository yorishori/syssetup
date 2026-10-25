pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "merge.js" as Merge

// Settings: what's changed now and then from the Settings panel, and what the
// shell remembers on its own. Kept out of the project, in
// $XDG_STATE_HOME/quickshell/settings.json (~/.local/state/…), merged over the
// defaults below. How the machine is set up (terminal, launcher entries,
// calendar, theme tokens…) is Setup's, in the project.
//
// The file is watched and re-read on save. If it is missing, defaults are
// used. If it is invalid, the last good settings stay and Health is told why.
//
// set(path, value) changes a setting: it applies immediately, and the file is
// rewritten shortly after the last change (atomically; the previous file is
// kept once per session as settings.json.bak).
Singleton {
    id: root

    readonly property var defaults: ({
        theme: "cyber",      // which theme (themes/<name>)
        screen: "DP-3",      // output name; empty or missing = the first screen
        wallpaper: {
            path: "",        // image file ("~/…" ok); empty = plain color
            fit: "fill",     // fill (crop), fit, center, tile
            color: "#2c2633" // the plain color; empty = the theme's background
        },
        // Minutes without input before each; 0 = never. Apps that inhibit
        // idle (fullscreen, games) and playing media hold both off.
        idle: {
            lock: 25,
            screenOff: 30
        },
        // The lock screen checks by itself once this many characters are typed
        // (your password's length); 0 = press Enter.
        passcode: 4,

        // Remembered by the shell.
        mutedApps: [],       // apps whose popups are silenced (lowercase names)
        // The last folder each kind of capture was saved to; empty = Setup's.
        folders: {
            screenshots: "",
            recordings: "",
            voice: ""
        }
    })

    readonly property string dir: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/quickshell`

    property var values: defaults

    readonly property string theme: values.theme
    readonly property string screen: values.screen
    readonly property var wallpaper: values.wallpaper
    readonly property var idle: values.idle
    readonly property int passcode: values.passcode
    readonly property var mutedApps: values.mutedApps
    readonly property var folders: values.folders

    // The setting at a dotted path, e.g. get("idle.lock").
    function get(path: string): var {
        return path.split(".").reduce((o, k) => o?.[k], values);
    }

    // Change a setting; applied now, written to settings.json shortly after.
    function set(path: string, value: var): void {
        const next = JSON.parse(JSON.stringify(values));
        const keys = path.split(".");
        let node = next;
        for (const k of keys.slice(0, -1))
            node = node[k] = node[k] ?? {};
        node[keys[keys.length - 1]] = value;
        values = next;
        writeDelay.restart();
    }

    property string loadedText: ""   // file content as last read
    property string writtenText: ""  // what we last wrote (to ignore its echo)
    property bool backedUp: false

    function write(): void {
        const text = JSON.stringify(values, null, 2) + "\n";
        if (text === loadedText)
            return;
        if (!backedUp && loadedText) {
            backup.setText(loadedText);
            backedUp = true;
        }
        writtenText = text;
        file.setText(text);
    }

    Timer {
        id: writeDelay
        interval: 400
        onTriggered: root.write()
    }

    FileView {
        id: backup
        path: `${root.dir}/settings.json.bak`
        blockLoading: true
        printErrors: false
    }

    // qs ipc call config <get PATH|set PATH JSON|add PATH ITEM|remove PATH ITEM>
    //   config set theme '"bubble"'      config add mutedApps steam
    IpcHandler {
        target: "config"

        function get(path: string): string {
            return JSON.stringify(root.get(path), null, 2) ?? "undefined";
        }
        function set(path: string, json: string): string {
            let value;
            try {
                value = JSON.parse(json);
            } catch (e) {
                return `not JSON: ${e.message} (strings need quotes: '"text"')`;
            }
            if (root.get(path) === undefined)
                return `unknown setting: ${path}`;
            root.set(path, value);
            return "ok";
        }
        // For list settings (qs ipc splits arguments on commas, so JSON
        // lists can't be passed to set): add / remove one text item.
        function add(path: string, item: string): string {
            const list = root.get(path);
            if (!Array.isArray(list))
                return `not a list: ${path}`;
            root.set(path, [...list, item]);
            return "ok";
        }
        function remove(path: string, item: string): string {
            const list = root.get(path);
            if (!Array.isArray(list))
                return `not a list: ${path}`;
            root.set(path, list.filter(i => i !== item));
            return "ok";
        }
    }

    FileView {
        id: file

        path: `${root.dir}/settings.json`
        watchChanges: true
        atomicWrites: true
        printErrors: false

        onFileChanged: reload()

        onLoaded: {
            const content = text();
            root.loadedText = content;
            // Our own write coming back: values are already current.
            if (content === root.writtenText)
                return;
            try {
                root.values = Merge.merge(root.defaults, JSON.parse(content));
                Health.resolve("config");
            } catch (e) {
                Health.report("config", `settings.json is invalid, keeping previous values: ${e.message}`);
            }
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.values = root.defaults;
            } else {
                Health.report("config", `cannot read settings.json: ${FileViewError.toString(error)}`);
            }
        }
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.dir])
}
