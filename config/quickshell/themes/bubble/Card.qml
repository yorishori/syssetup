import QtQuick
import qs.components as C
import qs.core

// Rounded base-colored panel, outlined (in the tone, when there is one).
Box {
    required property C.Card control

    fill: Theme.palette.bg
    stroke: control.tone.a > 0 ? control.tone : Theme.palette.border
}
