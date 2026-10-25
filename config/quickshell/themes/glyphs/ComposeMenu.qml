import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.modules.compose as M

// A drawer from the bottom edge: what the sequence can become, as tiles
// with their keys (the part typed dimmed), the selected one's name, the
// prompt.
Item {
    id: root

    required property M.ComposePad control

    readonly property int columns: 8
    readonly property Item inputArea: drawer
    readonly property bool showing: drawer.height > 0

    Connections {
        target: root.control

        function onCleared(): void {
            field.text = "";
            if (root.control.open)
                field.focusInput();
        }
        function onSelectedChanged(): void {
            grid.positionViewAtIndex(root.control.selected, GridView.Contain);
        }
    }

    MouseArea {
        anchors.fill: drawer
    }

    BottomDrawer {
        id: drawer

        anchors {
            bottom: parent.bottom
            bottomMargin: drawer.lift
            horizontalCenter: parent.horizontalCenter
        }
        width: 680
        open: root.control.open

        ColumnLayout {
            width: parent.width
            spacing: 10

            SectionTitle {
                text: "Compose"
                code: !root.control.loaded ? "loading" : root.control.typed === "" ? `${root.control.sequences} sequences`
                    : root.control.byName ? `${root.control.results.length} by name` : `${root.control.results.length} matches`
            }

            Placeholder {
                text: root.control.typed === "" ? "-- start a sequence: ' e → é, o c → ©, - > → → --" : "-- no sequence or name matches --"
                visible: root.control.results.length === 0
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: grid.height
                visible: root.control.results.length > 0

                GridView {
                    id: grid

                    width: parent.width
                    height: Math.min(Math.ceil(count / root.columns), 3) * cellHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    cellWidth: Math.floor(width / root.columns)
                    cellHeight: 70
                    model: root.control.results

                    delegate: Tile {
                        id: tile

                        required property var modelData
                        required property int index

                        width: grid.cellWidth
                        height: grid.cellHeight
                        current: root.control.selected === index
                        onEntered: root.control.selected = tile.index
                        onClicked: root.control.insert(tile.modelData.result)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.modelData.result
                                color: tile.current ? Theme.palette.accent : Theme.palette.fg
                                glow: tile.current
                                font.pixelSize: 24
                            }
                            // The keys, with the part already typed dimmed.
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                textFormat: Text.StyledText
                                text: {
                                    const seq = tile.modelData.seq;
                                    const done = root.control.byName ? 0 : root.control.typed.length;
                                    const esc = s => [...s].map(c => ({ "<": "&lt;", ">": "&gt;", "&": "&amp;" })[c] ?? c).join(" ");
                                    const typedPart = esc(seq.slice(0, done));
                                    const rest = esc(seq.slice(done));
                                    return `<font color="${Theme.palette.muted}">${typedPart}</font>${typedPart && rest ? " " : ""}${rest}`;
                                }
                                color: Theme.palette.dim
                                font.pixelSize: Theme.font.size - 2
                                font.bold: true
                            }
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
                text: root.control.results[root.control.selected]?.name ?? ""
                caps: true
                color: Theme.palette.muted
                font.pixelSize: Theme.font.size - 2
                font.bold: true
                tracking: 1.5
                elide: Text.ElideRight
                visible: text !== ""
            }

            TextField {
                id: field

                Layout.fillWidth: true
                prompt: "compose>"
                placeholder: "type a sequence, or a name"
                captureHorizontal: true
                onTextChanged: root.control.typed = text
                onAccepted: root.control.insertSelected()
                onHorizontal: step => root.control.move(step)
            }

            KeyHints {
                Layout.alignment: Qt.AlignHCenter
                hints: [["↵", "insert"], ["←↑↓→", "move"], ["esc", "close"]]
            }
        }
    }
}
