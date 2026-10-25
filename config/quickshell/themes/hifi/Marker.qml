import QtQuick
import QtQuick.Effects
import qs.components as C
import qs.core

// A lit segment of the display, blooming in its color. Lying down, it's
// centered and lifted a little, so a mark along the display's bottom edge
// stays on the glass.
Item {
    id: root

    required property C.Marker control

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.control.vertical ? 0 : -5
        width: root.control.vertical ? parent.width : Math.min(parent.width, 12)
        height: parent.height

        RectangularShadow {
            anchors.fill: parent
            visible: (Theme.glow.opacity ?? 0) > 0
            radius: Math.min(width, height) / 2
            blur: 7
            color: Qt.alpha(root.control.color, 0.85 * (Theme.glow.opacity ?? 0))
        }
        Rectangle {
            anchors.fill: parent
            radius: Math.min(width, height) / 2
            color: root.control.color
        }
    }
}
