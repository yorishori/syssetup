import QtQuick
import qs.core

// Faint CRT scanlines. Lay it over a panel; strength from config.
Image {
    source: Qt.resolvedUrl("../assets/scanlines.png")
    fillMode: Image.Tile
    smooth: false
    opacity: Config.effects.scanlines
    visible: opacity > 0
}
