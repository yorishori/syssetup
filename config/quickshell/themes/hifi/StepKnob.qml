import QtQuick
import QtQuick.Effects
import qs.core

// A click-stop rotary selector: `count` positions printed round it, the
// pointer on `index`. Click for the next, right click for the previous,
// or scroll. Dead with one position or none.
Item {
    id: selector

    property int count: 0
    property int index: 0
    property string legend
    readonly property bool live: count > 1
    property real angle: count > 1 ? -135 + 270 * index / (count - 1) : 0

    signal stepped(int step)

    width: 52
    height: 62

    Behavior on angle {
        SpringAnimation { spring: 6; damping: 0.45; epsilon: 0.2 }
    }

    // The positions.
    Repeater {
        model: Math.max(selector.count, 1)

        Rectangle {
            required property int index
            readonly property real a: (selector.count > 1 ? -135 + 270 * index / (selector.count - 1) : 0) * Math.PI / 180

            x: selector.width / 2 + Math.sin(a) * 22 - 1.5
            y: 24 - Math.cos(a) * 22 - 1.5
            width: 3
            height: 3
            radius: 1.5
            color: Qt.alpha(Theme.palette.fg, index === selector.index ? 0.8 : 0.3)
        }
    }
    // The knob.
    Item {
        x: (selector.width - 30) / 2
        y: 9
        width: 30
        height: 30
        opacity: selector.live ? 1 : 0.5

        RectangularShadow {
            anchors.fill: parent
            radius: width / 2
            offset.y: 2
            blur: 4
            color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
        }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            border.width: 1
            border.color: Theme.palette.shadow
            gradient: Gradient {
                GradientStop { position: 0; color: knobArea.containsMouse && selector.live ? Qt.lighter(Theme.palette.surface, 1.6) : Qt.lighter(Theme.palette.surface, 1.3) }
                GradientStop { position: 1; color: Qt.darker(Theme.palette.surface, 1.7) }
            }
        }
        // The pointer, a line across the knob's face.
        Item {
            anchors.fill: parent
            rotation: selector.angle

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 3
                width: 3
                height: 11
                radius: 1.5
                color: Theme.palette.fg
            }
        }
    }
    Legend {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        text: selector.legend
        size: 8
    }

    MouseArea {
        id: knobArea

        anchors.fill: parent
        enabled: selector.live
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => selector.stepped(mouse.button === Qt.RightButton ? -1 : 1)
        onWheel: wheel => selector.stepped(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
