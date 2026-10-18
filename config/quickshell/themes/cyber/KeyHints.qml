import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core

// "↵ RUN  ⇧↵ NEW  esc CLOSE"
RowLayout {
    id: root

    required property C.KeyHints control

    spacing: 14

    Repeater {
        model: root.control.hints

        RowLayout {
            required property var modelData

            spacing: 4

            C.StyledText {
                text: modelData[0]
                color: Theme.palette.dim
                font.pixelSize: Theme.font.size - 3
                font.bold: true
            }
            C.StyledText {
                text: modelData[1]
                caps: true
                color: Theme.palette.muted
                font.pixelSize: Theme.font.size - 3
                tracking: 1.5
            }
        }
    }
}
