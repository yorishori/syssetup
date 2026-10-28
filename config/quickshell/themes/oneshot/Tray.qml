import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.bar.widgets as W

// Each tray app hangs from the beam as its own charm on twine, at its own
// length like the workspace tags: a little framed tile with the app's icon
// shrunk to 10 x 10 and blown up unsmoothed, so it's pixel art too, and
// tinted a little toward the palette. Hidden when there are none.
Item {
    id: root

    required property W.Tray control

    readonly property bool shown: control.items.length > 0
    readonly property int px: Theme.get("pixel.scale") ?? 3
    readonly property int tile: 9 * px
    readonly property int gap: 2 * px
    // The beam's underside, in here: this item is bar-tall and sits
    // `offset` below the bar's top.
    readonly property int bough: (Theme.get("bar.bough") ?? 18) - (Theme.get("bar.offset") ?? 0)
    readonly property var drops: [1, -1, 2, 0, 3]

    function tileTop(index: int): int {
        return Math.round((height - tile) / 2 / px + drops[index % drops.length]) * px;
    }
    function slotRect(index: int): rect {
        return Qt.rect(index * (tile + gap) + 3, tileTop(index) + 3, tile - 6, tile - 6);
    }

    implicitWidth: Math.max(0, control.items.length * (tile + gap) - gap)
    implicitHeight: Theme.barHeight

    Repeater {
        model: root.control.items

        Item {
            id: charm

            required property int index
            required property var modelData
            readonly property int tileY: root.tileTop(index)

            x: index * (root.tile + root.gap)
            width: root.tile
            height: root.height

            Rectangle {
                x: Math.round(root.tile / 2 / root.px) * root.px - root.px
                y: root.bough
                width: root.px
                height: charm.tileY - root.bough
                color: "#a08c62"
            }
            Frame {
                y: charm.tileY
                width: root.tile
                height: root.tile
                frame: "#7a6c8f"
            }
            Image {
                id: icon

                anchors.horizontalCenter: parent.horizontalCenter
                y: charm.tileY + (root.tile - 20) / 2
                width: 20
                height: 20
                sourceSize: Qt.size(10, 10)
                smooth: false
                source: charm.modelData.icon
                visible: false
            }
            MultiEffect {
                source: icon
                anchors.fill: icon
                colorization: 0.25
                colorizationColor: Theme.palette.dim
                saturation: -0.2
            }
        }
    }
}
