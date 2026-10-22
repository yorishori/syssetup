import QtQuick
import QtQuick.Effects
import Quickshell.Widgets

// An old round sticker of an icon: printed on paper, a touch faded, a chip
// or a scratch here and there (wear.png, turned by `seed` so no
// two wear the same). The icon stays readable: a light one (the white
// symbolic icons panels get) is printed on dark paper, the rest on cream.
Item {
    id: root

    property string source
    property int seed: 0

    implicitWidth: 20
    implicitHeight: 20

    IconTone {
        id: tone

        source: root.source
    }

    Item {
        id: paper

        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: tone.lightness > 0.62 ? "#2c2b29" : "#d8d1c0"
        }
        IconImage {
            anchors.centerIn: parent
            implicitSize: Math.round(root.width * 0.7)
            source: root.source
        }
    }
    Item {
        id: wear

        anchors.fill: parent
        visible: false
        layer.enabled: true

        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("wear.png")
            rotation: root.seed * 137
            smooth: true
        }
    }
    MultiEffect {
        anchors.fill: parent
        source: paper
        saturation: -0.12
        contrast: -0.05
        brightness: -0.02
        maskEnabled: true
        maskSource: wear
        // Light wear: only the deepest chips and scratches show.
        maskThresholdMin: 0.08
        maskSpreadAtMin: 0.2
    }
}
