import QtQuick
import qs.components as C
import qs.core

// What the keys do, each punched on its own label: [ESC CLOSE] [↵ RUN].
Row {
    id: root

    required property C.KeyHints control

    spacing: 8

    Repeater {
        model: root.control.hints

        Legend {
            required property var modelData

            anchors.verticalCenter: parent.verticalCenter
            text: `${modelData[0]} ${modelData[1]}`
            size: 9
        }
    }
}
