import QtQuick
import QtQuick.Effects
import qs.core

// A keycap standing on the plate: convex and lit from above, its side
// showing underneath. `down` pushes it in (pressed, or latched when on): it
// sinks by `travel`, its side and shadow go, and its face turns concave.
// Whatever sits on the cap moves with it by `shift`. `glowColor` backlights
// its edge.
Item {
    id: root

    property bool down: false
    property bool hovered: false
    property real roundness: Theme.values.shape?.radius ?? 0
    property color tint: Theme.palette.surface
    property color glowColor: "transparent"
    readonly property real travel: 2
    readonly property real shift: down ? travel - 0.5 : 0
    readonly property real r: Math.max(0, Math.min(roundness, width / 2, height / 2))
    readonly property real shadow: Theme.values.effects?.shadow ?? 0
    readonly property color face: hovered ? Qt.lighter(tint, 1.12) : tint

    // Contact shadow, gone when pushed in.
    RectangularShadow {
        anchors {
            fill: parent
            topMargin: root.travel
        }
        radius: root.r
        offset.y: 1
        blur: 4
        color: Qt.alpha(Theme.palette.shadow, root.down ? 0 : root.shadow)
    }

    // Backlight around the edge.
    RectangularShadow {
        anchors.fill: cap
        visible: root.glowColor.a > 0
        radius: root.r
        blur: 8
        spread: 1
        color: Qt.alpha(root.glowColor, 0.5 * (Theme.glow.opacity ?? 0))
    }

    // The side of the key.
    Rectangle {
        anchors {
            fill: parent
            topMargin: root.travel
        }
        radius: root.r
        color: Qt.darker(root.tint, 1.9)
    }

    Rectangle {
        id: cap

        y: root.shift
        width: parent.width
        height: parent.height - root.travel
        radius: root.r
        border.width: Theme.values.shape?.border ?? 1
        border.color: root.glowColor.a > 0 ? root.glowColor : Qt.darker(root.tint, 2.1)
        gradient: Gradient {
            GradientStop { position: 0; color: root.down ? Qt.darker(root.face, 1.3) : Qt.lighter(root.face, 1.28) }
            GradientStop { position: 1; color: root.down ? Qt.darker(root.face, 1.05) : Qt.darker(root.face, 1.12) }
        }

        Behavior on y {
            NumberAnimation { duration: 70; easing.type: Easing.OutQuad }
        }

        // Light on the top edge of a cap that stands up.
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: parent.border.width
                leftMargin: Math.max(1, root.r)
                rightMargin: Math.max(1, root.r)
            }
            height: 1
            color: Qt.alpha("white", root.down ? 0.04 : 0.2)
        }
    }
}
