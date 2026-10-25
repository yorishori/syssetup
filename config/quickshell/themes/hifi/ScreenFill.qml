import QtQuick
import qs.components as C
import qs.core

// The grille of a speaker cabinet over the whole screen: perforated metal,
// lit from above.
Rectangle {
    required property C.ScreenFill control

    gradient: Gradient {
        GradientStop { position: 0; color: Qt.lighter(Theme.palette.bg, 1.1) }
        GradientStop { position: 1; color: Qt.darker(Theme.palette.bg, 1.6) }
    }

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("grille.png")
        fillMode: Image.Tile
        smooth: false
    }
}
