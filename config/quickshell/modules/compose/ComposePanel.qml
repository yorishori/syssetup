import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.core
import qs.services

// Compose overlay (bind it to the compose key): a drawer from the bottom edge.
// Type a sequence (' then e) and every character it can still become is
// shown with its keys; a complete, unambiguous sequence inserts right away.
// Typing something that starts no sequence searches by name ("euro").
// Enter inserts the selected one, arrows move, Escape closes.
PanelWindow {
    id: win

    property string typed: ""
    property int selected: 0
    readonly property var results: Compose.search(typed)
    readonly property bool byName: typed !== "" && results.length > 0 && !results[0].seq.startsWith(typed)
    readonly property int columns: 8

    function move(step: int): void {
        if (results.length > 0)
            selected = Math.max(0, Math.min(results.length - 1, selected + step));
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
    visible: Compose.open || drawer.height > 0
    mask: Region {
        item: Compose.open ? fullArea : drawer
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-compose"
    WlrLayershell.keyboardFocus: Compose.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Connections {
        target: Compose

        function onOpenChanged(): void {
            win.typed = "";
            field.text = "";
            if (Compose.open)
                field.focusInput();
        }
    }
    onTypedChanged: {
        selected = 0;
        const done = Compose.complete(typed);
        if (done)
            Compose.insert(done.result);
    }
    onSelectedChanged: grid.positionViewAtIndex(selected, GridView.Contain)

    // Click outside the drawer closes.
    Item {
        id: fullArea

        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: Panels.close()
        }
    }

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
        open: Compose.open

        ColumnLayout {
            width: parent.width
            spacing: 10

            Keys.onUpPressed: win.move(-win.columns)
            Keys.onDownPressed: win.move(win.columns)
            Keys.onEscapePressed: Panels.close()

            SectionTitle {
                text: "COMPOSE"
                code: !Compose.loaded ? "LOADING" : win.typed === "" ? `${Compose.entries.length} SEQUENCES`
                    : win.byName ? `${win.results.length} BY NAME` : `${win.results.length} MATCHES`
            }

            Placeholder {
                text: win.typed === "" ? "-- start a sequence: ' e → é, o c → ©, - > → → --" : "-- no sequence or name matches --"
                visible: win.results.length === 0
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: grid.height
                visible: win.results.length > 0

                GridView {
                    id: grid

                    width: parent.width
                    height: Math.min(Math.ceil(count / win.columns), 3) * cellHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    cellWidth: Math.floor(width / win.columns)
                    cellHeight: 70
                    model: win.results

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
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.modelData.result
                                color: tile.current ? Config.colors.accent : Config.colors.fg
                                glow: tile.current
                                font.pixelSize: 24
                            }
                            // The keys, with the part already typed dimmed.
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                textFormat: Text.StyledText
                                text: {
                                    const seq = tile.modelData.seq;
                                    const done = win.byName ? 0 : win.typed.length;
                                    const esc = s => [...s].map(c => ({ "<": "&lt;", ">": "&gt;", "&": "&amp;" })[c] ?? c).join(" ");
                                    const typedPart = esc(seq.slice(0, done));
                                    const rest = esc(seq.slice(done));
                                    return `<font color="${Config.colors.muted}">${typedPart}</font>${typedPart && rest ? " " : ""}${rest}`;
                                }
                                color: Config.colors.dim
                                font.pixelSize: Config.font.size - 2
                                font.bold: true
                            }
                        }
                        MouseArea {
                            id: tileArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.selected = tile.index
                            onClicked: Compose.insert(tile.modelData.result)
                        }
                    }
                }
                ScrollLamp {
                    view: grid
                }
            }

            // Selected: name
            StyledText {
                Layout.fillWidth: true
                text: win.results[win.selected]?.name.toUpperCase() ?? ""
                color: Config.colors.muted
                font.pixelSize: Config.font.size - 2
                font.bold: true
                font.letterSpacing: 1.5
                elide: Text.ElideRight
                visible: text !== ""
            }

            TextField {
                id: field

                Layout.fillWidth: true
                prompt: "compose>"
                placeholder: "type a sequence, or a name"
                captureHorizontal: true
                onTextChanged: win.typed = text
                onAccepted: {
                    const r = win.results[win.selected];
                    if (r)
                        Compose.insert(r.result);
                }
                onHorizontal: step => win.move(step)
            }

            KeyHints {
                Layout.alignment: Qt.AlignHCenter
                hints: [["↵", "insert"], ["←↑↓→", "move"], ["esc", "close"]]
            }
        }
    }
}
