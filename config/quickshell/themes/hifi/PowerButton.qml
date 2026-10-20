import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.bar.widgets as W

// The emergency stop: a red mushroom head standing in a recessed collar on a
// dark plinth, a thin ring of safety yellow round it, under a clear red guard
// hinged at its bottom edge. Hover and the guard swings down toward you and
// the head lights up; it stays open while the session menu is. Pressed, the
// head sinks into the collar.
Item {
    id: root

    required property W.PowerButton control
    readonly property bool armed: control.hovered || control.open
    readonly property color hazard: Theme.values.display?.hazard ?? Theme.palette.warn
    readonly property color red: Theme.palette.error
    readonly property real side: 3
    readonly property real sink: control.pressed ? 2 : 0

    implicitWidth: 42
    implicitHeight: 44

    // The plinth: its side, then its top.
    RectangularShadow {
        anchors {
            fill: parent
            topMargin: root.side
        }
        radius: 6
        offset.y: 2
        blur: 6
        color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
    }
    Rectangle {
        anchors {
            fill: parent
            topMargin: root.side
        }
        radius: 6
        color: "#0b0b0d"
    }
    Rectangle {
        id: face

        width: parent.width
        height: parent.height - root.side
        radius: 6
        border.width: 1
        border.color: "black"
        gradient: Gradient {
            GradientStop { position: 0; color: "#55575e" }
            GradientStop { position: 0.5; color: "#38393f" }
            GradientStop { position: 1; color: "#26272b" }
        }

        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 1
                leftMargin: 6
                rightMargin: 6
            }
            height: 1
            color: Qt.alpha("white", 0.25)
        }
    }

    // The collar: a recess, with the yellow ring round its rim.
    Rectangle {
        id: collar

        x: (face.width - width) / 2
        y: (face.height - height) / 2
        width: 32
        height: 32
        radius: 16
        border.width: 1.5
        border.color: Qt.alpha(root.hazard, 0.85)
        gradient: Gradient {
            GradientStop { position: 0; color: "#050506" }
            GradientStop { position: 1; color: "#2c2d31" }
        }
    }

    // The head: its glow, its shadow in the collar, its skirt, its dome.
    Item {
        id: head

        readonly property color c: root.armed ? Qt.lighter(root.red, 1.08) : Qt.darker(root.red, 1.7)

        x: collar.x + 3
        y: collar.y + 2 + root.sink
        width: 26
        height: 26

        Behavior on y {
            NumberAnimation { duration: 70 }
        }

        RectangularShadow {
            anchors.fill: parent
            radius: width / 2
            blur: 16
            spread: 2
            color: Qt.alpha(root.red, 0.9 * (Theme.glow.opacity ?? 0))
            opacity: root.armed ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }
        RectangularShadow {
            anchors.fill: parent
            radius: width / 2
            offset.y: 4 - root.sink
            blur: 4
            color: Qt.alpha("black", 0.8)
        }
        // The skirt, below the dome.
        Rectangle {
            y: 3 - root.sink
            width: parent.width
            height: parent.height
            radius: width / 2
            color: Qt.darker(head.c, 2.4)
        }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            border.width: 1
            border.color: Qt.darker(head.c, 2.2)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(head.c, 1.45) }
                GradientStop { position: 0.55; color: head.c }
                GradientStop { position: 1; color: Qt.darker(head.c, 1.6) }
            }
        }
        // Light bouncing back onto the dome's lower rim.
        Rectangle {
            x: 5
            y: parent.height - 7
            width: parent.width - 10
            height: 3
            radius: 1.5
            color: Qt.alpha(Qt.lighter(head.c, 1.6), 0.35)
        }
        // The highlight.
        Rectangle {
            x: 6
            y: 4
            width: 9
            height: 5
            radius: 2.5
            rotation: -20
            color: Qt.alpha("white", root.armed ? 0.6 : 0.4)
        }
    }

    // The hinge along the bottom of the plinth.
    Rectangle {
        anchors.horizontalCenter: face.horizontalCenter
        y: face.height - 5
        width: 24
        height: 4
        radius: 2
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(Theme.palette.border, 1.6) }
            GradientStop { position: 1; color: Qt.darker(Theme.palette.border, 1.4) }
        }
    }

    // The guard: clear red plastic, swinging down toward you.
    Item {
        id: guard

        x: 3
        y: 3
        width: face.width - 6
        height: face.height - 7

        transform: Rotation {
            origin.y: guard.height
            axis { x: 1; y: 0; z: 0 }
            angle: root.armed ? -130 : 0

            Behavior on angle {
                NumberAnimation { duration: 260; easing.type: root.armed ? Easing.OutBack : Easing.InQuad; easing.overshoot: 1.2 }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 4
            color: Qt.alpha(root.red, 0.22)
            border.width: 2
            border.color: Qt.alpha(Qt.lighter(root.red, 1.4), 0.75)
        }
        // The tab you lift it by.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: -2
            width: 12
            height: 4
            radius: 2
            color: Qt.alpha(Qt.lighter(root.red, 1.3), 0.85)
        }
        Gloss {
            anchors {
                fill: parent
                margins: 1
            }
            roundness: 3
        }
    }
}
