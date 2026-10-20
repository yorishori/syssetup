import QtQuick
import QtQuick.Effects
import Quickshell.Widgets

// An old round sticker of an icon: printed on paper, a little faded, its rim
// chipped and a few scratches through it (wear.png, turned by `seed` so no
// two wear the same). The icon stays readable.
Item {
    id: root

    property string source
    property int seed: 0

    implicitWidth: 20
    implicitHeight: 20

    Item {
        id: paper

        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#d8d1c0"
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
        saturation: -0.2
        contrast: -0.1
        brightness: -0.04
        maskEnabled: true
        maskSource: wear
        // Light wear: the rim chips and scratches show, the icon stays readable.
        maskThresholdMin: 0.2
        maskSpreadAtMin: 0.25
    }
}
