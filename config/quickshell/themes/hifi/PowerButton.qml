import QtQuick
import qs.modules.bar.widgets as W

// The emergency stop (EStop). Hover and its guard swings open and the head
// lights; it stays open while the session menu is. Pressed, the head sinks.
EStop {
    required property W.PowerButton control

    size: 42
    open: control.hovered || control.open
    pressed: control.pressed
}
