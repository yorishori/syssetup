import QtQuick
import qs.components as C
import qs.core

// A one-art-pixel line in raised plum.
Rectangle {
    required property C.Divider control
    readonly property int px: Theme.get("pixel.scale") ?? 3

    implicitWidth: control.vertical ? px : 0
    implicitHeight: control.vertical ? 0 : px
    color: Theme.palette.surface
}
