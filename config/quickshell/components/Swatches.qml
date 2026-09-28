import QtQuick
import qs.core

// Color picker limited to a palette (Catppuccin Mocha accents by default, or
// `dark`), so nothing off-theme can be picked. The current color is outlined.
// Emits picked(color).
Flow {
    id: root

    property string current: ""
    readonly property var accents: [
        "#f5e0dc", "#f2cdcd", "#f5c2e7", "#cba6f7", "#f38ba8", "#eba0ac", "#fab387",
        "#f9e2af", "#a6e3a1", "#94e2d5", "#89dceb", "#74c7ec", "#89b4fa", "#b4befe"
    ]
    // Backgrounds: Mocha's crust, mantle and base, then the accents at 12%
    // over crust (mauve, red, peach, yellow, green, teal, blue, pink).
    readonly property var dark: [
        "#11111b", "#181825", "#1e1e2e",
        "#272335", "#2c202c", "#2d2428", "#2d2a2d", "#232a2b", "#212a31", "#1f2536", "#2c2633"
    ]
    property var palette: accents

    signal picked(string color)

    spacing: 4

    Repeater {
        model: root.palette

        Item {
            id: swatch

            required property string modelData
            readonly property bool selected: root.current.toLowerCase() === modelData.toLowerCase()

            width: 20
            height: 20

            Chamfer {
                anchors.fill: parent
                cut: 4
                fill: swatch.modelData
                stroke: swatch.selected ? Config.colors.fg : "transparent"
                strokeWidth: 2
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(swatch.modelData)
            }
        }
    }
}
