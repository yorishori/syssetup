import QtQuick
import qs.core

// A recess cut into the plate, glazed with black glass: displays, inputs,
// slots. Its top lip throws a shadow in; light catches the bottom lip.
// `ring` lights its bezel (focus, a tone).
Item {
    id: root

    property real roundness: Theme.values.shape?.radius ?? 0
    property color fill: Theme.palette.bgAlt
    property color ring: "transparent"
    readonly property real r: Math.max(0, Math.min(roundness, width / 2, height / 2))

    // The lower lip, catching the light.
    Rectangle {
        anchors {
            fill: parent
            bottomMargin: -1
        }
        radius: root.r
        color: Qt.alpha("white", 0.08)
    }

    Rectangle {
        anchors.fill: parent
        radius: root.r
        color: root.fill
        border.width: Theme.values.shape?.border ?? 1
        border.color: root.ring.a > 0 ? root.ring : Qt.alpha(Theme.palette.shadow, 0.9)

        Behavior on border.color {
            ColorAnimation { duration: 140 }
        }

        // The shadow of the top lip.
        Rectangle {
            anchors {
                fill: parent
                margins: parent.border.width
            }
            radius: Math.max(0, root.r - 1)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha(Theme.palette.shadow, 0.75) }
                GradientStop { position: Math.min(0.5, 7 / Math.max(1, root.height)); color: "transparent" }
            }
        }
    }
}
