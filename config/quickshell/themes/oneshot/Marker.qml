import QtQuick
import qs.components as C

// A short pill. Lying down, it's centered and lifted a little, so a mark
// along an island's bottom edge stays inside the island.
Item {
    id: root

    required property C.Marker control

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.control.vertical ? 0 : -3
        width: root.control.vertical ? parent.width : Math.min(parent.width, 10)
        height: parent.height
        radius: Math.min(width, height) / 2
        color: root.control.color
    }
}
