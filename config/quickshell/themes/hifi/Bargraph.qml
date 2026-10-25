import QtQuick
import QtQuick.Effects
import qs.core

// How full a disk is: a row of LEDs, green, then amber, then red.
Row {
    id: graph

    property real value: 0
    readonly property int count: 12

    spacing: 2

    Repeater {
        model: graph.count

        Rectangle {
            required property int index
            readonly property bool on: graph.value * graph.count > index + 0.25
            readonly property color tone: index >= 10 ? Theme.palette.error : index >= 8 ? Theme.palette.warn : Theme.palette.ok

            width: 5
            height: 10
            radius: 1
            color: on ? tone : Qt.alpha(tone, 0.12)
            border.width: 1
            border.color: Qt.alpha("black", 0.6)

            RectangularShadow {
                anchors.fill: parent
                radius: 1
                blur: 6
                color: Qt.alpha(parent.tone, 0.6)
                visible: parent.on
                z: -1
            }
        }
    }
}
