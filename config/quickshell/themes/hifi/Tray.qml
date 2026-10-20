import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.bar.widgets as W

// A jack field labelled AUX: a row of sockets, always there; each running
// tray app is a plug in one, with an old sticker of its icon on the cap. Plugs push in as apps start; sockets
// are added if there are more apps than sockets.
Row {
    id: root

    required property W.Tray control
    readonly property bool shown: true
    readonly property int sockets: Math.max(5, control.items.length)
    readonly property int pitch: 28

    function slotRect(index: int): rect {
        return Qt.rect(field.x + 4 + index * pitch, field.y + (field.height - 26) / 2, 26, 26);
    }

    spacing: 6

    Legend {
        anchors.verticalCenter: parent.verticalCenter
        text: "aux"
    }

    Item {
        id: field

        anchors.verticalCenter: parent.verticalCenter
        width: root.sockets * root.pitch + 6
        height: 34

        Well {
            anchors.fill: parent
            roundness: 4
            fill: Qt.darker(Theme.palette.bg, 1.5)
        }

        // The sockets: a nut round a hole.
        Repeater {
            model: root.sockets

            Item {
                required property int index

                x: 4 + index * root.pitch
                y: (field.height - 26) / 2
                width: 26
                height: 26

                Rectangle {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    radius: 9
                    border.width: 1
                    border.color: Theme.palette.shadow
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.lighter(Theme.palette.border, 1.5) }
                        GradientStop { position: 1; color: Qt.darker(Theme.palette.border, 1.5) }
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 9
                    height: 9
                    radius: 4.5
                    color: Theme.palette.shadow
                }
            }
        }

        // The plugs.
        Repeater {
            model: root.control.items

            Item {
                id: plug

                required property int index
                required property var modelData

                x: 4 + index * root.pitch
                y: (field.height - 26) / 2
                width: 26
                height: 26

                // Pushed in: it comes from closer to you and settles.
                scale: 1
                opacity: 1
                Component.onCompleted: insert.start()

                ParallelAnimation {
                    id: insert

                    NumberAnimation { target: plug; property: "scale"; from: 1.35; to: 1; duration: 260; easing.type: Easing.OutCubic }
                    NumberAnimation { target: plug; property: "opacity"; from: 0; to: 1; duration: 140 }
                }

                RectangularShadow {
                    anchors.fill: cap
                    radius: width / 2
                    offset.y: 2
                    blur: 5
                    color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
                }
                Rectangle {
                    id: cap

                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    radius: 12
                    border.width: 1
                    border.color: Theme.palette.shadow
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.lighter(Theme.palette.surface, 1.3) }
                        GradientStop { position: 1; color: Qt.darker(Theme.palette.surface, 1.5) }
                    }
                }
                Sticker {
                    anchors.centerIn: parent
                    source: plug.modelData.icon
                    seed: plug.index
                }
            }
        }
    }
}
