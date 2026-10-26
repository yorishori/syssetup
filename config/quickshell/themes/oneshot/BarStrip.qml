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

    Repeater {
        // Every entry of every island is its own sign.
        model: root.entries().filter(i => i && !root.hangsItself.includes(i.widget ?? ""))

        Item {
            id: sign

            required property var modelData
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

            // Dark outline, cream frame, plum face; corners cut a pixel.
            Rectangle {
                x: root.px
                width: parent.width - 2 * root.px
                height: parent.height
                color: Theme.palette.shadow
            }
            Rectangle {
                y: root.px
                width: parent.width
                height: parent.height - 2 * root.px
                color: Theme.palette.shadow
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: root.px
                color: Theme.palette.border

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: root.px
                    color: Theme.palette.bg
                }
            }
        }
    }
}
