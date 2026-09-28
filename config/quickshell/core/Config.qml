pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User settings from config.json, merged over the defaults below.
//
// The file is watched and re-read on save. If it is missing, defaults are used.
// If it is invalid, the last good config stays active and Health is told why.
//
// set(path, value) changes a setting (the settings panel uses it): it applies
// immediately, and the file is rewritten shortly after the last change
// (atomically; the previous file is kept once per session as config.json.bak).
// Hand edits keep working alongside.
Singleton {
    id: root

    readonly property var defaults: ({
        screen: "",  // output name, e.g. "DP-3"; empty = first screen
        font: {
            family: "JetBrainsMono Nerd Font",
            size: 13
        },
        // Catppuccin Mocha, by role.
        colors: {
            bg: "#11111b",       // crust: the console (bar and drops)
            bgAlt: "#181825",    // mantle: recessed wells (meters, inputs)
            shadow: "#11111b",   // crust: text on lit surfaces
            surface: "#313244",  // surface0: hover, unlit segments
            border: "#45475a",   // surface1: hairlines
            fg: "#cdd6f4",       // text: primary content
            dim: "#a6adc8",      // subtext0: calm state (bar default)
            muted: "#6c7086",    // overlay0: empty, secondary
            off: "#99eba0ac",    // maroon at 60%: switched off by you (mute, DND, radio off)
            accent: "#94e2d5",   // teal: lit / active / in use
            ok: "#a6e3a1",       // green: up / healthy (server lamps)
            warn: "#fab387",     // peach: needs attention
            error: "#f38ba8"     // red: broken
        },
        wallpaper: {
            path: "",            // image file ("~/…" ok); empty = plain color
            fit: "fill",         // fill (crop), fit, center, tile
            color: ""            // the plain color; empty = colors.bg
        },
        // Retro-futurist geometry and effects.
        shape: {
            cut: 6,              // size of the 45-degree corner cuts, px
            border: 1            // hairline width, px
        },
        effects: {
            glow: 0.6,           // phosphor glow on lit elements, 0 = off
            scanlines: 0.25,     // scanline strength on panels, 0 = off
            backdrop: 0.45       // darkening behind the launcher, 0 = off
        },
        bar: {
            height: 32,
            padding: 12,
            spacing: 16,
            workspaces: 5  // minimum number of workspaces shown
        },
        launcher: {
            terminal: ["kitty", "-e"],                   // prefix for terminal commands
            search: "https://duckduckgo.com/?q=%s",      // web search URL (%s = query)
            // Your own entries: { name, command, description?, icon?, terminal?, keywords? }
            entries: []
        },
        calendar: {
            weekStart: 1,        // first day of the week: 1 = Monday, 0 = Sunday
            // CalDAV server (read-only); login from ~/.netrc. Empty = no events.
            url: "",
            // One color per calendar, in the order the server lists them.
            colors: ["#94e2d5", "#cba6f7", "#89b4fa", "#a6e3a1", "#f5c2e7", "#fab387"]
        },
        // Minutes without input before each step; 0 = never. Apps that inhibit
        // idle (video players, games) hold both off.
        idle: {
            lock: 10,
            screenOff: 15
        },
        lock: {
            // Passcode mode: check automatically once this many characters are
            // typed (must equal your password's length). 0 = off, press Enter.
            passcode: 0
        },
        // Home server for the control center's SERVER section (empty host = hidden).
        server: {
            name: "",
            host: "",       // for the ping
            ssh: "",        // optional terminal command for the SSH key, e.g. "ssh koi-server"
            services: []    // { name, url }: a lamp each, checked over HTTP
        },
        controlCenter: {
            // Tool keys; each command opens in the terminal (launcher.terminal).
            tools: [
                { label: "btop", command: "btop" },
                { label: "nyst", command: "nyst" },
                { label: "sensors", command: "watch -n1 sensors" }
            ]
        },
        // Folders the capture prompt suggests (the last one used is remembered).
        capture: {
            screenshots: "~/Pictures/Screenshots",
            recordings: "~/Videos/Recordings",
            voice: "~/Music/Voice"
        },
        clipboard: {
            // Window classes that paste with Ctrl+Shift+V instead of Ctrl+V.
            terminals: ["kitty", "com.mitchellh.ghostty", "ghostty", "foot", "Alacritty", "org.wezfurlong.wezterm"]
        },
        notifications: {
            timeout: 5,     // seconds a popup stays up when the app doesn't say
            mutedApps: []   // apps whose popups are silenced (lowercase names)
        }
    })

    property var values: defaults

    readonly property string screen: values.screen
    readonly property var font: values.font
    readonly property var colors: values.colors
    readonly property var wallpaper: values.wallpaper
    readonly property var idle: values.idle
    readonly property var shape: values.shape
    readonly property var effects: values.effects
    readonly property var bar: values.bar
    readonly property var launcher: values.launcher
    readonly property var calendar: values.calendar
    readonly property var lock: values.lock
    readonly property var server: values.server
    readonly property var controlCenter: values.controlCenter
    readonly property var capture: values.capture
    readonly property var clipboard: values.clipboard
    readonly property var notifications: values.notifications

    // The setting at a dotted path, e.g. get("effects.glow").
    function get(path: string): var {
        return path.split(".").reduce((o, k) => o?.[k], values);
    }

    // Change a setting; applied now, written to config.json shortly after.
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
        path: Quickshell.shellPath("config.json.bak")
        blockLoading: true
        printErrors: false
    }

    // Recursively overlay `over` onto `base`; keys unknown to base are ignored.
    function merge(base: var, over: var): var {
        const out = {};
        for (const key in base) {
            const b = base[key], o = over?.[key];
            if (o === undefined)
                out[key] = b;
            else if (Array.isArray(b))
                out[key] = Array.isArray(o) ? o : b;
            else if (b !== null && typeof b === "object")
                out[key] = merge(b, o);
            else
                out[key] = o;
        }
        return out;
    }

    // qs ipc call config <get PATH|set PATH JSON|add PATH ITEM|remove PATH ITEM>
    //   config set effects.glow 0.8      config set colors.accent '"#cba6f7"'
    //   config add notifications.mutedApps steam
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

        path: Quickshell.shellPath("config.json")
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
                root.values = root.merge(root.defaults, JSON.parse(content));
                Health.resolve("config");
            } catch (e) {
                Health.report("config", `config.json is invalid, keeping previous values: ${e.message}`);
            }
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                root.values = root.defaults;
            else
                Health.report("config", `cannot read config.json: ${FileViewError.toString(error)}`);
        }
    }
}
