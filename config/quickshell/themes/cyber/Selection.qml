import QtQuick
import qs.core
import qs.modules.capture as M
import "../glyphs" as G

// Dims everything outside the area; a 2px accent line around it.
Item {
    id: root

    required property M.Selection control
    readonly property rect r: control.area

    Rectangle { x: 0; y: 0; width: parent.width; height: root.r.y; color: "#000"; opacity: 0.45 }
    Rectangle { x: 0; y: root.r.y + root.r.height; width: parent.width; height: parent.height - y; color: "#000"; opacity: 0.45 }
    Rectangle { x: 0; y: root.r.y; width: root.r.x; height: root.r.height; color: "#000"; opacity: 0.45 }
    Rectangle { x: root.r.x + root.r.width; y: root.r.y; width: parent.width - x; height: root.r.height; color: "#000"; opacity: 0.45 }

    Rectangle {
        x: root.r.x - 1
        y: root.r.y - 1
        width: root.r.width + 2
        height: root.r.height + 2
        color: "transparent"
        border.width: 2
        border.color: Theme.palette.accent
        visible: root.control.hasArea
    }

    G.SelectionTags {
        control: root.control
    }
}
