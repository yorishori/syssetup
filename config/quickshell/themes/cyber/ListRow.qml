import QtQuick
import qs.components as C
import qs.core

// Cut-corner fill on hover and selection, an accent tick on the left for the
// keyboard selection.
Item {
    id: root

    required property C.ListRow control

    Chamfer {
        anchors.fill: parent
        cut: 5
        fill: root.control.current || root.control.highlighted || (root.control.hovered && root.control.enabled) ? Theme.palette.surface : "transparent"
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 14
        color: Theme.palette.accent
        visible: root.control.marker && root.control.current
    }
}
