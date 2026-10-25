import QtQuick
import QtQuick.Effects
import qs.core

// A drive caddy in its bay. `out` slides it half out of the bay.
Item {
    id: caddy

    property string label
    property string detail
    property string reading
    property real usage: -1   // -1: no bargraph
    property bool out: false
    property color link: "transparent"  // its link lamp, for a share
    default property alias keys: keyRow.data

    width: parent?.width ?? 0
    height: 58

    // The bay.
    Rectangle {
        anchors.fill: parent
        radius: 3
        color: "#070707"
        border.width: 1
        border.color: "black"
    }
    // The caddy's front.
    Item {
        id: front

        x: caddy.out ? 26 : 3
        y: 3
        width: caddy.width - 6 - (caddy.out ? 23 : 0)
        height: caddy.height - 6

        RectangularShadow {
            anchors.fill: parent
            radius: 2
            offset.x: caddy.out ? -6 : 0
            blur: caddy.out ? 8 : 2
            color: Qt.alpha("black", 0.7)
        }
        Rectangle {
            anchors.fill: parent
            radius: 2
            border.width: 1
            border.color: "black"
            gradient: Gradient {
                GradientStop { position: 0; color: "#4a4c52" }
                GradientStop { position: 0.12; color: "#33353a" }
                GradientStop { position: 1; color: "#212226" }
            }
        }
        // Its vent.
        Image {
            x: 6
            y: 6
            width: 44
            height: parent.height - 12
            source: Qt.resolvedUrl("grille.png")
            fillMode: Image.Tile
            opacity: 0.7
        }
        Led {
            x: 20
            anchors.verticalCenter: parent.verticalCenter
            size: 8
            on: caddy.link.a > 0
            color: caddy.link.a > 0 ? caddy.link : Theme.palette.ok
            visible: caddy.link.a > 0 || caddy.usage < 0
        }
        Readout {
            x: 60
            anchors.verticalCenter: parent.verticalCenter
            width: 300
            height: parent.height - 8
            size: 12
            line1: caddy.label
            line2: [caddy.detail, caddy.reading].filter(t => t).join(" · ")
        }
        Bargraph {
            anchors {
                right: keyRow.left
                rightMargin: 14
                verticalCenter: parent.verticalCenter
            }
            value: caddy.usage
            visible: caddy.usage >= 0
        }
        Row {
            id: keyRow

            anchors {
                right: parent.right
                rightMargin: 8
                verticalCenter: parent.verticalCenter
            }
            spacing: 8
        }
    }
}
