import QtQuick
import qs.components as C
import qs.core

// The console color laid over the screen, at the backdrop strength.
Rectangle {
    id: root

    required property C.Backdrop control
    readonly property real strength: Theme.values.effects?.backdrop ?? 0

    color: Theme.palette.bg
    opacity: !control.shown ? 0 : control.strong ? Math.max(strength, 0.6) : strength
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
    }
}
