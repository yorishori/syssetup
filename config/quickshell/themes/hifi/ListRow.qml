import QtQuick
import qs.components as C
import qs.core

// Rows sit on the plate. Hover catches a little light; the current and
// highlighted rows are pressed into it, and the keyboard selection has its
// LED lit.
Item {
    id: root

    required property C.ListRow control
    readonly property bool sunk: control.current || control.highlighted

    Well {
        anchors.fill: parent
        visible: root.sunk
    }
    Rectangle {
        anchors.fill: parent
        radius: Theme.values.shape?.radius ?? 0
        color: Qt.alpha("white", 0.05)
        visible: !root.sunk && root.control.hovered && root.control.enabled
    }
    Led {
        x: 3
        anchors.verticalCenter: parent.verticalCenter
        size: 6
        on: true
        visible: root.control.marker && root.control.current
    }
}
