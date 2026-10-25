import QtQuick
import qs.components as C
import qs.core
import qs.modules.audio as M

// An app's channel: its name, an upright fader with its scale, the mute.
Item {
    id: channel

    required property M.AudioPanel panel
    property var nodes: []
    property string name
    readonly property real volume: nodes[0]?.audio?.volume ?? 0

    implicitWidth: 80
    implicitHeight: strip.implicitHeight + 24

    Column {
        id: strip

        anchors.horizontalCenter: parent.horizontalCenter
        y: 12
        spacing: 12

        Legend {
            anchors.horizontalCenter: parent.horizontalCenter
            text: channel.name.slice(0, 9)
        }

        // The fader, with its scale printed beside it.
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 60
            height: 150

            Repeater {
                model: 11

                Item {
                    required property int index
                    readonly property bool major: index % 2 === 0

                    y: 6 + (10 - index) * (138 / 10) - height / 2
                    width: 22
                    height: 10

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.index
                        visible: parent.major
                        color: Qt.alpha(Theme.palette.fg, 0.55)
                        font.family: Theme.font.family
                        font.pixelSize: 8
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.major ? 7 : 4
                        height: 1
                        color: Qt.alpha(Theme.palette.fg, parent.major ? 0.5 : 0.3)
                    }
                }
            }
            C.Meter {
                x: 32
                y: 6
                width: 14
                height: 138
                vertical: true
                value: channel.volume
                color: "transparent"
                onMoved: value => channel.panel.setLevel(channel.nodes, value)
            }
        }

        MuteKey {
            anchors.horizontalCenter: parent.horizontalCenter
            panel: channel.panel
            nodes: channel.nodes
        }
    }
}
