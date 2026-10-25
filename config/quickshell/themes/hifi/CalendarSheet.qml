import QtQuick
import QtQuick.Effects
import qs.core

// A sheet of the calendar's paper, with its shadow on the wall.
Item {
    required property color paper

    RectangularShadow {
        anchors.fill: parent
        offset.y: 4
        blur: 14
        color: Qt.alpha("black", 0.45 * (Theme.values.effects?.shadow ?? 0.6))
    }
    Rectangle {
        anchors.fill: parent
        color: paper
        border.width: 1
        border.color: Qt.darker(paper, 1.15)
    }
}
