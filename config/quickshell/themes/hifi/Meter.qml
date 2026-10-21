import QtQuick
import QtQuick.Effects
import qs.components as C
import qs.core

// As a control, a fader: a slot cut into the plate, lit up to the level, with
// a ribbed cap riding in it. As a readout, an LED ladder behind glass, one
// segment per step. Upright (`vertical`), it's a mixer's channel fader: it
// fills from the bottom, under a square cap. A clear color leaves the slot
// unlit, a plain analog fader.
Item {
    id: root

    required property C.Meter control
    readonly property bool upright: control.vertical
    readonly property int n: Math.max(1, control.segments)
    readonly property real level: control.lit / n
    readonly property real glow: Theme.glow.opacity ?? 0
    // Along the travel, and across it.
    readonly property real length: upright ? height : width
    readonly property real breadth: upright ? width : height

    // A box `from` and `size` along the travel, `across` the travel centered,
    // turned to lie along it.
    function box(from: real, size: real, across: real): rect {
        return upright ? Qt.rect((width - across) / 2, height - from - size, across, size)
                       : Qt.rect(from, (height - across) / 2, size, across);
    }

    // Readout.
    Well {
        anchors.fill: parent
        roundness: 2
        visible: !root.control.interactive
    }
    Item {
        id: ladder

        readonly property real span: root.length - 4
        readonly property real step: (span + 1) / root.n

        anchors {
            fill: parent
            margins: 2
        }
        visible: !root.control.interactive

        RectangularShadow {
            readonly property rect area: root.box(0, ladder.span * root.level, root.breadth - 4)

            x: area.x - 2
            y: area.y - 2
            width: area.width
            height: area.height
            visible: root.control.lit > 0 && root.glow > 0
            blur: 6
            color: Qt.alpha(root.control.color, 0.5 * root.glow)
        }
        Repeater {
            model: root.n

            Rectangle {
                required property int index
                readonly property rect area: root.box(index * ladder.step, ladder.step - 1, root.breadth - 4)

                x: area.x - 2
                y: area.y - 2
                width: area.width
                height: area.height
                color: index < root.control.lit ? root.control.color : Qt.alpha(root.control.color, 0.1)
            }
        }
    }

    // Fader.
    Well {
        id: slot

        readonly property real across: Math.max(5, Math.round(root.breadth * 0.55))
        readonly property rect area: root.box(0, root.length, across)

        x: area.x
        y: area.y
        width: area.width
        height: area.height
        roundness: across / 2
        visible: root.control.interactive
    }
    Item {
        id: fill

        property real reach: Math.max(0, (root.length - 2) * root.level)
        readonly property rect area: root.box(1, reach, slot.across - 2)

        x: area.x
        y: area.y
        width: area.width
        height: area.height
        visible: root.control.interactive && root.control.lit > 0 && root.control.color.a > 0

        Behavior on reach {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        RectangularShadow {
            anchors.fill: parent
            visible: root.glow > 0
            radius: Math.min(width, height) / 2
            blur: 6
            color: Qt.alpha(root.control.color, 0.6 * root.glow)
        }
        Rectangle {
            anchors.fill: parent
            radius: Math.min(width, height) / 2
            color: root.control.color
        }
    }
    Item {
        id: cap

        readonly property real thick: root.upright ? 18 : 12
        property real at: Math.max(0, Math.min(root.length - thick, root.length * root.level - thick / 2))
        readonly property rect area: root.box(at, thick, root.breadth + (root.upright ? 16 : 8))

        x: area.x
        y: area.y
        width: area.width
        height: area.height
        visible: root.control.interactive

        Behavior on at {
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
        Grid {
            anchors.centerIn: parent
            rows: root.upright ? 3 : 1
            columns: root.upright ? 1 : 3
            spacing: 2

            Repeater {
                model: 3

                Rectangle {
                    required property int index

                    width: root.upright ? cap.width - 4 : 1
                    height: root.upright ? 1 : cap.height - 4
                    // The middle one marks the level.
                    color: index !== 1 ? Qt.alpha(Theme.palette.shadow, 0.45)
                        : root.control.color.a > 0 ? Qt.darker(root.control.color, 1.6) : "#f4f2ec"
                }
            }
        }
    }
}
