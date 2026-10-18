import QtQuick
import QtQuick.Effects
import qs.components as C
import qs.core

// A free-standing plate screwed on at its corners, on a cast shadow. With a
// tone, a light pipe down its left edge glows in it and its bezel lights.
Item {
    id: root

    required property C.Card control
    readonly property bool toned: control.tone.a > 0

    Metal {
        id: plate

        anchors.fill: parent
        roundness: (Theme.values.shape?.radius ?? 0) + 2
        raised: true
        border.color: root.toned ? Qt.alpha(root.control.tone, 0.7) : Qt.darker(plate.tint, 2.2)

        Behavior on border.color {
            ColorAnimation { duration: 140 }
        }
    }

    // The light pipe.
    Item {
        x: 1
        y: plate.radius + 4
        width: 3
        height: root.height - 2 * y
        opacity: root.toned ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 140 }
        }

        RectangularShadow {
            anchors.fill: parent
            radius: 1.5
            blur: 8
            color: Qt.alpha(root.control.tone, 0.8 * (Theme.glow.opacity ?? 0))
        }
        Rectangle {
            anchors.fill: parent
            radius: 1.5
            color: root.control.tone
        }
    }

    Repeater {
        model: [[0, 0, 40], [1, 0, -25], [0, 1, 75], [1, 1, 5]]

        Screw {
            required property var modelData

            size: 6
            x: modelData[0] ? root.width - width - 4 : 4
            y: modelData[1] ? root.height - height - 4 : 4
            angle: modelData[2]
        }
    }
}
