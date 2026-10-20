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
        // The look: which theme (themes/<name>), and your tweaks to each one's
        // tokens, e.g. cyber: { palette: { accent: "#89b4fa" } }. See core/Theme.qml.
        theme: {
            name: "cyber",
            cyber: {},
            bubble: {},
            hifi: {}
        },
        wallpaper: {
            path: "",            // image file ("~/…" ok); empty = plain color
            fit: "fill",         // fill (crop), fit, center, tile
            color: ""            // the plain color; empty = the theme's background
        },
        bar: {
            height: 32,
            padding: 18,
            spacing: 16
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
        // idle (fullscreen, games) and playing media hold both off.
        idle: {
            lock: 10,
            screenOff: 15,
            indicator: 10   // seconds before the bar's sleep glyph shows; 0 = never
        },
        lock: {
            // Passcode mode: check automatically once this many characters are
            // typed (must equal your password's length). 0 = off, press Enter.
            passcode: 0
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
    readonly property var theme: values.theme
    readonly property var wallpaper: values.wallpaper
    readonly property var idle: values.idle
    readonly property var bar: values.bar
    readonly property var launcher: values.launcher
    readonly property var calendar: values.calendar
    readonly property var lock: values.lock
    readonly property var controlCenter: values.controlCenter
    readonly property var capture: values.capture
    readonly property var clipboard: values.clipboard
    readonly property var notifications: values.notifications

    // The setting at a dotted path, e.g. get("bar.height").
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

    // Recursively overlay `over` onto `base`; keys unknown to base are ignored,
    // except under an empty object, which takes whatever is there (the
    // per-theme tweaks: their keys are the theme's business).
    function merge(base: var, over: var): var {
        const out = {};
        for (const key in base) {
            const b = base[key], o = over?.[key];
            const isObject = v => v !== null && typeof v === "object" && !Array.isArray(v);
            if (o === undefined)
                out[key] = b;
            else if (Array.isArray(b))
                out[key] = Array.isArray(o) ? o : b;
            else if (isObject(b))
                out[key] = !isObject(o) ? b : Object.keys(b).length === 0 ? o : merge(b, o);
            else
                out[key] = o;
        }
        return out;
    }

    // Older configs kept the look at the top level (colors, font, shape,
    // effects): move it into the cyber theme's tweaks. True if anything moved.
    function migrate(json: var): bool {
        const old = ["colors", "font", "shape", "effects"].filter(k => k in json);
        if (old.length === 0)
            return false;
        const cyber = {};
        if (json.colors)
            cyber.palette = json.colors;
        if (json.font)
            cyber.font = json.font;
        if (json.shape)
            cyber.shape = json.shape;
        if (json.effects) {
            const effects = Object.assign({}, json.effects);
            if (effects.glow !== undefined)
                cyber.glow = { opacity: effects.glow };
            delete effects.glow;
            cyber.effects = effects;
        }
        json.theme = json.theme ?? {};
        json.theme.cyber = Object.assign(cyber, json.theme.cyber ?? {});
        for (const k of old)
            delete json[k];
        return true;
    }

    // qs ipc call config <get PATH|set PATH JSON|add PATH ITEM|remove PATH ITEM>
    //   config set theme.name '"bubble"'      config set theme.cyber.palette.accent '"#cba6f7"'
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
            // Theme tweaks are free-form (the theme decides what they mean).
            if (root.get(path) === undefined && !path.startsWith("theme."))
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
                const json = JSON.parse(content);
                const migrated = root.migrate(json);
                root.values = root.merge(root.defaults, json);
                Health.resolve("config");
                if (migrated)
                    writeDelay.restart();
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
