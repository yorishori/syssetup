import QtQuick
import qs.components as C
import qs.core

// Rounded highlight on hover and selection; the keyboard selection gets a
// little accent pill on the left.
Item {
    id: root

    required property C.ListRow control

    Box {
        anchors.fill: parent
        roundness: 10
        fill: root.control.current || root.control.highlighted ? Theme.palette.surface
            : root.control.hovered && root.control.enabled ? Qt.alpha(Theme.palette.surface, 0.55)
            : "transparent"
    }
    Rectangle {
        x: 3
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 14
        radius: 1.5
        color: Theme.palette.accent
        visible: root.control.marker && root.control.current
    }
}
