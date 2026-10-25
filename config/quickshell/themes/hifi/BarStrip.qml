import QtQuick
import qs.core
import qs.modules.bar as B

// The work table's panel along the top: a dark walnut board, the same wood
// as the drawers' cases but oiled deeper, screwed on at both ends and
// casting a shadow on what's below. Its parts are set into it.
Item {
    id: root

    required property B.BarStrip control
    // Drops slide out from under the panel, touching its lower edge.
    readonly property real seam: 0

    // The shadow it casts.
    Rectangle {
        y: root.height
        width: root.width
        height: 10
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Theme.palette.shadow, 0.7 * (Theme.values.effects?.shadow ?? 0)) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    // The board: the drawers' walnut, its grain running the length of the
    // panel, darkened and lit from above.
    Item {
        anchors.fill: parent
        clip: true

        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("wood.png")
            fillMode: Image.Tile
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha("#120804", 0.42) }
                GradientStop { position: 0.5; color: Qt.alpha("#120804", 0.55) }
                GradientStop { position: 1; color: Qt.alpha("#0a0402", 0.72) }
            }
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 1
            border.color: "#1c0f07"
        }
        // Light catching the top edge.
        Rectangle {
            x: 1
            y: 1
            width: parent.width - 2
            height: 1
            color: Qt.alpha("#e0b48a", 0.22)
        }
    }

    Screw {
        x: 5
        anchors.verticalCenter: parent.verticalCenter
        angle: 35
    }
    Screw {
        x: root.width - width - 5
        anchors.verticalCenter: parent.verticalCenter
        angle: -20
    }
}
