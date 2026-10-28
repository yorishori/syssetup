import QtQuick
import qs.components as C
import qs.core

// An RPG window; its frame takes the card's tone when it has one (amber
// on hover, red for critical), cream otherwise.
Frame {
    required property C.Card control

    frame: control.tone.a > 0 ? control.tone : Theme.palette.border
}
