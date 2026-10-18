import QtQuick
import qs.core
import qs.modules.bar as B

// The faceplate of a rack unit along the top: brushed metal screwed on at
// both ends, casting a shadow on what's below. The middle group (launcher,
// workspaces) sits in a black-glass display window cut into it.
Item {
    id: root

    required property B.BarStrip control
    // Drops slide out from under the plate, touching its lower edge.
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

    // The display window.
    Repeater {
        model: root.control.islands.length > 1 ? [root.control.islands[1]] : []

        Item {
            required property var modelData
            readonly property var items: modelData.filter(i => i && i.visible && i.width > 0)
            readonly property real start: Math.min(...items.map(i => i.x))
            readonly property real end: Math.max(...items.map(i => i.x + i.width))

            x: start - 10
            y: 4
            width: end - start + 20
            height: root.height - 8
            visible: items.length > 0

            Well {
                id: window

                anchors.fill: parent
                // Faintly tinted by the display behind the glass.
                fill: Qt.tint(Theme.palette.bgAlt, Qt.alpha(Theme.palette.accent, 0.035))
            }
            Gloss {
                anchors {
                    fill: parent
                    margins: 1
                }
                roundness: window.r
            }
        }
    }
}
