import QtQuick
import QtQuick.Effects
import qs.components as C
import qs.core

// As a control, a fader: a slot cut into the plate, lit up to the level, with
// a ribbed cap riding in it. As a readout, an LED ladder behind glass, one
// segment per step.
Item {
    id: root

    required property C.Meter control
    readonly property int n: Math.max(1, control.segments)
    readonly property real level: control.lit / n
    readonly property real glow: Theme.glow.opacity ?? 0

    // Readout.
    Well {
        id: window

        anchors.fill: parent
        roundness: 2
        visible: !root.control.interactive
    }
    Item {
        anchors {
            fill: parent
            margins: 2
        }
        visible: !root.control.interactive

        RectangularShadow {
            width: parent.width * root.level
            height: parent.height
            visible: root.control.lit > 0 && root.glow > 0
            blur: 6
            color: Qt.alpha(root.control.color, 0.5 * root.glow)
        }
        Row {
            id: ladder

            anchors.fill: parent
            spacing: 1

            Repeater {
                model: root.n

                Rectangle {
                    required property int index

                    width: (ladder.width - (root.n - 1) * ladder.spacing) / root.n
                    height: parent.height
                    color: index < root.control.lit ? root.control.color : Qt.alpha(root.control.color, 0.1)
                }
            }
        }
    }

    // Fader.
    Well {
        id: slot

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Math.max(5, Math.round(parent.height * 0.55))
        roundness: height / 2
        visible: root.control.interactive
    }
    Item {
        x: slot.x + 1
        anchors.verticalCenter: slot.verticalCenter
        width: Math.max(0, (slot.width - 2) * root.level)
        height: slot.height - 2
        visible: root.control.interactive && root.control.lit > 0

        Behavior on width {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        RectangularShadow {
            anchors.fill: parent
            visible: root.glow > 0
            radius: height / 2
            blur: 6
            color: Qt.alpha(root.control.color, 0.6 * root.glow)
        }
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: root.control.color
        }
    }
    Item {
        id: cap

        readonly property real w: 12

        x: Math.max(0, Math.min(root.width - w, root.width * root.level - w / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: w
        height: root.height + 8
        visible: root.control.interactive

        Behavior on x {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        RectangularShadow {
            anchors.fill: parent
            radius: 2
            offset.y: 2
            blur: 4
            color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
        }
        Rectangle {
            anchors.fill: parent
            radius: 2
            border.width: 1
            border.color: Theme.palette.shadow
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(Theme.palette.fg, 1.05) }
                GradientStop { position: 0.5; color: Theme.palette.dim }
                GradientStop { position: 1; color: Qt.darker(Theme.palette.dim, 1.4) }
            }
        }
        // The grip: grooves across the cap, and the line that marks the level.
        Column {
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: 3

                Rectangle {
                    required property int index

                    width: cap.w - 4
                    height: 1
                    color: index === 1 ? Qt.darker(root.control.color, 1.6) : Qt.alpha(Theme.palette.shadow, 0.45)
                }
            }
        }
    }
}
