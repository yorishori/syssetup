import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.modules.keys as M

// Sway's binds by section, in three columns: the key combos (modifiers dim,
// the key lit) and what they do.
Item {
    id: root

    required property M.KeysPanel control

    readonly property int columnCount: 3
    readonly property int rowHeight: 22
    readonly property int titleHeight: 30
    readonly property var columns: control.split(columnCount, g => titleHeight + g.binds.length * rowHeight)

    implicitWidth: 1020
    implicitHeight: body.implicitHeight

    Connections {
        target: root.control

        function onOpenChanged(): void {
            if (root.control.open)
                flick.contentY = 0;
        }
        function onNudged(velocity: real): void {
            flick.flick(0, velocity);
        }
    }

    FontMetrics {
        id: metrics

        font.family: Theme.font.family
        font.pixelSize: Theme.font.size - 1
        font.bold: true
    }

    ColumnLayout {
        id: body

        width: parent.width
        spacing: 10

        SectionTitle {
            text: "Keys"
            code: root.control.error ? "" : `${root.control.count} binds · sway config`
        }

        Placeholder {
            text: `-- ${root.control.error} --`
            visible: root.control.error !== ""
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(columnsRow.implicitHeight, root.control.maxHeight - 80)
            visible: root.control.error === ""

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
                                        text: group.modelData.title
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
                                                    return `<font color="${Theme.palette.muted}">${mods}</font>${esc(modelData.key)}`;
                                                }
                                                color: Theme.palette.accent
                                                font.pixelSize: Theme.font.size - 1
                                                font.bold: true
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: modelData.action
                                                color: Theme.palette.fg
                                                font.pixelSize: Theme.font.size - 1
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
