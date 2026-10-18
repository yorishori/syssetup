import QtQuick
import qs.components as C
import qs.core

// A floating rounded card on a soft shadow; outlined in its tone, when it
// has one.
Box {
    required property C.Card control

    fill: Theme.palette.bg
    stroke: control.tone
    raised: true
}
