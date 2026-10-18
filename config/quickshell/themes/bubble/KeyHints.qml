import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core

// Little keycaps with what they do: [↵] run  [esc] close
RowLayout {
    id: root

    required property C.KeyHints control

    spacing: 12

    Repeater {
        model: root.control.hints

        RowLayout {
            required property var modelData

            spacing: 5

            Rectangle {
                implicitWidth: Math.max(implicitHeight, key.implicitWidth + 10)
                implicitHeight: key.implicitHeight + 2
                radius: 6
                color: Theme.palette.surface

                C.StyledText {
                    id: key

                    anchors.centerIn: parent
                    text: modelData[0]
                    color: Theme.palette.fg
                    font.pixelSize: Theme.font.size - 3
                    font.bold: true
                }
            }
            C.StyledText {
                text: modelData[1]
                caps: true
                color: Theme.palette.muted
                font.pixelSize: Theme.font.size - 3
            }
        }
    }
}
