import QtQuick
import qs.components as C
import qs.core

// The console color with scanlines.
Rectangle {
    required property C.ScreenFill control

    color: Theme.palette.bg

    Scanlines {
        anchors.fill: parent
    }
}
