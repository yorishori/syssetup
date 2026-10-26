import QtQuick
import qs.components as C
import qs.core

// A one-art-pixel amber block on the right edge.
Item {
    id: root

    required property C.ScrollLamp control
    readonly property int px: Theme.get("pixel.scale") ?? 3

    Rectangle {
        x: root.width - width
        y: Math.round(root.control.position * root.height / root.px) * root.px
        width: root.px
        height: Math.max(root.px, Math.round(root.control.ratio * root.height / root.px) * root.px)
        color: Theme.palette.accent
        visible: root.control.ratio < 1
    }
}
