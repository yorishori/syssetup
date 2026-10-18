import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.bar as B

// A chassis plate sliding out from under the faceplate on rails: square
// where it meets the bar, in whose shadow its top lies, screwed at the
// bottom corners. It runs out firmly and stops with a slight settle.
Item {
    id: root

    required property B.Drop control

    readonly property real overhang: 0
    readonly property real inset: 0
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

    // Shadow under the plate; kept off its top so the bar stays clean.
    RectangularShadow {
        anchors {
            fill: parent
            topMargin: 14
        }
        visible: root.height > 20
        radius: plate.radius
        offset.y: 4
        blur: 16
        color: Qt.alpha(Theme.palette.shadow, Math.min(1, (Theme.values.effects?.shadow ?? 0) * 1.2))
    }

    Metal {
        id: plate

        anchors.fill: parent
        squareTop: true
    }

    // The bar's lower edge throws its shadow on the plate.
    Rectangle {
        width: parent.width
        height: Math.min(10, parent.height)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Theme.palette.shadow, 0.65) }
            GradientStop { position: 1; color: "transparent" }
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
}
