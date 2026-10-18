import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core

// Edits a list of colors (e.g. one per calendar): click a chip to select it,
// then pick its color from the palette below; × removes, + adds.
ColumnLayout {
    id: root

    property var items: []
    property int selected: 0

    signal changed(var items)

    spacing: 8

    Flow {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: root.items

            Swatch {
                required property string modelData
                required property int index

                width: 46
                height: 24
                color: modelData
                text: String(index + 1).padStart(2, "0")
                selected: root.selected === index
                onClicked: root.selected = index
            }
        }
        IconButton {
            size: 24
            icon: "\u{F0415}"
            onClicked: {
                const index = root.items.length;
                root.changed([...root.items, Theme.palette.accent]);
                root.selected = index;
            }
        }
        IconButton {
            size: 24
            icon: "\u{F0156}"
            iconColor: Theme.palette.muted
            visible: root.items.length > 1
            onClicked: {
                root.changed(root.items.filter((_, i) => i !== root.selected));
                root.selected = Math.max(0, root.selected - 1);
            }
        }
    }
    Swatches {
        Layout.fillWidth: true
        current: root.items[root.selected] ?? ""
        onPicked: color => root.changed(root.items.map((c, i) => i === root.selected ? color : c))
    }
}
