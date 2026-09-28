import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core

// Edits a list of strings: reorder (up/down), remove (×), add at the bottom.
// Emits changed(items) with the whole new list.
ColumnLayout {
    id: root

    property var items: []
    property string placeholder: "add…"

    signal changed(var items)

    function moved(from: int, to: int): var {
        const next = items.slice();
        next.splice(to, 0, next.splice(from, 1)[0]);
        return next;
    }

    spacing: 2

    Placeholder {
        text: "-- empty --"
        visible: root.items.length === 0
    }

    Repeater {
        model: root.items

        ListRow {
            id: row

            required property string modelData
            required property int index

            implicitHeight: 26
            leftPadding: 8
            rightPadding: 2
            spacing: 2
            marker: false

            StyledText {
                Layout.fillWidth: true
                text: row.modelData
                color: Config.colors.dim
                elide: Text.ElideRight
            }
            IconButton {
                size: 20
                icon: "\u{F0143}"
                iconColor: Config.colors.muted
                visible: row.index > 0
                onClicked: root.changed(root.moved(row.index, row.index - 1))
            }
            IconButton {
                size: 20
                icon: "\u{F0140}"
                iconColor: Config.colors.muted
                visible: row.index < root.items.length - 1
                onClicked: root.changed(root.moved(row.index, row.index + 1))
            }
            IconButton {
                size: 20
                icon: "\u{F0156}"
                iconColor: Config.colors.muted
                onClicked: root.changed(root.items.filter((_, i) => i !== row.index))
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 6

        TextField {
            id: adder

            Layout.fillWidth: true
            prompt: "+"
            placeholder: root.placeholder
            onAccepted: addButton.clicked()
        }
        TextButton {
            id: addButton

            text: "add"
            enabled: adder.text.trim() !== ""
            onClicked: {
                root.changed([...root.items, adder.text.trim()]);
                adder.text = "";
            }
        }
    }
}
