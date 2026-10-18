import QtQuick
import qs.core
import qs.modules.bar as B

// A plain strip in the base color; drops merge into it.
Rectangle {
    required property B.BarStrip control
    readonly property real seam: 0

    color: Theme.palette.bg
}
