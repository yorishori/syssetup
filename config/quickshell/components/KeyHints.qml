import QtQuick
import QtQuick.Layouts
import qs.core

// Footer of key hints: "↵ RUN  ⇧↵ NEW  esc CLOSE".
// hints: [["↵", "run"], ["esc", "close"]]
RowLayout {
    property var hints: []

    spacing: 14

    Repeater {
        model: parent.hints

        RowLayout {
            required property var modelData

            spacing: 4

            StyledText {
                text: modelData[0]
                color: Config.colors.dim
                font.pixelSize: Config.font.size - 3
                font.bold: true
            }
            StyledText {
                text: modelData[1].toUpperCase()
                color: Config.colors.muted
                font.pixelSize: Config.font.size - 3
                font.letterSpacing: 1.5
            }
        }
    }
}
