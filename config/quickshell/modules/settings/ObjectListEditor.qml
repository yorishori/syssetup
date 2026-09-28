import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core

// Edits a list of objects (launcher entries, tools): one row each with a title
// and subtitle; click a row to edit its fields. Fields save when you leave
// them (or press Enter). Reorder, remove, add.
//
// fields: [{ key, label, type: "text" | "words" | "bool", hint? }]
// title / subtitle: functions item => string. Emits changed(items).
ColumnLayout {
    id: root

    property var items: []
    property var fields: []
    property var title: item => ""
    property var subtitle: item => ""

    property int expanded: -1
    // "index:key" of the field that just saved: a save rebuilds the entries, so
    // the new field flashes in its place.
    property string justSaved: ""

    signal changed(var items)

    function update(index: int, key: string, value: var): void {
        const next = items.map(i => Object.assign({}, i));
        if (value === "" || (Array.isArray(value) && value.length === 0) || value === false)
            delete next[index][key];
        else
            next[index][key] = value;
        changed(next);
    }

    function move(from: int, to: int): void {
        const next = items.slice();
        next.splice(to, 0, next.splice(from, 1)[0]);
        expanded = expanded === from ? to : expanded;
        changed(next);
    }

    spacing: 2

    Placeholder {
        text: "-- empty --"
        visible: root.items.length === 0
    }

    Repeater {
        model: root.items

        ColumnLayout {
            id: entry

            required property var modelData
            required property int index
            readonly property bool open: root.expanded === index

            Layout.fillWidth: true
            spacing: 4

            ListRow {
                implicitHeight: 28
                leftPadding: 8
                rightPadding: 2
                spacing: 8
                marker: false
                highlighted: entry.open
                onClicked: root.expanded = entry.open ? -1 : entry.index

                StyledText {
                    text: root.title(entry.modelData) || "(unnamed)"
                    color: entry.open ? Config.colors.accent : Config.colors.fg
                    font.bold: true
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.subtitle(entry.modelData)
                    color: Config.colors.muted
                    font.pixelSize: Config.font.size - 2
                    elide: Text.ElideRight
                }
                IconButton {
                    size: 20
                    icon: "\u{F0143}"
                    iconColor: Config.colors.muted
                    visible: entry.index > 0
                    onClicked: root.move(entry.index, entry.index - 1)
                }
                IconButton {
                    size: 20
                    icon: "\u{F0140}"
                    iconColor: Config.colors.muted
                    visible: entry.index < root.items.length - 1
                    onClicked: root.move(entry.index, entry.index + 1)
                }
                IconButton {
                    size: 20
                    icon: "\u{F0156}"
                    iconColor: Config.colors.muted
                    onClicked: {
                        root.expanded = -1;
                        root.changed(root.items.filter((_, i) => i !== entry.index));
                    }
                }
            }

            // Field editor
            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 4
                Layout.bottomMargin: 6
                columns: 2
                columnSpacing: 10
                rowSpacing: 4
                visible: entry.open

                Repeater {
                    model: entry.open ? root.fields : []

                    StyledText {
                        required property var modelData
                        required property int index

                        Layout.row: index
                        Layout.column: 0
                        Layout.preferredWidth: 90
                        text: modelData.label.toUpperCase()
                        color: Config.colors.muted
                        font.pixelSize: Config.font.size - 3
                        font.bold: true
                        font.letterSpacing: 1.5
                    }
                }
                Repeater {
                    model: entry.open ? root.fields : []

                    Loader {
                        id: fieldLoader

                        required property var modelData
                        required property int index
                        readonly property var value: entry.modelData[modelData.key]

                        Layout.row: index
                        Layout.column: 1
                        Layout.fillWidth: true
                        sourceComponent: modelData.type === "bool" ? boolField : textField

                        Component {
                            id: textField

                            TextField {
                                prompt: ">"
                                submitOnEnter: true
                                placeholder: fieldLoader.modelData.hint ?? ""
                                text: fieldLoader.modelData.type === "words"
                                    ? (fieldLoader.value ?? []).join(" ")
                                    : (fieldLoader.value ?? "")
                                onEditingFinished: {
                                    const v = fieldLoader.modelData.type === "words"
                                        ? text.split(/\s+/).filter(w => w)
                                        : text.trim();
                                    const old = fieldLoader.modelData.type === "words" ? (fieldLoader.value ?? []).join(" ") : (fieldLoader.value ?? "");
                                    const now = fieldLoader.modelData.type === "words" ? v.join(" ") : v;
                                    if (now !== old) {
                                        root.justSaved = `${entry.index}:${fieldLoader.modelData.key}`;
                                        root.update(entry.index, fieldLoader.modelData.key, v);
                                    }
                                }
                                onAccepted: flash()
                                Component.onCompleted: {
                                    if (root.justSaved === `${entry.index}:${fieldLoader.modelData.key}`) {
                                        root.justSaved = "";
                                        flash();
                                    }
                                }
                            }
                        }
                        Component {
                            id: boolField

                            RowLayout {
                                TextButton {
                                    text: fieldLoader.value ? "on" : "off"
                                    lit: !!fieldLoader.value
                                    onClicked: root.update(entry.index, fieldLoader.modelData.key, !fieldLoader.value)
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    TextButton {
        Layout.topMargin: 4
        text: "\u{F0415}  add"
        onClicked: {
            const index = root.items.length;
            root.changed([...root.items, {}]);
            root.expanded = index;
        }
    }
}
