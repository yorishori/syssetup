import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.core
import qs.services

// "Insert something" (SUPER+V): clipboard history, emoji, Nerd Font glyphs,
// symbols and kaomoji, rising from the bottom edge of the screen. A drawer
// like the bar's, upside down: it grows out of the bottom edge with angled
// shoulders and the same hairline. Tabs on top, prompt at the bottom.
//
// Whatever you pick is pasted into the window you were in (Enter), or only
// copied (Shift+Enter). Tab / Shift+Tab switch tabs, arrows move, Shift+Delete
// removes a history entry, Escape closes.
PanelWindow {
    id: win

    readonly property var tabs: [
        { key: "history", label: "HISTORY" },
        { key: "emoji", label: "EMOJI" },
        { key: "nerd", label: "NERD" },
        { key: "symbol", label: "SYMBOLS" },
        { key: "kaomoji", label: "KAOMOJI" }
    ]
    readonly property string tab: tabs[tabBar.current].key
    readonly property bool onHistory: tab === "history"

    property string query: ""
    property int selected: 0

    // Symbol results for the current tab. The list and grid read their own
    // source, never `entries`: on a tab switch they could otherwise catch it
    // before it updates and get the other kind of entry for a moment.
    readonly property var symbols: onHistory ? [] : Symbols.search(query, tab)
    // History entries, or symbol results for the current tab.
    readonly property var entries: onHistory ? Clipboard.filtered : symbols
    readonly property int columns: tab === "kaomoji" ? 3 : 12

    function move(step: int): void {
        if (entries.length > 0)
            selected = Math.max(0, Math.min(entries.length - 1, selected + step));
    }

    function switchTab(step: int): void {
        tabBar.current = (tabBar.current + step + tabs.length) % tabs.length;
    }

    function pick(index: int, modifiers: int): void {
        const entry = entries[index];
        if (!entry)
            return;
        const paste = !(modifiers & Qt.ShiftModifier);
        if (onHistory)
            Clipboard.pick(entry, paste);
        else
            Clipboard.insert(entry.ch, paste);
    }

    screen: Display.primary
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: Clipboard.open || backdrop.opacity > 0 || drawer.height > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-clipboard"
    WlrLayershell.keyboardFocus: Clipboard.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Connections {
        target: Clipboard

        function onOpenChanged(): void {
            win.selected = 0;
            field.text = "";
            if (!Clipboard.open)
                return;
            const start = win.tabs.findIndex(t => t.key === Clipboard.startTab);
            tabBar.current = start >= 0 ? start : 0;
            Clipboard.startTab = "";
            field.focusInput();
        }
    }
    onTabChanged: {
        selected = 0;
        field.text = "";
        if (!onHistory)
            Symbols.load();
        field.focusInput();
    }
    onEntriesChanged: selected = Math.min(selected, Math.max(0, entries.length - 1))
    onSelectedChanged: {
        if (onHistory)
            list.positionViewAtIndex(selected, ListView.Contain);
        else
            grid.positionViewAtIndex(selected, GridView.Contain);
    }

    // Shift+Delete removes the selected history entry (plain Delete edits the filter).
    Shortcut {
        sequence: "Shift+Delete"
        enabled: Clipboard.open && win.onHistory
        onActivated: {
            const entry = win.entries[win.selected];
            if (entry)
                Clipboard.remove(entry);
        }
    }

    // Darkened, blurred backdrop; click to close.
    Rectangle {
        id: backdrop

        anchors.fill: parent
        color: Config.colors.bg
        opacity: Clipboard.open ? Config.effects.backdrop : 0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Clipboard.hide()
        }
    }

    // ── Drawer ───────────────────────────────────────────────────────────────
    // Swallow clicks on the drawer so they don't reach the backdrop.
    MouseArea {
        anchors.fill: drawer
    }

    BottomDrawer {
        id: drawer

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: 680
        open: Clipboard.open

        ColumnLayout {
            id: content

            width: parent.width
            spacing: 10

            Keys.onUpPressed: win.move(win.onHistory ? 1 : -win.columns)
            Keys.onDownPressed: win.move(win.onHistory ? -1 : win.columns)
            Keys.onTabPressed: win.switchTab(1)
            Keys.onBacktabPressed: win.switchTab(-1)
            Keys.onEscapePressed: Clipboard.hide()

            // Tabs, and the clear-history key
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Tabs {
                    id: tabBar

                    tabs: win.tabs.map(t => t.label)
                    onCurrentChanged: field.focusInput()
                }
                TextButton {
                    text: "\u{F0A7A}  clear"
                    visible: win.onHistory && Clipboard.entries.length > 0
                    onClicked: Clipboard.wipe()
                }
            }

            Placeholder {
                text: win.onHistory
                    ? (Clipboard.entries.length === 0 ? "-- history is empty --" : "-- no matches --")
                    : (Symbols.loaded ? "-- no matches --" : "-- loading --")
                visible: win.entries.length === 0
            }

            // ── History: newest at the bottom, next to the prompt ────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: list.height
                visible: win.onHistory && win.entries.length > 0

                ListView {
                    id: list

                    width: parent.width
                    height: Math.min(contentHeight, 420)
                    verticalLayoutDirection: ListView.BottomToTop
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: win.onHistory ? Clipboard.filtered : []

                    delegate: ListRow {
                        id: row

                        required property var modelData
                        required property int index
                        readonly property string thumb: Clipboard.thumbs[modelData.id] ?? ""

                        width: ListView.view.width
                        implicitHeight: modelData.image ? 64 : 32
                        spacing: 12
                        current: win.selected === index
                        onEntered: win.selected = index
                        onClicked: mouse => win.pick(index, mouse.modifiers)

                        StyledText {
                            Layout.preferredWidth: 22
                            text: String(row.index + 1).padStart(2, "0")
                            color: row.current ? Config.colors.accent : Config.colors.muted
                            font.pixelSize: Config.font.size - 3
                            font.bold: true
                        }
                        Image {
                            Layout.preferredWidth: 96
                            Layout.preferredHeight: 54
                            source: row.thumb
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: 192
                            sourceSize.height: 108
                            asynchronous: true
                            visible: row.modelData.image
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: row.modelData.image ? "" : row.modelData.text
                            color: row.current ? Config.colors.fg : Config.colors.dim
                            elide: Text.ElideRight
                        }
                        StyledText {
                            text: row.modelData.image ? row.modelData.meta : "TXT"
                            color: Config.colors.muted
                            font.pixelSize: Config.font.size - 3
                            font.bold: true
                            font.letterSpacing: 1.5
                        }
                    }
                }
                ScrollLamp {
                    view: list
                    inverted: true
                }
            }

            // ── Symbols: glyph grid and the selected one's details ───────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: grid.height
                visible: !win.onHistory && win.entries.length > 0

                GridView {
                    id: grid

                    width: parent.width
                    height: Math.min(Math.ceil(count / win.columns), 6) * cellHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    cellWidth: Math.floor(width / win.columns)
                    cellHeight: 44
                    model: win.symbols

                    delegate: Item {
                        id: tile

                        required property var modelData
                        required property int index
                        readonly property bool current: win.selected === index

                        width: grid.cellWidth
                        height: grid.cellHeight

                        Chamfer {
                            anchors {
                                fill: parent
                                margins: 2
                            }
                            cut: 5
                            fill: tile.current ? Config.colors.surface : tileArea.containsMouse ? Config.colors.bgAlt : "transparent"
                            stroke: tile.current ? Config.colors.accent : "transparent"
                        }
                        StyledText {
                            anchors.centerIn: parent
                            width: parent.width - 8
                            horizontalAlignment: Text.AlignHCenter
                            text: tile.modelData.ch
                            color: tile.current ? Config.colors.accent : Config.colors.fg
                            font.pixelSize: win.tab === "kaomoji" ? Config.font.size : 20
                            elide: Text.ElideRight
                        }
                        MouseArea {
                            id: tileArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.selected = tile.index
                            onClicked: mouse => win.pick(tile.index, mouse.modifiers)
                        }
                    }
                }
                ScrollLamp {
                    view: grid
                }
            }

            RowLayout {
                id: detail

                readonly property var current: win.symbols[win.selected] ?? null

                Layout.fillWidth: true
                spacing: 12
                visible: current !== null

                StyledText {
                    Layout.maximumWidth: 220
                    text: detail.current?.ch ?? ""
                    color: Config.colors.accent
                    glow: true
                    font.pixelSize: 26
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    text: detail.current?.name ?? ""
                    font.bold: true
                    elide: Text.ElideRight
                }
                StyledText {
                    text: detail.current?.detail ?? ""
                    color: Config.colors.muted
                    font.pixelSize: Config.font.size - 2
                }
            }

            // ── Prompt and keys ──────────────────────────────────────────
            TextField {
                id: field

                Layout.fillWidth: true
                prompt: win.onHistory ? "clip>" : "sym>"
                placeholder: win.onHistory ? "filter history" : "arrow, smile, cod-git, table flip…"
                captureHorizontal: !win.onHistory
                onTextChanged: {
                    win.query = text;
                    Clipboard.query = win.onHistory ? text : "";
                    win.selected = 0;
                }
                onAccepted: modifiers => win.pick(win.selected, modifiers)
                onHorizontal: step => win.move(step)
            }

            KeyHints {
                Layout.alignment: Qt.AlignHCenter
                hints: win.onHistory
                    ? [["↵", "paste"], ["⇧↵", "copy"], ["↑↓", "move"], ["tab", "switch"], ["⇧del", "remove"], ["esc", "close"]]
                    : [["↵", "paste"], ["⇧↵", "copy"], ["←↑↓→", "move"], ["tab", "switch"], ["esc", "close"]]
            }
        }
    }
}
