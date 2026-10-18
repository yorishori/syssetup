import QtQuick
import qs.core

// Faint CRT scanlines. Lay it over a panel; strength from config.
Image {
    source: Qt.resolvedUrl("scanlines.png")
    fillMode: Image.Tile
    smooth: false
    opacity: Theme.values.effects.scanlines
    visible: opacity > 0
}
