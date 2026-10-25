import QtQuick
import Quickshell
import qs.components
import qs.core
import qs.services

// Settings: the few things changed now and then (Config; applied live, saved
// to settings.json shortly after). How the machine is set up isn't here:
// that's Setup, in the project (`editSetup` opens it). The skin
// (SettingsMenu) lays out `items`.
//
// Item types: choice (options), screen, text, color (palette: "dark" for
// background tones), int (min, max, suffix), action (run(); no path).
// `when: () => bool` shows an item only while it applies.
Skinned {
    id: root

    property bool open: false
    property real maxHeight: 900

    readonly property var items: [
        { label: "Theme", path: "theme", type: "choice", hint: "how the shell looks",
          options: Theme.names.map(n => ({ label: Theme.specs[n]?.label ?? n, value: n })) },
        { label: "Screen", path: "screen", type: "screen", hint: "where the shell lives" },
        { label: "Wallpaper", path: "wallpaper.path", type: "text", hint: "image file; empty = plain" },
        { label: "Fit", path: "wallpaper.fit", type: "choice",
          options: [{ label: "fill", value: "fill" }, { label: "fit", value: "fit" },
                    { label: "center", value: "center" }, { label: "tile", value: "tile" }],
          when: () => !!Config.wallpaper.path },
        { label: "Plain color", path: "wallpaper.color", type: "color", palette: "dark",
          hint: "the background without a wallpaper", when: () => !Config.wallpaper.path },
        { label: "Lock after", path: "idle.lock", type: "int", min: 0, max: 120, suffix: "min",
          hint: "idle time before locking; 0 = never" },
        { label: "Screen off", path: "idle.screenOff", type: "int", min: 0, max: 120, suffix: "min",
          hint: "idle time before the display sleeps; 0 = never" },
        { label: "Passcode", path: "passcode", type: "int", min: 0, max: 12, suffix: "ch",
          hint: "the lock checks by itself after this many characters (your password's length); 0 = press Enter" },
        { label: "Restart", type: "action", button: "restart", hint: "start Quickshell over",
          run: () => Session.restartShell() }
    ]
    // The screens there are to put the shell on.
    readonly property var screens: Quickshell.screens.map(s => s.name)

    skin: "SettingsMenu"
    focus: open

    function value(path: string): var {
        return Config.get(path);
    }
    function defaultOf(path: string): var {
        return path.split(".").reduce((o, k) => o?.[k], Config.defaults);
    }
    function changed(path: string): bool {
        return JSON.stringify(value(path)) !== JSON.stringify(defaultOf(path));
    }
    function set(path: string, v: var): void {
        Config.set(path, v);
    }
    function reset(path: string): void {
        Config.set(path, defaultOf(path));
    }
    // Open the setup (core/Setup.qml) in the editor.
    function editSetup(): void {
        Launcher.runInTerminal(`nvim '${Quickshell.shellPath("core/Setup.qml")}'`);
        Panels.close();
    }

    Keys.onEscapePressed: Panels.close()
}
