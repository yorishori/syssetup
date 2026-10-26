import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components as C
import qs.core
import qs.modules.launcher as M

// An RPG menu: the mode as the window's title in lantern amber, the modes
// beside it as small capitals you can click, the quick-action keys, then
// the prompt, the results (the bobbing cursor marks the selection; what
// Enter does is tagged on the right), and the key hints.
Item {
    id: root

    required property M.LauncherPanel control

    implicitWidth: 560
    implicitHeight: column.implicitHeight

    Connections {
        target: root.control

        function onFocusRequested(): void {
            field.focusInput();
        }
        // The query and mode can also be set from outside (IPC); keep the
        // field and tabs in sync.
        function onQueryChanged(): void {
            if (field.text !== root.control.query)
                field.text = root.control.query;
        }
        function onSelectedChanged(): void {
            if (root.control.listed)
                list.positionViewAtIndex(root.control.selected, ListView.Contain);
        }
    }

    // One result: [icon] name  detail  TAG
    component ResultRow: C.ListRow {
        id: row

        required property var modelData
        required property int index
        readonly property bool lit: modelData.kind === "calc" || modelData.kind === "window"

        width: ListView.view ? ListView.view.width : implicitWidth
        implicitHeight: 33
        leftPadding: 18
        current: root.control.selected === index
        onEntered: root.control.selected = index
        onClicked: mouse => root.control.run(index, mouse.modifiers)

        Item {
            implicitWidth: 20
            implicitHeight: 20

            IconImage {
                anchors.fill: parent
                source: row.modelData.icon
                visible: row.modelData.icon !== ""
            }
            C.StyledText {
                anchors.centerIn: parent
                text: row.modelData.glyph
                color: row.lit ? Theme.palette.accent : Theme.palette.dim
                font.bold: true
                font.pixelSize: Theme.font.size + 2
                visible: row.modelData.icon === ""
            }
        }
        C.StyledText {
            Layout.maximumWidth: 260
            text: row.modelData.kind === "web" ? `"${row.modelData.name}"` : row.modelData.name
            color: row.modelData.kind === "calc" || row.current ? Theme.palette.accent : Theme.palette.fg
            font.pixelSize: Theme.font.size + 1
            elide: Text.ElideRight
        }
        C.StyledText {
            Layout.fillWidth: true
            text: row.modelData.detail
            color: Theme.palette.muted
            font.pixelSize: Theme.font.size - 1
            elide: Text.ElideRight
        }
        C.StyledText {
            text: root.control.verbs[row.modelData.kind] ?? ""
            caps: true
            color: row.lit || row.current ? Theme.palette.accent : Theme.palette.muted
            font.family: Theme.get("font.labels") ?? Theme.font.family
            font.pixelSize: Theme.font.size - 4
        }
    }

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 10

        // ── Tabs, then the quick-action keys ─────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            C.StyledText {
                text: ({ search: "Search", windows: "Windows", apps: "Apps" })[root.control.mode] ?? ""
                color: Theme.palette.accent
                font.pixelSize: Theme.font.size + 6
                font.weight: Font.DemiBold
            }

            Repeater {
                model: root.control.modes

                C.StyledText {
                    id: tab

                    required property string modelData
                    required property int index
                    readonly property bool current: root.control.mode === modelData

                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 3
                    text: modelData === "windows" ? `windows ${root.control.windowCount}` : modelData
                    caps: true
                    color: current ? Theme.palette.fg : tabArea.containsMouse ? Theme.palette.dim : Theme.palette.muted
                    font.family: Theme.get("font.labels") ?? Theme.font.family
                    font.pixelSize: Theme.font.size - 3

                    MouseArea {
                        id: tabArea

                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.control.setMode(tab.modelData)
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Quick actions as bare glyph keys, to keep the top row to one line.
            Repeater {
                model: root.control.actions

                C.IconButton {
                    required property var modelData

                    size: 26
                    icon: modelData.icon
                    iconColor: Theme.palette.dim
                    enabled: !(modelData.busy && root.control.capturing)
                    opacity: enabled ? 1 : 0.4
                    onClicked: modelData.run()
                }
            }
        }

        // ── Prompt ───────────────────────────────────────────────────────────
        C.TextField {
            id: field

            Layout.fillWidth: true
            prompt: root.control.prompt
            placeholder: root.control.placeholder
            onTextChanged: root.control.setQuery(text)
            onAccepted: modifiers => root.control.run(root.control.selected, modifiers)
        }

        // ── Search ───────────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            visible: root.control.mode === "search"

            C.Placeholder {
                text: "-- no matches --"
                visible: root.control.results.length === 0 && root.control.query.trim() !== ""
            }
            Repeater {
                model: root.control.mode === "search" ? root.control.results : []
                ResultRow {}
            }
        }

        // ── Windows / apps: everything, scrollable ───────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: list.height
            visible: root.control.listed

            ListView {
                id: list

                width: parent.width
                height: Math.min(count, 10) * 33
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.control.listed ? root.control.results : []
                delegate: ResultRow {}
            }
            C.ScrollLamp {
                view: list
            }
        }
        C.Placeholder {
            text: root.control.query.trim() !== "" ? "-- no matches --" : `-- no ${root.control.mode} --`
            visible: root.control.listed && root.control.results.length === 0
        }

        // ── Key hints ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 14

            C.Divider {
                Layout.fillWidth: true
            }
            C.KeyHints {
                hints: root.control.hints
            }
        }
    }
}
