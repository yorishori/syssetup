import QtQuick
import qs.core

// Four rising bars for signal strength (0-100).
Row {
    id: root

    property int strength: 0
    property color color: Config.colors.fg

    spacing: 2

    Repeater {
        model: 4

        Rectangle {
            required property int index

            anchors.bottom: parent.bottom
            width: 3
            height: 4 + index * 3
            color: root.strength > index * 25 ? root.color : Config.colors.surface
        }
    }
}
