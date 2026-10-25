import QtQuick
import qs.core

// A section of the faceplate, outlined in silkscreen.
Rectangle {
    property color silk: Theme.values.display?.silk ?? Theme.palette.dim

    radius: 4
    color: "transparent"
    border.width: 1
    border.color: Qt.alpha(silk, 0.55)
}
