import QtQuick
import qs.core

// Faint CRT scanlines. Lay it over a panel; strength from the theme.
Image {
    source: Qt.resolvedUrl("scanlines.png")
    fillMode: Image.Tile
    smooth: false
    opacity: Theme.values.effects?.scanlines ?? 0
    visible: opacity > 0
}
