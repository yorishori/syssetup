import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.bar.widgets as W

// Each tray app is a potion bottle hanging from the beam on its own length
// of twine: corked, a little glass bottle filled with a potion of its own
// colour (picked from the app's id, so it keeps it), the app's icon on it
// like a label (shrunk to 10 x 10 and blown up unsmoothed, so it's pixel
// art too). Now and then a bubble rises in it. The one whose menu is open
// is lifted a little and its glass lit. Hidden when there are none.
Item {
    id: root

    required property W.Tray control

    readonly property bool shown: control.items.length > 0
    readonly property int px: Theme.get("pixel.scale") ?? 3
    // The bottle is 11 x 15 art pixels.
    readonly property int bottleWidth: 11 * px
    readonly property int bottleHeight: 15 * px
    readonly property int gap: 2 * px
    // The beam's underside, in here: this item is bar-tall and sits
    // `offset` below the bar's top.
    readonly property int bough: (Theme.get("bar.bough") ?? 18) - (Theme.get("bar.offset") ?? 0)
    readonly property var drops: [1, 3, 2, 0, 2]
    readonly property var potions: ["#7fc8a9", "#e8a0b4", "#8fa0dc", "#f2c46d", "#b58fdc", "#ef8f6f"]

    function bottleTop(index: int): int {
        return bough + (2 + drops[index % drops.length]) * px;
    }
    // Where the click goes: the bottle's body.
    function slotRect(index: int): rect {
        return Qt.rect(index * (bottleWidth + gap), bottleTop(index) + 4 * px, bottleWidth, 10 * px);
    }
    function potion(item: var): color {
        const id = `${item?.id ?? ""}`;
        let h = 0;
        for (let i = 0; i < id.length; i++)
            h = (h * 31 + id.charCodeAt(i)) >>> 0;
        return potions[h % potions.length];
    }
    function rgba(c: color, a: real): string {
        return `rgba(${Math.round(c.r * 255)},${Math.round(c.g * 255)},${Math.round(c.b * 255)},${a})`;
    }

    implicitWidth: Math.max(0, control.items.length * (bottleWidth + gap) - gap)
    implicitHeight: Theme.barHeight

    Ticker { id: clock }

    Repeater {
        model: root.control.items

        Item {
            id: bottle

            required property int index
            required property var modelData
            readonly property bool pulled: root.control.pulled === modelData
            readonly property int bottleY: root.bottleTop(index) - (pulled ? 2 * root.px : 0)
            readonly property color tint: root.potion(modelData)

            x: index * (root.bottleWidth + root.gap)
            width: root.bottleWidth
            height: root.height

            // The twine, from the beam to the cork.
            Rectangle {
                x: 5 * root.px
                y: root.bough
                width: root.px
                height: bottle.bottleY - root.bough
                color: "#a08c62"
            }
            PixelArt {
                y: bottle.bottleY
                px: root.px
                colors: ({
                    "c": "#8a6844",
                    "C": "#5e4433",
                    "g": bottle.pulled ? Theme.palette.accent : root.rgba(Theme.palette.dim, 0.85),
                    "G": root.rgba(Theme.palette.dim, 0.18),
                    "L": root.rgba(bottle.tint, 0.55),
                    "l": root.rgba(bottle.tint, 0.8),
                    "w": "#fff6dc"
                })
                rows: [
                    "....ccc....",
                    "....CCC....",
                    "....gGg....",
                    "....gGg....",
                    "..ggGGGgg..",
                    ".gGwGGGGGg.",
                    "gGwGGGGGGGg",
                    "gllllllllLg",
                    "gLLLLLLLLLg",
                    "gLLLLLLLLLg",
                    "gLLLLLLLLLg",
                    "gLLLLLLLLLg",
                    ".gLLLLLLLg.",
                    "..ggggggg..",
                    "..........."
                ]
            }
            // A bubble rising in the potion now and then.
            Rectangle {
                readonly property int t: (clock.frame + bottle.index * 5) % 14

                visible: t < 4
                x: (3 + (bottle.index * 3) % 5) * root.px
                y: bottle.bottleY + (11 - t) * root.px
                width: root.px
                height: root.px
                color: Qt.lighter(bottle.tint, 1.4)
                opacity: 0.8
            }
            Image {
                id: icon

                x: (root.bottleWidth - 20) / 2
                y: bottle.bottleY + 6 * root.px + 1
                width: 20
                height: 20
                sourceSize: Qt.size(10, 10)
                smooth: false
                source: bottle.modelData.icon
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
