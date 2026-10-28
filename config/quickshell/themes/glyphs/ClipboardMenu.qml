import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.modules.clipboard as M

// A drawer rising from the bottom edge of the screen: tabs on top, the
// history list or the symbol grid, the prompt at the bottom.
Item {
    id: root

    required property M.ClipboardPicker control
    readonly property bool showing: drawer.height > 0

    Connections {
        target: root.control

        function onCleared(): void {
            field.text = "";
        }
        function onFocusRequested(): void {
            field.focusInput();
        }
        function onCurrentChanged(): void {
            tabBar.current = root.control.current;
        }
        function onSelectedChanged(): void {
            if (root.control.onHistory)
                list.positionViewAtIndex(root.control.selected, ListView.Contain);
            else
                grid.positionViewAtIndex(root.control.selected, GridView.Contain);
        }
    }

    // Swallow clicks on the drawer so they don't reach the backdrop.
    MouseArea {
        anchors.fill: drawer
    }

    BottomDrawer {
        id: drawer

        name: "clipboard"

        anchors {
            bottom: parent.bottom
            bottomMargin: drawer.lift
            horizontalCenter: parent.horizontalCenter
        }
        width: 680
        open: root.control.open

        ColumnLayout {
            id: content

            width: parent.width
            spacing: 10

            // Tabs, and the clear-history key
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Tabs {
                    id: tabBar

                    tabs: root.control.tabs.map(t => t.label)
                    onCurrentChanged: {
                        root.control.current = current;
                        field.focusInput();
                    }
                }
                TextButton {
                    text: "\u{F0A7A}  clear"
                    visible: root.control.onHistory && root.control.allHistory.length > 0
                    onClicked: root.control.wipe()
                }
            }

            Placeholder {
                text: root.control.onHistory
                    ? (root.control.allHistory.length === 0 ? "-- history is empty --" : "-- no matches --")
                    : (root.control.symbolsLoaded ? "-- no matches --" : "-- loading --")
                visible: root.control.entries.length === 0
            }

            // ── History: newest at the bottom, next to the prompt ────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: list.height
                visible: root.control.onHistory && root.control.entries.length > 0

                ListView {
                    id: list

                    width: parent.width
                    height: Math.min(contentHeight, 420)
                    verticalLayoutDirection: ListView.BottomToTop
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.control.onHistory ? root.control.clips : []

                    delegate: ListRow {
                        id: row

                        required property var modelData
                        required property int index
                        readonly property string thumb: root.control.thumbs[modelData.id] ?? ""

                        width: ListView.view.width
                        implicitHeight: modelData.image ? 64 : 32
                        spacing: 12
                        current: root.control.selected === index
                        onEntered: root.control.selected = index
                        onClicked: mouse => root.control.pick(index, mouse.modifiers)

                        StyledText {
                            Layout.preferredWidth: 22
                            text: String(row.index + 1).padStart(2, "0")
                            color: row.current ? Theme.palette.accent : Theme.palette.muted
                            font.pixelSize: Theme.font.size - 3
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
                            color: row.current ? Theme.palette.fg : Theme.palette.dim
                            elide: Text.ElideRight
                        }
                        StyledText {
                            text: row.modelData.image ? row.modelData.meta : "txt"
                            caps: true
                            color: Theme.palette.muted
                            font.pixelSize: Theme.font.size - 3
                            font.bold: true
                            tracking: 1.5
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
                visible: !root.control.onHistory && root.control.entries.length > 0

                GridView {
                    id: grid

                    width: parent.width
                    height: Math.min(Math.ceil(count / root.control.columns), 6) * cellHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    cellWidth: Math.floor(width / root.control.columns)
                    cellHeight: 44
                    model: root.control.symbols

                    delegate: Tile {
                        id: tile

                        required property var modelData
                        required property int index

                        width: grid.cellWidth
                        height: grid.cellHeight
                        current: root.control.selected === index
                        onEntered: root.control.selected = tile.index
                        onClicked: mouse => root.control.pick(tile.index, mouse.modifiers)

                        StyledText {
                            anchors.centerIn: parent
                            width: parent.width - 8
                            horizontalAlignment: Text.AlignHCenter
                            text: tile.modelData.ch
                            color: tile.current ? Theme.palette.accent : Theme.palette.fg
                            font.pixelSize: root.control.tab === "kaomoji" ? Theme.font.size : 20
                            elide: Text.ElideRight
                        }
                    }
                }
                ScrollLamp {
                    view: grid
                }
            }

            RowLayout {
                id: detail

                readonly property var current: root.control.symbols[root.control.selected] ?? null

                Layout.fillWidth: true
                spacing: 12
                visible: current !== null

                StyledText {
                    Layout.maximumWidth: 220
                    text: detail.current?.ch ?? ""
                    color: Theme.palette.accent
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
                    color: Theme.palette.muted
                    font.pixelSize: Theme.font.size - 2
                }
            }

            // ── Prompt and keys ──────────────────────────────────────────
            TextField {
                id: field

                Layout.fillWidth: true
                prompt: root.control.onHistory ? "clip>" : "sym>"
                placeholder: root.control.onHistory ? "filter history" : "arrow, smile, cod-git, table flip…"
                keyFilter: root.control.fieldKey
                onTextChanged: root.control.setQuery(text)
            }

            KeyHints {
                Layout.alignment: Qt.AlignHCenter
                hints: root.control.onHistory
                    ? [["↵", "paste"], ["⇧↵", "copy"], ["↑↓", "move"], ["tab", "switch"], ["⇧del", "remove"], ["esc", "close"]]
                    : [["↵", "paste"], ["⇧↵", "copy"], ["←↑↓→", "move"], ["tab", "switch"], ["esc", "close"]]
            }
        }
    }
}
