import QtQuick
import qs.core
import qs.modules.capture as M
import "../glyphs" as G

// Dims everything outside the area; a rounded accent line around it.
Item {
    id: root

    required property M.Selection control
    readonly property rect r: control.area

    Rectangle { x: 0; y: 0; width: parent.width; height: root.r.y; color: Theme.palette.shadow; opacity: 0.5 }
    Rectangle { x: 0; y: root.r.y + root.r.height; width: parent.width; height: parent.height - y; color: Theme.palette.shadow; opacity: 0.5 }
    Rectangle { x: 0; y: root.r.y; width: root.r.x; height: root.r.height; color: Theme.palette.shadow; opacity: 0.5 }
    Rectangle { x: root.r.x + root.r.width; y: root.r.y; width: parent.width - x; height: root.r.height; color: Theme.palette.shadow; opacity: 0.5 }

    Rectangle {
        x: root.r.x - 2
        y: root.r.y - 2
        width: root.r.width + 4
        height: root.r.height + 4
        radius: 8
        color: "transparent"
        border.width: 2
        border.color: Theme.palette.accent
        visible: root.control.hasArea
    }

    G.SelectionTags {
        control: root.control
    }
}
