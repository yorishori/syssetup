import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.core
import qs.services

// The launcher: "go somewhere or run something". Quick-action keys on top,
// then the prompt, then results.
//
//   search  apps, open windows, your entries (config.json → launcher.entries),
//           math, web
//   APPS    every app in a scrollable list
//
// Enter runs the selection (focuses an app that's already open), Shift+Enter
// opens a new instance. Arrows move, Escape goes back to search, then closes.
// (Symbols and emoji live in the clipboard panel, SUPER+V.)
ColumnLayout {
    id: root

    property bool open: false

    signal done

    property int selected: 0
    readonly property var results: Launcher.results
    readonly property string mode: Launcher.mode

    // At least 560, wider if the quick-action keys need it.
    width: Math.max(560, actions.implicitWidth)
    spacing: 10

    function setMode(m: string): void {
        Launcher.mode = Launcher.mode === m ? "search" : m;
        field.text = "";
        selected = 0;
        field.focusInput();
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
        if (mode === "apps")
            appList.positionViewAtIndex(selected, ListView.Contain);
    }

    // The query can also be set from outside (IPC); keep the field in sync.
    Connections {
        target: Launcher

        function onQueryChanged(): void {
            if (field.text !== Launcher.query)
                field.text = Launcher.query;
        }
    }

    Keys.onUpPressed: move(-1)
    Keys.onDownPressed: move(1)
    Keys.onTabPressed: move(1)
    Keys.onBacktabPressed: move(-1)
    Keys.onEscapePressed: back()

    // ── Quick actions ────────────────────────────────────────────────────────
    RowLayout {
        id: actions

        Layout.fillWidth: true
        spacing: 8

        TextButton {
            text: "\u{F003B}  apps"
            lit: root.mode === "apps"
            onClicked: root.setMode("apps")
        }
        TextButton {
            text: "\u{F0E51}  shot"
            onClicked: Capture.screenshot()
        }
        TextButton {
            text: "\u{F044A}  rec"
            enabled: !Capture.busy
            onClicked: Capture.recordScreen()
        }
        TextButton {
            text: "\u{F036C}  voice"
            enabled: !Capture.busy
            onClicked: {
                Panels.close();
                Capture.recordVoice();
            }
        }
        TextButton {
            text: "\u{F0147}  cliphist"
            onClicked: Clipboard.show()
        }
        TextButton {
            text: "\u{F0493}  settings"
            onClicked: Panels.open("settings")
        }
        Item {
            Layout.fillWidth: true
        }
    }

    // ── Prompt ───────────────────────────────────────────────────────────────
    TextField {
        id: field

        Layout.fillWidth: true
        prompt: root.mode === "apps" ? "apps>" : ">"
        placeholder: root.mode === "apps" ? "filter apps" : "apps · windows · 2+2 · web"

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
                color: row.lit ? Config.colors.accent : Config.colors.dim
                font.bold: true
                font.pixelSize: Config.font.size + 2
                visible: row.modelData.icon === ""
            }
        }
        StyledText {
            Layout.maximumWidth: 260
            text: row.modelData.kind === "web" ? `"${row.modelData.name}"` : row.modelData.name
            color: row.modelData.kind === "calc" ? Config.colors.accent : row.current ? Config.colors.fg : Config.colors.dim
            glow: row.modelData.kind === "calc"
            font.bold: row.current || row.modelData.kind === "calc"
            elide: Text.ElideRight
        }
        StyledText {
            Layout.fillWidth: true
            text: row.modelData.detail
            color: Config.colors.muted
            font.pixelSize: Config.font.size - 1
            elide: Text.ElideRight
        }
        StyledText {
            text: ({ calc: "COPY", window: "FOCUS", app: "RUN", custom: "CMD", web: "WEB" })[row.modelData.kind] ?? ""
            color: row.lit ? Config.colors.accent : Config.colors.muted
            font.pixelSize: Config.font.size - 3
            font.bold: true
            font.letterSpacing: 1.5
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

    // ── Apps: every app, scrollable ──────────────────────────────────────────
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: appList.height
        visible: root.mode === "apps"

        ListView {
            id: appList

            width: parent.width
            height: Math.min(count, 10) * 32
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.mode === "apps" ? root.results : []
            delegate: ResultRow {}
        }
        ScrollLamp {
            view: appList
        }
    }
    Placeholder {
        text: "-- no apps --"
        visible: root.mode === "apps" && root.results.length === 0
    }

    // ── Key hints ────────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2
        spacing: 14

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Config.colors.border
        }
        KeyHints {
            hints: [["↵", "run"], ["⇧↵", "new"], ["↑↓", "move"], ["esc", root.mode === "search" ? "close" : "back"]]
        }
    }
}
