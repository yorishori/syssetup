import QtQuick
import QtQuick.Layouts

// Pick one of a few options, as keys; the current one is lit.
// options: [{ label: "MON", value: 1 }, …]. Emits picked(value).
RowLayout {
    id: root

    property var options: []
    property var current

    signal picked(var value)

    spacing: 6

    Repeater {
        model: root.options

        TextButton {
            required property var modelData

            text: modelData.label
            lit: modelData.value === root.current
            onClicked: root.picked(modelData.value)
        }
    }
}
