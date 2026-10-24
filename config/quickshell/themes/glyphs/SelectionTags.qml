import QtQuick
import qs.components
import qs.core

// The glyph themes' selection tags: the area's size by its corner, and how
// to choose at the top of the screen, until it's chosen.
Item {
    id: root

    required property var control
    readonly property rect r: control.area

    anchors.fill: parent

    Tag {
        x: root.r.x
        y: root.r.y > 28 ? root.r.y - height - 6 : root.r.y + 6
        text: `${Math.round(root.r.width)}×${Math.round(root.r.height)}`
        fill: Theme.palette.accent
        visible: root.control.hasArea && !root.control.marking
    }
    Tag {
        anchors {
            top: parent.top
            topMargin: 48
            horizontalCenter: parent.horizontalCenter
        }
        text: root.control.kind === "screenshot" ? "click a window · drag a region · enter for the screen" : "record: click a window · drag a region · enter for the screen"
        fill: Theme.palette.surface
        textColor: Theme.palette.fg
        size: Theme.font.size - 1
        visible: !root.control.marking
    }
}
