import QtQuick
import QtQuick.Effects
import qs.core

// A big tuning knob: knurled round its edge, a dimple for a fingertip. It
// clicks round a step at a time: stepped(-1) or stepped(1). Click its left
// or right half, or scroll. Its turn follows `position` (what it's tuned
// to, however that was picked), so it moves with the list it steps through.
// Not `live`, it stays put.
Item {
    id: root

    property bool live: true
    // Where it's tuned to, in steps; it springs round to each new one.
    property int position: 0
    property real angle: position * 24

    signal stepped(int step)

    implicitWidth: 72
    implicitHeight: 72

    function step(by: int): void {
        if (live)
            stepped(by);
    }

    Behavior on angle {
        SpringAnimation { spring: 5; damping: 0.4; epsilon: 0.2 }
    }

    RectangularShadow {
        anchors.fill: parent
        radius: width / 2
        offset.y: 3
        blur: 8
        color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
    }
    // The skirt, and the knurled grip turning on it.
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "#0d0d0f"
        border.width: 1
        border.color: "black"
    }
    Item {
        anchors {
            fill: parent
            margins: 3
        }
        rotation: root.angle
        opacity: root.live ? 1 : 0.5

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0; color: area.containsMouse && root.live ? "#5b5d63" : "#4a4c51" }
                GradientStop { position: 1; color: "#18191b" }
            }
        }
        Repeater {
            model: 48

            Item {
                required property int index

                anchors.fill: parent
                rotation: index * 7.5

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 1.5
                    height: 5
                    color: Qt.alpha("black", 0.55)
                }
            }
        }
        // The cap, a shade lighter, and the dimple.
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 14
            height: width
            radius: width / 2
            border.width: 1
            border.color: Qt.alpha("black", 0.6)
            gradient: Gradient {
                GradientStop { position: 0; color: "#55575c" }
                GradientStop { position: 1; color: "#242528" }
            }
        }
        Rectangle {
            x: parent.width / 2 - width / 2
            y: 13
            width: 11
            height: 11
            radius: 5.5
            gradient: Gradient {
                GradientStop { position: 0; color: "#141517" }
                GradientStop { position: 1; color: "#4a4c51" }
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.live ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => root.step(mouse.x < root.width / 2 ? -1 : 1)
        onWheel: wheel => root.step(wheel.angleDelta.y > 0 ? -1 : 1)
    }
}
