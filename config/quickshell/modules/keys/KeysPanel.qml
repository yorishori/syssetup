import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services

// Keyboard shortcuts cheat sheet (SUPER+F1): Sway's binds by section, in
// three columns. Read from the loaded config every time it opens (see
// Keybinds). Escape closes.
Item {
    id: root

    property bool open: false
    property real maxHeight: 900

    readonly property int columnCount: 3
    readonly property int rowHeight: 22
    readonly property int titleHeight: 30

    // Sections split into contiguous columns of about equal height.
    readonly property var columns: {
        const groups = Keybinds.groups;
        const size = g => titleHeight + g.binds.length * rowHeight;
        const target = groups.reduce((n, g) => n + size(g), 0) / columnCount;
        const out = [[]];
        let height = 0;
        for (const g of groups) {
            if (height > 0 && height + size(g) / 2 > target && out.length < columnCount) {
                out.push([]);
                height = 0;
            }
            out[out.length - 1].push(g);
            height += size(g);
        }
        return out;
    }

    width: 1020
    implicitHeight: body.implicitHeight
    height: implicitHeight
    focus: open

    onOpenChanged: {
        if (open) {
            flick.contentY = 0;
            forceActiveFocus();
        }
    }

    Keys.onEscapePressed: Panels.close()
    Keys.onUpPressed: flick.flick(0, 800)
    Keys.onDownPressed: flick.flick(0, -800)

    FontMetrics {
        id: metrics

        font.family: Config.font.family
        font.pixelSize: Config.font.size - 1
        font.bold: true
    }

    ColumnLayout {
        id: body

        width: parent.width
        spacing: 10

        SectionTitle {
            text: "KEYS"
            code: Keybinds.error ? "" : `${Keybinds.count} BINDS · SWAY CONFIG`
        }

        Placeholder {
            text: `-- ${Keybinds.error} --`
            visible: Keybinds.error !== ""
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(columnsRow.implicitHeight, root.maxHeight - 80)
            visible: Keybinds.error === ""

            Flickable {
                id: flick

                anchors.fill: parent
                contentHeight: columnsRow.implicitHeight
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                RowLayout {
                    id: columnsRow

                    width: flick.width
                    spacing: 24

                    Repeater {
                        model: root.columns

                        ColumnLayout {
                            id: column

                            required property var modelData
                            // Widest key combo in the column, so actions line up.
                            readonly property real keyWidth: {
                                let widest = 0;
                                for (const g of modelData)
                                    for (const b of g.binds)
                                        widest = Math.max(widest, metrics.advanceWidth(b.mods.concat(b.key).join("+")));
                                return widest + 12;
                            }

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.alignment: Qt.AlignTop
                            spacing: 0

                            Repeater {
                                model: column.modelData

                                ColumnLayout {
                                    id: group

                                    required property var modelData
                                    required property int index

                                    Layout.fillWidth: true
                                    Layout.topMargin: index > 0 ? 8 : 0
                                    spacing: 0

                                    SectionTitle {
                                        Layout.preferredHeight: root.titleHeight - 8
                                        text: group.modelData.title.toUpperCase()
                                    }

                                    Repeater {
                                        model: group.modelData.binds

                                        RowLayout {
                                            required property var modelData

                                            Layout.fillWidth: true
                                            Layout.preferredHeight: root.rowHeight
                                            spacing: 0

                                            // Modifiers dim, the key itself lit.
                                            StyledText {
                                                Layout.preferredWidth: column.keyWidth
                                                textFormat: Text.StyledText
                                                text: {
                                                    const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
                                                    const mods = modelData.mods.map(m => `${esc(m)}+`).join("");
                                                    return `<font color="${Config.colors.muted}">${mods}</font>${esc(modelData.key)}`;
                                                }
                                                color: Config.colors.accent
                                                font.pixelSize: Config.font.size - 1
                                                font.bold: true
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: modelData.action
                                                color: Config.colors.fg
                                                font.pixelSize: Config.font.size - 1
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            ScrollLamp {
                view: flick
            }
        }

        KeyHints {
            Layout.alignment: Qt.AlignHCenter
            hints: [["super+F1", "toggle"], ["esc", "close"]]
        }
    }
}
