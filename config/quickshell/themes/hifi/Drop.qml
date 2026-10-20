import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.bar as B

// A hinged door below the panel, its controls on the inside. Opening, it
// swings down from where it's folded up under the panel, comes past
// hanging straight and settles; closing, it swings back up. Steel, with the
// piano hinge along its top and screws at its bottom corners; while it
// swings, its face turns from the light and darkens.
Item {
    id: root

    required property B.Drop control

    readonly property real overhang: 0
    readonly property real inset: 0
    readonly property real popScale: 1
    // The face, and what's on it, turning from the light as it swings.
    readonly property real contentOpacity: 1 - 0.6 * swing / 90
    // Folded up (90) to hanging (0).
    property real swing: 90
    // Full height while it shows at all; nothing once folded away.
    readonly property real shownHeight: swing < 89.5 ? control.openHeight : 0

    // It drops, swings past hanging and settles; it's lifted back briskly.
    Component.onCompleted: swing = control.open ? 0 : 90
    Connections {
        target: root.control

        function onOpenChanged(): void {
            fold.stop();
            drop.stop();
            (root.control.open ? drop : fold).start();
        }
    }
    NumberAnimation {
        id: drop

        target: root
        property: "swing"
        to: 0
        duration: 520
        easing.type: Easing.OutBack
        easing.overshoot: 1.4
    }
    NumberAnimation {
        id: fold

        target: root
        property: "swing"
        to: 90
        duration: 230
        easing.type: Easing.InCubic
    }

    // Its shadow on what's below, while it hangs.
    RectangularShadow {
        anchors {
            fill: parent
            topMargin: 14
        }
        radius: plate.radius
        offset.y: 6
        blur: 18
        color: Qt.alpha(Theme.palette.shadow, Math.min(1, (Theme.values.effects?.shadow ?? 0) * 1.2))
        opacity: 1 - root.swing / 90
    }

    Metal {
        id: plate

        anchors.fill: parent
        squareTop: true
    }

    // The piano hinge.
    Item {
        width: parent.width
        height: 8

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(Theme.palette.border, 1.7) }
                GradientStop { position: 0.5; color: Theme.palette.border }
                GradientStop { position: 1; color: Qt.darker(Theme.palette.border, 1.8) }
            }
        }
        // The knuckles.
        Row {
            anchors.fill: parent

            Repeater {
                model: Math.max(0, Math.ceil(parent.width / 24))

                Rectangle {
                    required property int index

                    width: 24
                    height: 8
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.alpha("black", index % 2 ? 0.5 : 0.25)
                }
            }
        }
    }

    Screw {
        x: 5
        y: root.height - height - 5
        visible: root.height > 40 && (Theme.values.effects?.screws ?? true)
        angle: 60
    }
    Screw {
        x: root.width - width - 5
        y: root.height - height - 5
        visible: root.height > 40 && (Theme.values.effects?.screws ?? true)
        angle: -15
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.6 * root.swing / 90
    }
}
