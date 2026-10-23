import QtQuick
import qs.components as C
import qs.core

// The room lights going down behind a big panel.
Rectangle {
    id: root

    required property C.Backdrop control
    readonly property real strength: Theme.values.effects?.backdrop ?? 0

    color: Theme.palette.shadow
    opacity: !control.shown ? 0 : control.strong ? Math.max(strength, 0.65) : strength
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
    }
}
