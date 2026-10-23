import QtQuick
import QtQuick.Effects
import qs.components as C
import qs.core

// A chassis plate sliding up out of the bottom edge on rails: square where
// it leaves the screen edge, screwed at the top corners.
Item {
    id: root

    required property C.BottomDrawer control

    readonly property real overhang: 0
    readonly property real lift: 0
    property real shownHeight: control.open ? control.openHeight : 0
    property real contentOpacity: control.open ? 1 : 0
    readonly property real popScale: 1

    Behavior on shownHeight {
        NumberAnimation {
            duration: root.control.open ? 300 : 160
            easing.type: root.control.open ? Theme.motion.spring : Easing.InCubic
            easing.overshoot: Theme.motion.bounce
        }
    }
    Behavior on contentOpacity {
        NumberAnimation { duration: root.control.open ? 180 : 70 }
    }

    RectangularShadow {
        anchors.fill: parent
        visible: root.height > 20
        radius: plate.radius
        offset.y: -2
        blur: 16
        color: Qt.alpha(Theme.palette.shadow, Math.min(1, (Theme.values.effects?.shadow ?? 0) * 1.2))
    }

    Metal {
        id: plate

        anchors.fill: parent
        squareBottom: true
    }

    Screw {
        x: 5
        y: 5
        visible: root.height > 40 && (Theme.values.effects?.screws ?? true)
        angle: 20
    }
    Screw {
        x: root.width - width - 5
        y: 5
        visible: root.height > 40 && (Theme.values.effects?.screws ?? true)
        angle: -50
    }
}
