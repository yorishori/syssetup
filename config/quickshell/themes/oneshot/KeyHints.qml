import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core

// Square keycaps and what they do, in small capitals: [↵] RUN  [ESC] CLOSE
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
                implicitHeight: key.implicitHeight + 4
                color: Theme.palette.surface

                C.StyledText {
                    id: key

                    anchors.centerIn: parent
                    text: modelData[0]
                    color: Theme.palette.fg
                    font.pixelSize: Theme.font.size - 3
                }
            }
            C.StyledText {
                text: modelData[1]
                caps: true
                color: Theme.palette.dim
                font.family: Theme.get("font.labels") ?? Theme.font.family
                font.pixelSize: Theme.font.size - 4
            }
        }
    }
}
