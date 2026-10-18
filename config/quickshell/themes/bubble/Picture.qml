import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.components as C
import qs.core

// The picture in a rounded frame; the icon on its own.
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
        fill: "transparent"
        stroke: Theme.palette.border
        visible: art.status === Image.Ready
    }
    IconImage {
        anchors.centerIn: parent
        implicitSize: Math.round(root.width * 0.6)
        source: root.control.icon
        visible: art.status !== Image.Ready && root.control.icon !== ""
    }
}
