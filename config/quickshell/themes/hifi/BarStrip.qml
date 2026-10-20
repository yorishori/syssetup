import QtQuick
import qs.core
import qs.modules.bar as B

// The work table's panel along the top: brushed metal screwed on at both
// ends, casting a shadow on what's below. Its parts are set into it.
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

    Metal {
        anchors.fill: parent
        roundness: 0
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
