import QtQuick
import qs.core
import qs.modules.bar as B

// No strip: the wallpaper's bough runs along the top, and each group of
// keys is a sign hanging from it on two lengths of twine, cream-framed plum
// like the panels. Widgets that hang themselves (the workspace tags) get no
// sign. Everything sits on the art-pixel grid so it matches the wallpaper.
Item {
    id: root

    required property B.BarStrip control
    readonly property real seam: -6
    readonly property real offset: Theme.get("bar.offset") ?? 0

    readonly property int px: Theme.get("pixel.scale") ?? 3
    readonly property int bough: Theme.get("bar.bough") ?? 18
    // Signs: 11 art pixels tall, their middle where the widgets sit.
    readonly property int signHeight: 11 * px
    readonly property int signTop: snap(height / 2 + offset - signHeight / 2)
    readonly property var hangsItself: ["Workspaces"]

    // The islands' entries in one list (they may arrive nested or not).
    function entries(): var {
        const out = [];
        for (const group of Array.from(control.islands ?? [])) {
            if (group && group.length !== undefined && !(group instanceof Item))
                out.push(...Array.from(group));
            else
                out.push(group);
        }
        return out;
    }

    function snap(v: real): int {
        return Math.round(v / px) * px;
    }

    // Every entry of every island is its own sign.
    readonly property var signs: entries().filter(i => i && !hangsItself.includes(i.widget ?? ""))

    Repeater {
        model: root.signs

        Item {
            id: sign

            required property var modelData
            required property int index
            // What's showing in it: a group's children (a slot counts when
            // its widget is visible), or the entry itself.
            readonly property var parts: modelData.widget !== undefined ? [modelData]
                : Array.from(modelData.children ?? []).filter(c => c.visible && c.width > 0 && (c.item?.visible ?? true))
            readonly property real start: parts.length ? Math.min(...parts.map(p => p === modelData ? 0 : p.x)) : 0
            readonly property real end: parts.length ? Math.max(...parts.map(p => p === modelData ? p.width : p.x + p.width)) : 0
            readonly property bool shown: modelData.visible && (modelData.item?.visible ?? true) && end > start
            readonly property int pad: 3 * root.px

            x: root.snap(modelData.x + start - pad)
            y: root.signTop
            width: root.snap(end - start + 2 * pad)
            height: root.signHeight
            visible: shown

            // Twine, from the bough's underside to the sign's top corners.
            Repeater {
                model: [2, sign.width / root.px - 3]

                Rectangle {
                    required property real modelData

                    x: Math.round(modelData) * root.px
                    y: root.bough - sign.y
                    width: root.px
                    height: sign.y - root.bough
                    color: "#a08c62"

                    Rectangle {
                        y: parent.height - root.px
                        width: root.px
                        height: root.px
                        color: "#5f533c"
                    }
                }
            }

            Frame {
                anchors.fill: parent
            }

            // The cat naps on the last sign, its tail dangling off the end.
            Cat {
                visible: sign.index === root.signs.length - 1
                pose: "nap"
                flip: true
                x: -4 * root.px
                y: -7 * root.px
            }
        }
    }
}
