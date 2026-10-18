import QtQuick
import qs.core

// Color picker limited to the theme's palette (its accents by default, or
// `dark` for backgrounds), so nothing off-theme can be picked. Emits
// picked(color).
Flow {
    id: root

    property string current: ""
    readonly property var accents: Theme.swatches.accents
    readonly property var dark: Theme.swatches.dark
    property var palette: accents

    signal picked(string color)

    spacing: 4

    Repeater {
        model: root.palette

        Swatch {
            required property string modelData

            color: modelData
            selected: root.current.toLowerCase() === modelData.toLowerCase()
            onClicked: root.picked(modelData)
        }
    }
}
