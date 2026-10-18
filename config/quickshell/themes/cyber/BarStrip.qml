import QtQuick
import qs.core
import qs.modules.bar as B

// A dark console strip, distinct from wallpaper and windows, with scanlines
// and a hairline bottom edge; drops continue the hairline around themselves.
Rectangle {
    id: root

    required property B.BarStrip control
    readonly property real seam: Theme.values.shape?.border ?? 0

    color: Theme.palette.bg

    Scanlines {
        anchors.fill: parent
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: root.seam
        color: Theme.palette.border
    }
}
