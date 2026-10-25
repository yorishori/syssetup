import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components as C
import qs.core
import qs.modules.tray as M

// The tray app's name, a BACK row inside submenus, then its entries: a lamp
// for checkboxes (square) and radio buttons (diamond), the entry's icon, its
// label, › for a submenu.
Item {
    id: root

    required property M.TrayPanel control

    implicitWidth: 260
    implicitHeight: column.implicitHeight

    // One menu line: [lamp] [icon] label  [›]
    component MenuRow: C.ListRow {
        id: row

        property string label
        property string icon: ""
        property string glyph: ""
        property int buttonType: QsMenuButtonType.None
        property bool checked: false
        property bool submenu: false
        property bool stencil: false

        implicitHeight: 26
        leftPadding: 8
        rightPadding: 8
        spacing: 8
        marker: false

        // Checkbox: square lamp. Radio: small diamond lamp.
        C.Lamp {
            on: row.checked
            rotation: row.buttonType === QsMenuButtonType.RadioButton ? 45 : 0
            visible: row.buttonType !== QsMenuButtonType.None
        }
        IconImage {
            implicitSize: 14
            source: Icons.url(row.icon)
            visible: row.icon !== ""
        }
        C.StyledText {
            text: row.glyph
            color: Theme.palette.dim
            visible: row.glyph !== ""
        }
        C.StyledText {
            Layout.fillWidth: true
            text: row.label
            elide: Text.ElideRight
            color: !row.enabled ? Theme.palette.muted
                : row.checked ? Theme.palette.accent
                : row.current || row.hovered ? Theme.palette.fg
                : Theme.palette.dim
            glow: row.checked && row.enabled
            font.pixelSize: row.stencil ? Theme.font.size - 2 : Theme.font.size
            font.bold: row.stencil
            caps: row.stencil
            tracking: row.stencil ? 1.5 : 0
        }
        C.StyledText {
            text: "\u{F0142}"
            color: Theme.palette.muted
            visible: row.submenu
        }
    }

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 4

        C.SectionTitle {
            text: root.control.title
            code: "tray"
        }

        // Back row inside submenus
        MenuRow {
            visible: root.control.stack.length > 0
            label: "back"
            glyph: "\u{F0141}"
            stencil: true
            onClicked: root.control.back()
        }

        C.Placeholder {
            text: "-- loading --"
            visible: root.control.entries.length === 0
        }

        Repeater {
            model: root.control.entryModel

            Item {
                id: entryItem

                required property QsMenuEntry modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: modelData.isSeparator ? 9 : 26

                C.Divider {
                    anchors.centerIn: parent
                    width: parent.width - 12
                    visible: entryItem.modelData.isSeparator
                }

                MenuRow {
                    anchors.fill: parent
                    visible: !entryItem.modelData.isSeparator
                    label: root.control.label(entryItem.modelData)
                    icon: entryItem.modelData.icon
                    buttonType: entryItem.modelData.buttonType
                    checked: entryItem.modelData.checkState === Qt.Checked
                    submenu: entryItem.modelData.hasChildren
                    enabled: entryItem.modelData.enabled
                    current: root.control.highlighted === entryItem.index
                    onEntered: root.control.highlighted = entryItem.index
                    onClicked: root.control.activate(entryItem.modelData)
                }
            }
        }
    }
}
