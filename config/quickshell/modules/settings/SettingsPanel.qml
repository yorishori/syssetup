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
// Items are Config.schema's (see core/settings.js), with choice options as
// { label, value }, plus actions (type "action", run(); no path).
// `palette: "dark"` offers background tones for a color; `when: () => bool`
// shows an item only while it applies.
Skinned {
    id: root

    property bool open: false
    property real maxHeight: 900

    // Config's settings that have a label, then the panel's own actions.
    readonly property var items: [
        ...Config.schema.filter(s => s.label).map(s => Object.assign({}, s, {
            options: s.path === "theme"
                ? Theme.names.map(n => ({ label: Theme.specs[n]?.label ?? n, value: n }))
                : s.options?.map(o => ({ label: o, value: o }))
        })),
        { label: "Restart", type: "action", button: "restart", hint: "start Quickshell over",
          run: () => root.restart() }
    ]
    // The screens there are to put the shell on.
    readonly property var screens: Quickshell.screens.map(s => s.name)

    skin: "SettingsMenu"
    focus: open

    function value(path: string): var {
        return Config.get(path);
    }
    function defaultOf(path: string): var {
        return Config.defaultOf(path);
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
    function restart(): void {
        Session.restartShell();
    }
    // Open the setup (core/Setup.qml) in the editor.
    function editSetup(): void {
        Launcher.execInTerminal(["nvim", Quickshell.shellPath("core/Setup.qml")]);
        Panels.close();
    }

    Keys.onEscapePressed: Panels.close()
}
