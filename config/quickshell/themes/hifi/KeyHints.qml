import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core

// Little keycaps with what they do silk-screened beside them:
// [↵] run  [esc] close
RowLayout {
    id: root

    required property C.KeyHints control

    spacing: 12

    Repeater {
        model: root.control.hints

        RowLayout {
            required property var modelData

            spacing: 6

            Item {
                implicitWidth: Math.max(implicitHeight, key.implicitWidth + 12)
                implicitHeight: key.implicitHeight + 6

                Key {
                    id: cap

                    anchors.fill: parent
                    roundness: 3
                }
                Engraved {
                    id: key

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -cap.travel / 2
                    text: modelData[0]
                    color: Theme.palette.fg
                    font.pixelSize: Theme.font.size - 3
                    font.bold: true
                }
            }
            Engraved {
                text: modelData[1]
                caps: true
                tracking: 1
                color: Theme.palette.muted
                font.pixelSize: Theme.font.size - 3
            }
        }
    }
}
