import QtQuick
import qs.components
import qs.services

// The launcher: "go somewhere or run something". The skin (LauncherMenu)
// lays it out: the modes and quick-action keys, the prompt, the results.
//
//   SEARCH   apps, open windows, your entries (Setup → launcher.entries),
//            math, web
//   WINDOWS  every open window; Enter focuses it
//   APPS     every app in a scrollable list
//
// Enter runs the selection (focuses an app that's already open), Shift+Enter
// opens a new instance. Arrows move, Tab switches modes, Escape goes back to
// search, then closes. (Symbols and emoji live in the clipboard panel, SUPER+V.)
//
// The skin's prompt calls setQuery as it's typed, follows `query` when it's
// set from outside (IPC), and takes the keyboard on focusRequested.
Skinned {
    id: root

    property bool open: false

    signal done
    signal focusRequested
    // A result was run, just before the launcher closes.
    signal ran(int modifiers)

    property int selected: 0
    readonly property var results: Launcher.results
    readonly property string query: Launcher.query
    readonly property string mode: Launcher.mode
    readonly property var modes: ["search", "windows", "apps"]
    readonly property bool listed: mode !== "search"  // a scrollable list of everything
    readonly property int windowCount: Wm.windows.length
    readonly property string prompt: mode === "search" ? ">" : `${mode}>`
    readonly property string placeholder: ({ search: "apps · windows · 2+2 · web", windows: "filter windows", apps: "filter apps" })[mode]
    // What Enter does to a result, by its kind.
    readonly property var verbs: ({ calc: "copy", window: "focus", app: "run", custom: "cmd", web: "web" })
    readonly property var hints: [
        ["↵", mode === "windows" ? "focus" : "run"],
        ...(mode === "windows" ? [] : [["⇧↵", "new"]]),
        ["↑↓", "move"], ["⇥", "tab"],
        ["esc", mode === "search" ? "close" : "back"]
    ]
    // Quick actions; `busy` ones wait while a capture is running.
    readonly property bool capturing: Capture.busy
    readonly property var actions: [
        { name: "screenshot", icon: "\u{F0E51}", run: () => Capture.screenshot() },
        { name: "record", icon: "\u{F044A}", busy: true, run: () => Capture.recordScreen() },
        { name: "voice", icon: "\u{F036C}", busy: true, run: () => { Panels.close(); Capture.recordVoice(); } },
        { name: "clipboard", icon: "\u{F0147}", run: () => Panels.open("clipboard") },
        { name: "settings", icon: "\u{F0493}", run: () => Panels.open("settings") }
    ]

    skin: "LauncherMenu"

    function setMode(m: string): void {
        if (Launcher.mode === m)
            return;
        Launcher.mode = m;
        Launcher.query = "";
        selected = 0;
        focusRequested();
    }

    function switchTab(step: int): void {
        setMode(modes[(modes.indexOf(mode) + step + modes.length) % modes.length]);
    }

    function setQuery(text: string): void {
        if (Launcher.query !== text)
            Launcher.query = text;
        selected = 0;
    }

    function run(index: int, modifiers: int): void {
        const result = results[index];
        if (!result)
            return;
        ran(modifiers);
        result.run((modifiers & Qt.ShiftModifier) !== 0);
        done();
    }

    function move(step: int): void {
        if (results.length > 0)
            selected = Math.max(0, Math.min(results.length - 1, selected + step));
    }

    function back(): void {
        if (mode !== "search")
            setMode("search");
        else
            done();
    }

    // Opens empty (IPC `launcher search` sets its query right after opening).
    onOpenChanged: {
        selected = 0;
        if (open) {
            focusRequested();
        } else {
            Launcher.query = "";
            Launcher.mode = "search";
        }
    }
    onResultsChanged: selected = Math.min(selected, Math.max(0, results.length - 1))

    Keys.onUpPressed: move(-1)
    Keys.onDownPressed: move(1)
    Keys.onTabPressed: switchTab(1)
    Keys.onBacktabPressed: switchTab(-1)
    Keys.onEscapePressed: back()
}
