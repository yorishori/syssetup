pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "objects.js" as Objects
import "settings.js" as Settings

// Settings: what's changed now and then from the Settings panel, and what the
// shell remembers on its own. Kept out of the project, in
// $XDG_STATE_HOME/quickshell/settings.json (~/.local/state/…), merged over the
// defaults in the schema below. How the machine is set up (terminal, launcher entries,
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

    // Every setting: its path, type and default, and for the Settings panel
    // a label (none: not shown there), hint and limits. See settings.js for
    // the types. A value of the wrong kind (in settings.json or from IPC)
    // isn't taken: the default stays and Health is told.
    readonly property var schema: [
        // Which theme (themes/<name>); the options are Theme.names.
        { path: "theme", type: "choice", default: "cyber", label: "Theme", hint: "how the shell looks" },
        // Output name; empty or missing = the first screen.
        { path: "screen", type: "screen", default: "DP-3", label: "Screen", hint: "where the shell lives" },
        // Image file ("~/…" ok); empty = plain color.
        { path: "wallpaper.path", type: "text", default: "", label: "Wallpaper", hint: "image file; empty = plain" },
        // fill (crop), fit, center, tile.
        { path: "wallpaper.fit", type: "choice", default: "fill", options: ["fill", "fit", "center", "tile"],
          label: "Fit", when: () => !!root.wallpaper.path },
        // The plain color; empty = the theme's background.
        { path: "wallpaper.color", type: "color", default: "#2c2633", palette: "dark",
          label: "Plain color", hint: "the background without a wallpaper", when: () => !root.wallpaper.path },
        // Minutes without input before each; 0 = never. Apps that inhibit
        // idle (fullscreen, games) and playing media hold both off.
        { path: "idle.lock", type: "int", default: 25, min: 0, max: 120, suffix: "min",
          label: "Lock after", hint: "idle time before locking; 0 = never" },
        { path: "idle.screenOff", type: "int", default: 30, min: 0, max: 120, suffix: "min",
          label: "Screen off", hint: "idle time before the display sleeps; 0 = never" },
        // The lock screen checks by itself once this many characters are
        // typed (your password's length); 0 = press Enter.
        { path: "passcode", type: "int", default: 4, min: 0, max: 12, suffix: "ch",
          label: "Passcode", hint: "the lock checks by itself after this many characters (your password's length); 0 = press Enter" },

        // Remembered by the shell.
        // Apps whose popups are silenced (lowercase names).
        { path: "mutedApps", type: "list", default: [] },
        // The last folder each kind of capture was saved to; empty = Setup's.
        { path: "folders.screenshots", type: "text", default: "" },
        { path: "folders.recordings", type: "text", default: "" },
        { path: "folders.voice", type: "text", default: "" }
    ]

    readonly property var defaults: Settings.defaults(schema)

    readonly property string dir: `${Paths.stateHome}/quickshell`

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
        return Objects.getPath(values, path);
    }

    // Its default.
    function defaultOf(path: string): var {
        return Objects.getPath(defaults, path);
    }

    // Why `value` won't do for the setting at `path`, or "" if it will.
    function problem(path: string, value: var): string {
        const setting = Settings.find(schema, path);
        if (!setting)
            return `unknown setting: ${path}; settings: ${schema.map(s => s.path).join(", ")}`;
        const why = Settings.problem(setting, value);
        return why ? `${path} ${why}` : "";
    }

    // Change a setting; applied now, written to settings.json shortly after.
    // A value that won't do is refused (with a warning).
    function set(path: string, value: var): void {
        const why = problem(path, value);
        if (why) {
            console.warn(`config: ${why}`);
            return;
        }
        values = Objects.setPath(values, path, value);
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
        // What's written is valid, whatever the file held before.
        Health.resolve("config");
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
            const why = root.problem(path, value);
            if (why)
                return why;
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
                const rejected = [];
                const merged = Objects.merge(root.defaults, JSON.parse(content), rejected);
                root.values = Settings.validate(root.schema, merged, rejected);
                if (rejected.length)
                    Health.report("config", `settings.json: ${rejected.join(", ")} won't do, using the defaults`);
                else
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
