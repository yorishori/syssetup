import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.bar.widgets as W

// The emergency stop: a red mushroom button on a safety-yellow plate, under
// a clear guard hinged at its bottom edge. Hover and the guard swings open
// and the button lights up red; it stays open while the session menu is.
Item {
    id: root

    required property W.PowerButton control
    readonly property bool armed: control.hovered || control.open
    readonly property color hazard: Theme.values.display?.hazard ?? Theme.palette.warn
    readonly property color red: Theme.palette.error

    implicitWidth: 42
    implicitHeight: 42

    // The plate.
    Rectangle {
        anchors.fill: parent
        radius: 5
        border.width: 1
        border.color: Qt.darker(root.hazard, 2.6)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(root.hazard, 1.15) }
            GradientStop { position: 1; color: Qt.darker(root.hazard, 1.35) }
        }

        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 1
                leftMargin: 5
                rightMargin: 5
            }
            height: 1
            color: Qt.alpha("white", 0.45)
        }
    }
    // The collar the button sits in.
    Rectangle {
        anchors.centerIn: parent
        width: 32
        height: 32
        radius: 16
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.darker(root.hazard, 1.9) }
            GradientStop { position: 1; color: Qt.darker(root.hazard, 1.2) }
        }
    }

    RectangularShadow {
        anchors.fill: button
        radius: width / 2
        blur: 16
        spread: 2
        color: Qt.alpha(root.red, 0.9 * (Theme.glow.opacity ?? 0))
        opacity: root.armed ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }
    Rectangle {
        id: button

        readonly property color c: root.armed ? Qt.lighter(root.red, 1.1) : Qt.darker(root.red, 1.6)

        anchors.centerIn: parent
        width: 26
        height: 26
        radius: 13
        scale: root.control.pressed ? 0.88 : 1
        border.width: 1
        border.color: Qt.darker(root.red, 2.5)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(button.c, 1.35) }
            GradientStop { position: 0.6; color: button.c }
            GradientStop { position: 1; color: Qt.darker(button.c, 1.7) }
        }

        Behavior on scale {
            NumberAnimation { duration: 80 }
        }

        // Light on the dome.
        Rectangle {
            x: 6
            y: 4
            width: 10
            height: 5
            radius: 2.5
            color: Qt.alpha("white", 0.45)
        }
    }

    // The hinge along the bottom.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - 5
        width: 24
        height: 4
        radius: 2
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(Theme.palette.border, 1.6) }
            GradientStop { position: 1; color: Qt.darker(Theme.palette.border, 1.4) }
        }
    }

    // The guard: clear plastic with a red tint, swinging down toward you.
    Item {
        id: guard

        x: 3
        y: 3
        width: parent.width - 6
        height: parent.height - 7

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
