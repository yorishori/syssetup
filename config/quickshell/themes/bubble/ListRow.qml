import QtQuick
import qs.components as C
import qs.core

// Rounded fill on hover and selection, an accent tick on the left for the
// keyboard selection.
Item {
    id: root

    required property C.ListRow control

    Box {
        anchors.fill: parent
        fill: root.control.current || root.control.highlighted || (root.control.hovered && root.control.enabled) ? Theme.palette.surface : "transparent"
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 14
        radius: 1
        color: Theme.palette.accent
        visible: root.control.marker && root.control.current
    }
}
