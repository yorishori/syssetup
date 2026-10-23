import QtQuick
import qs.components as C
import qs.core

// Four rising LED bars, lit up to the strength; unlit ones show faintly
// behind the glass.
Row {
    id: root

    required property C.SignalBars control

    spacing: 2

    Repeater {
        model: 4

        Rectangle {
            id: bar

            required property int index
            readonly property bool lit: root.control.strength > index * 25

            anchors.bottom: parent.bottom
            width: 3
            height: 4 + index * 3
            radius: 0.5
            gradient: Gradient {
                GradientStop { position: 0; color: bar.lit ? Qt.lighter(root.control.color, 1.2) : Qt.alpha(root.control.color, 0.16) }
                GradientStop { position: 1; color: bar.lit ? root.control.color : Qt.alpha(root.control.color, 0.1) }
            }
        }
    }
}
