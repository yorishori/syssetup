import QtQuick
import QtQuick.Effects
import qs.core

// Brushed, anodized metal: the basic hi-fi material. Lit from above, so the
// top catches the light and the bottom falls off, with a bright top edge and
// a dark bevel all round; the grain runs left to right. `raised` sets it on
// a cast shadow. `squareTop` / `squareBottom` keep those corners square, for
// plates that join another (a drop under the bar).
Rectangle {
    id: root

    property real roundness: Theme.values.shape?.radius ?? 0
    property color tint: Theme.palette.bg
    property bool raised: false
    property bool squareTop: false
    property bool squareBottom: false
    readonly property real shadow: Theme.values.effects?.shadow ?? 0

    radius: Math.max(0, Math.min(roundness, width / 2, height / 2))
    topLeftRadius: squareTop ? 0 : radius
    topRightRadius: squareTop ? 0 : radius
    bottomLeftRadius: squareBottom ? 0 : radius
    bottomRightRadius: squareBottom ? 0 : radius
    border.width: Theme.values.shape?.border ?? 1
    border.color: Qt.darker(tint, 2.2)
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.lighter(root.tint, 1.22) }
        GradientStop { position: 0.45; color: root.tint }
        GradientStop { position: 1; color: Qt.darker(root.tint, 1.25) }
    }

    RectangularShadow {
        z: -1
        anchors.fill: parent
        visible: root.raised && root.shadow > 0
        radius: root.radius
        offset.y: 3
        blur: 14
        color: Qt.alpha(Theme.palette.shadow, Math.min(1, root.shadow * 1.2))
    }

    // The grain.
    Image {
        anchors {
            fill: parent
            margins: root.border.width
        }
        source: Qt.resolvedUrl("brushed.png")
        fillMode: Image.Tile
        opacity: Theme.values.effects?.texture ?? 0
        visible: opacity > 0
    }

    // Light catching the top edge.
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: root.border.width
            leftMargin: Math.max(root.border.width, root.topLeftRadius)
            rightMargin: Math.max(root.border.width, root.topRightRadius)
        }
        height: 1
        color: Qt.alpha("white", 0.16)
    }
}
