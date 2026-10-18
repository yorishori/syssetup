import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.components as C
import qs.core

// The picture with rounded corners; the icon in a soft round tile.
Item {
    id: root

    required property C.Picture control

    Image {
        id: art

        anchors.fill: parent
        source: root.control.source
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.width * 2
        sourceSize.height: root.height * 2
        asynchronous: true
        visible: false
    }
    Box {
        id: artMask

        anchors.fill: parent
        roundness: 14
        fill: "white"
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        source: art
        maskEnabled: true
        maskSource: artMask
        visible: art.status === Image.Ready
    }
    Box {
        anchors.fill: parent
        roundness: 14
        fill: Theme.palette.surface
        visible: art.status !== Image.Ready && root.control.icon !== ""
    }
    IconImage {
        anchors.centerIn: parent
        implicitSize: Math.round(root.width * 0.55)
        source: root.control.icon
        visible: art.status !== Image.Ready && root.control.icon !== ""
    }
}
