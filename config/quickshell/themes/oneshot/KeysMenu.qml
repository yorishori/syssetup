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
    readonly property int rowHeight: 28
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
                                        widest = Math.max(widest, metrics.advanceWidth(b.mods.concat(b.key).join("")) * 0.85 + (b.mods.length + 1) * 14);
                                return widest + 14;
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

                                            // Keycaps, like a game's controls screen: the
                                            // modifiers plain, the key itself amber.
                                            Row {
                                                Layout.preferredWidth: column.keyWidth
                                                spacing: 3

                                                Repeater {
                                                    model: [...parent.parent.modelData.mods, parent.parent.modelData.key]

                                                    Item {
                                                        required property string modelData
                                                        required property int index
                                                        readonly property bool last: index === parent.parent.modelData.mods.length
                                                        readonly property string label: modelData.replace(/^XF86Audio/, "").replace(/^XF86/, "")
                                                            .replace("RaiseVolume", "vol+").replace("LowerVolume", "vol-").replace("Return", "enter")

                                                        implicitWidth: Math.max(22, cap.implicitWidth + 10)
                                                        implicitHeight: 22

                                                        Rectangle {
                                                            anchors.fill: parent
                                                            color: Theme.palette.shadow
                                                        }
                                                        Rectangle {
                                                            width: parent.width
                                                            height: parent.height - 3
                                                            color: parent.last ? Theme.palette.accent : Theme.palette.surface
                                                        }
                                                        StyledText {
                                                            id: cap

                                                            anchors.centerIn: parent
                                                            anchors.verticalCenterOffset: -1
                                                            text: parent.label
                                                            caps: true
                                                            color: parent.last ? Theme.palette.shadow : Theme.palette.fg
                                                            font.family: Theme.get("font.labels") ?? Theme.font.family
                                                            font.pixelSize: Theme.font.size - 5
                                                        }
                                                    }
                                                }
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
