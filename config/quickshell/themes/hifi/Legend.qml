import QtQuick
import qs.core

// A small label silk-screened on the panel next to a part: "LINK", "BT".
Engraved {
    caps: true
    tracking: 1.5
    color: Theme.palette.dim
    font.pixelSize: Math.max(8, Theme.font.size - 4)
    font.bold: true
}
