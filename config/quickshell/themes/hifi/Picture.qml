import QtQuick
import Quickshell.Widgets
import qs.components as C
import qs.core

// A print behind glass, set into a recessed frame; the icon when there's no
// picture.
Item {
    id: root

    required property C.Picture control
    readonly property bool hasArt: art.status === Image.Ready

    Well {
        id: frame

        anchors.fill: parent
        roundness: (Theme.values.shape?.radius ?? 0) + 2
    }
    Image {
        id: art

        anchors {
            fill: parent
            margins: 3
        }
        source: root.control.source
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.width * 2
        sourceSize.height: root.height * 2
        asynchronous: true
        visible: root.hasArt
    }
    // The print's edge sinking into the frame.
    Rectangle {
        anchors.fill: art
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Theme.palette.shadow, 0.7)
        visible: root.hasArt
    }
    IconImage {
        anchors.centerIn: parent
        implicitSize: Math.round(root.width * 0.55)
        source: root.control.icon
        visible: !root.hasArt && root.control.icon !== ""
    }
    Gloss {
        anchors {
            fill: parent
            margins: 1
        }
        roundness: frame.r
    }
}
