import QtQuick
import QtQuick.Effects
import qs.core

// A momentary center-off switch, (ON)-OFF-(ON): a paddle lever standing in a
// slot, resting in the middle. Push it to a side and it snaps over, then
// springs back to the middle; flicked(-1) for the left, flicked(1) for the
// right. Not `live`, it stays put.
Item {
    id: root

    property bool live: true
    // Where the lever leans: -1 left, 0 middle, 1 right.
    property real lean: 0

    signal flicked(int step)

    implicitWidth: 74
    implicitHeight: 34

    function flick(step: int): void {
        if (!live)
            return;
        spring.stop();
        lean = step;
        flicked(step);
        spring.start();
    }

    // Held over for a moment, then back to the middle.
    SequentialAnimation {
        id: spring

        PauseAnimation { duration: 140 }
        NumberAnimation { target: root; property: "lean"; to: 0; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2.5 }
    }

    // The slot.
    Well {
        x: 12
        y: (root.height - height) / 2
        width: root.width - 24
        height: 14
        roundness: 7
    }
    // The arrows printed either side.
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "◀"
        color: Qt.alpha(Theme.palette.fg, root.live ? 0.6 : 0.25)
        font.pixelSize: 9
    }
    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: "▶"
        color: Qt.alpha(Theme.palette.fg, root.live ? 0.6 : 0.25)
        font.pixelSize: 9
    }

    // The lever: it slides along the slot and tilts the way it's pushed.
    Item {
        x: root.width / 2 - width / 2 + root.lean * (root.width / 2 - 24)
        y: (root.height - height) / 2
        width: 16
        height: root.height
        rotation: root.lean * 14
        opacity: root.live ? 1 : 0.5

        RectangularShadow {
            anchors.fill: parent
            radius: 4
            offset.x: 2 - root.lean * 2
            offset.y: 2
            blur: 4
            color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
        }
        Rectangle {
            anchors.fill: parent
            radius: 4
            border.width: 1
            border.color: "black"
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: area.containsMouse && root.live ? "#4a4c52" : "#2e3034" }
                GradientStop { position: 0.45; color: area.containsMouse && root.live ? "#5d6067" : "#43454b" }
                GradientStop { position: 1; color: "#1c1d20" }
            }
        }
        // The grip.
        Column {
            anchors.centerIn: parent
            spacing: 3

            Repeater {
                model: 4

                Rectangle {
                    width: 8
                    height: 1
                    color: Qt.alpha("black", 0.5)
                }
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.live ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => root.flick(mouse.x < root.width / 2 ? -1 : 1)
        onWheel: wheel => root.flick(wheel.angleDelta.y > 0 ? -1 : 1)
    }
}
