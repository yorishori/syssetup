import QtQuick
import qs.core
import qs.modules.capture as M

// A camera's viewfinder: everything outside the area dimmed, a fine line
// round it and bright crop marks on its corners.
Item {
    id: root

    required property M.Selection control
    readonly property rect r: control.area
    readonly property real mark: Math.min(18, r.width / 3, r.height / 3)

    Rectangle { x: 0; y: 0; width: parent.width; height: root.r.y; color: Theme.palette.shadow; opacity: 0.55 }
    Rectangle { x: 0; y: root.r.y + root.r.height; width: parent.width; height: parent.height - y; color: Theme.palette.shadow; opacity: 0.55 }
    Rectangle { x: 0; y: root.r.y; width: root.r.x; height: root.r.height; color: Theme.palette.shadow; opacity: 0.55 }
    Rectangle { x: root.r.x + root.r.width; y: root.r.y; width: parent.width - x; height: root.r.height; color: Theme.palette.shadow; opacity: 0.55 }

    Rectangle {
        x: root.r.x - 1
        y: root.r.y - 1
        width: root.r.width + 2
        height: root.r.height + 2
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Theme.palette.accent, 0.6)
        visible: root.control.hasArea
    }

    // Crop marks: [x side, y side] of each corner.
    Repeater {
        model: [[0, 0], [1, 0], [0, 1], [1, 1]]

        Item {
            required property var modelData

            x: root.r.x + modelData[0] * root.r.width - (modelData[0] ? root.mark : 0) + (modelData[0] ? 3 : -3)
            y: root.r.y + modelData[1] * root.r.height - (modelData[1] ? root.mark : 0) + (modelData[1] ? 3 : -3)
            width: root.mark
            height: root.mark
            visible: root.control.hasArea

            Rectangle {
                y: parent.modelData[1] ? parent.height - height : 0
                width: parent.width
                height: 3
                color: Theme.palette.accent
            }
            Rectangle {
                x: parent.modelData[0] ? parent.width - width : 0
                width: 3
                height: parent.height
                color: Theme.palette.accent
            }
        }
    }
}
