import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.core
import qs.services

// The launcher: "go somewhere or run something". Tabs and quick-action keys
// on top, then the prompt, then results.
//
//   SEARCH   apps, open windows, your entries (config.json → launcher.entries),
//            math, web
//   WINDOWS  every open window; Enter focuses it
//   APPS     every app in a scrollable list
//
// Enter runs the selection (focuses an app that's already open), Shift+Enter
// opens a new instance. Arrows move, Tab switches tabs, Escape goes back to
// search, then closes. (Symbols and emoji live in the clipboard panel, SUPER+V.)
ColumnLayout {
    id: root

    property bool open: false

    signal done

    property int selected: 0
    readonly property var results: Launcher.results
    readonly property string mode: Launcher.mode
    readonly property var modes: ["search", "windows", "apps"]
    readonly property bool listed: mode !== "search"  // a scrollable list of everything

    width: 560
    spacing: 10

    function setMode(m: string): void {
        if (Launcher.mode === m)
            return;
        Launcher.mode = m;
        field.text = "";
        selected = 0;
        field.focusInput();
    }

    function switchTab(step: int): void {
        setMode(modes[(modes.indexOf(mode) + step + modes.length) % modes.length]);
    }

    function run(index: int, modifiers: int): void {
        const result = results[index];
        if (!result)
            return;
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
            field.focusInput();
        } else {
            Launcher.query = "";
            Launcher.mode = "search";
            field.text = "";
        }
    }
    onResultsChanged: selected = Math.min(selected, Math.max(0, results.length - 1))
    onSelectedChanged: {
        if (listed)
            list.positionViewAtIndex(selected, ListView.Contain);
    }

    // The query and mode can also be set from outside (IPC); keep the field
    // and tabs in sync.
    Connections {
        target: Launcher

        function onQueryChanged(): void {
            if (field.text !== Launcher.query)
                field.text = Launcher.query;
        }
        function onModeChanged(): void {
            tabs.current = root.modes.indexOf(Launcher.mode);
        }
    }

    Keys.onUpPressed: move(-1)
    Keys.onDownPressed: move(1)
    Keys.onTabPressed: switchTab(1)
    Keys.onBacktabPressed: switchTab(-1)
    Keys.onEscapePressed: back()

    // ── Tabs, then the quick-action keys ─────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Tabs {
            id: tabs

            tabs: ["Search", `Windows ${Wm.windows.length}`, "Apps"]
            onCurrentChanged: root.setMode(root.modes[current])
        }

        // Quick actions as bare glyph keys, to keep the top row to one line.
        Repeater {
            model: [
                { icon: "\u{F0E51}", run: () => Capture.screenshot() },
                { icon: "\u{F044A}", busy: true, run: () => Capture.recordScreen() },
                { icon: "\u{F036C}", busy: true, run: () => { Panels.close(); Capture.recordVoice(); } },
                { icon: "\u{F0147}", run: () => Clipboard.show() },
                { icon: "\u{F0493}", run: () => Panels.open("settings") }
            ]

            IconButton {
                required property var modelData

                size: 26
                icon: modelData.icon
                iconColor: Theme.palette.dim
                // Screen and voice recording wait while a capture is running.
                enabled: !(modelData.busy && Capture.busy)
                opacity: enabled ? 1 : 0.4
                onClicked: modelData.run()
            }
        }
    }

    // ── Prompt ───────────────────────────────────────────────────────────────
    TextField {
        id: field

        Layout.fillWidth: true
        prompt: root.mode === "search" ? ">" : `${root.mode}>`
        placeholder: ({ search: "apps · windows · 2+2 · web", windows: "filter windows", apps: "filter apps" })[root.mode]

        onTextChanged: {
            if (Launcher.query !== text)
                Launcher.query = text;
            root.selected = 0;
        }
        onAccepted: modifiers => root.run(root.selected, modifiers)
    }

    // One result: [icon] name  detail  TAG
    component ResultRow: ListRow {
        id: row

        required property var modelData
        required property int index
        readonly property bool lit: modelData.kind === "calc" || modelData.kind === "window"

        width: ListView.view ? ListView.view.width : implicitWidth
        implicitHeight: 32
        current: root.selected === index
        onEntered: root.selected = index
        onClicked: mouse => root.run(index, mouse.modifiers)

        Item {
            implicitWidth: 20
            implicitHeight: 20

            IconImage {
                anchors.fill: parent
                source: row.modelData.icon
                visible: row.modelData.icon !== ""
            }
            StyledText {
                anchors.centerIn: parent
                text: row.modelData.glyph
                color: row.lit ? Theme.palette.accent : Theme.palette.dim
                font.bold: true
                font.pixelSize: Theme.font.size + 2
                visible: row.modelData.icon === ""
            }
        }
        StyledText {
            Layout.maximumWidth: 260
            text: row.modelData.kind === "web" ? `"${row.modelData.name}"` : row.modelData.name
            color: row.modelData.kind === "calc" ? Theme.palette.accent : row.current ? Theme.palette.fg : Theme.palette.dim
            glow: row.modelData.kind === "calc"
            font.bold: row.current || row.modelData.kind === "calc"
            elide: Text.ElideRight
        }
        StyledText {
            Layout.fillWidth: true
            text: row.modelData.detail
            color: Theme.palette.muted
            font.pixelSize: Theme.font.size - 1
            elide: Text.ElideRight
        }
        StyledText {
            text: ({ calc: "copy", window: "focus", app: "run", custom: "cmd", web: "web" })[row.modelData.kind] ?? ""
            caps: true
            color: row.lit ? Theme.palette.accent : Theme.palette.muted
            font.pixelSize: Theme.font.size - 3
            font.bold: true
            tracking: 1.5
        }
    }

    // ── Search ───────────────────────────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        visible: root.mode === "search"

        Placeholder {
            text: "-- no matches --"
            visible: root.results.length === 0 && Launcher.query.trim() !== ""
        }
        Repeater {
            model: root.mode === "search" ? root.results : []
            ResultRow {}
        }
    }

    // ── Windows / apps: everything, scrollable ───────────────────────────────
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: list.height
        visible: root.listed

        ListView {
            id: list

            width: parent.width
            height: Math.min(count, 10) * 32
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.listed ? root.results : []
            delegate: ResultRow {}
        }
        ScrollLamp {
            view: list
        }
    }
    Placeholder {
        text: Launcher.query.trim() !== "" ? "-- no matches --" : `-- no ${root.mode} --`
        visible: root.listed && root.results.length === 0
    }

    // ── Key hints ────────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2
        spacing: 14

        Divider {
            Layout.fillWidth: true
        }
        KeyHints {
            hints: [
                ["↵", root.mode === "windows" ? "focus" : "run"],
                ...(root.mode === "windows" ? [] : [["⇧↵", "new"]]),
                ["↑↓", "move"], ["⇥", "tab"],
                ["esc", root.mode === "search" ? "close" : "back"]
            ]
        }
    }
}
