import QtQuick
import qs.core

// Panel: console fill, hairline outline, cut corners, faint scanlines.
Item {
    id: root

    property color fill: Config.colors.bg
    property color stroke: Config.colors.border

    Chamfer {
        anchors.fill: parent
        fill: root.fill
        stroke: root.stroke
    }

    Scanlines {
        anchors {
            fill: parent
            topMargin: Config.shape.cut
            bottomMargin: Config.shape.cut
        }
    }
}
