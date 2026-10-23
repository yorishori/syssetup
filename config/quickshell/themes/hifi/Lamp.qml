import QtQuick
import qs.components as C

// An LED in its bezel.
Led {
    required property C.Lamp control

    size: 8
    on: control.on
    color: control.litColor
    pulse: control.pulse
}
