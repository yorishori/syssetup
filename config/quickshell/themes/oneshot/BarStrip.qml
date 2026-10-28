import QtQuick
import qs.core
import qs.modules.bar as B

// The cabin's beam runs along the top (we're inside, looking out at the
// night): a squared log with its grain and pegs where twine is tied. Each
// group of keys is a sign hanging from it on two lengths of twine, framed
// like the panels; widgets that hang themselves (the workspace tags, the
// tray's bottles, the indicator bubbles) get no sign, and the launcher and
// caffeine keys are carved into brackets coming down from the beam itself,
// the two ends of a tunnel (a portal: the cat goes in one and comes out of
// the other, both glowing). Ropes sag from sign to sign and bracket (into
// a bracket low, at its mouth), the cat's paths along the bar: wooden,
// mossy; a rope's end dangles from the longest, for the cat to climb.
// Drops gather on the beam's underside and fall now and then. Everything
// sits on the art-pixel grid.
Item {
    id: root

    required property B.BarStrip control
    readonly property real seam: -6
    readonly property real offset: Theme.get("bar.offset") ?? 0

    readonly property int px: Theme.get("pixel.scale") ?? 3
    readonly property int bough: Theme.get("bar.bough") ?? 18
    // Signs: 13 art pixels tall, their middle where the widgets sit.
    readonly property int signHeight: 13 * px
    readonly property int signTop: snap(height / 2 + offset - signHeight / 2)
    readonly property var hangsItself: ["Workspaces", "Tray", "StatusLamps", "LauncherButton", "CaffeineButton"]
    // Keys carved into the beam rather than hung.
    readonly property var carved: ["LauncherButton", "CaffeineButton"]

    readonly property var c: ({
        wood: "#4a3428",
        woodLight: "#5e4433",
        woodDark: "#3a2820",
        grain: "#33241c",
        under: "#21160f",
        peg: "#6b5038",
        twine: "#a08c62",
        rope: "#6e5034",
        ropeLight: "#8a6844",
        ropeDark: "#4a3428",
        moss: "#4a6038",
        mossLight: "#62784a",
        mossDark: "#33442a",
        knot: "#5f533c",
        drip: "#8fa0dc"
    })

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

    // Where an entry's sign goes: around what's showing in it (a group's
    // children, a slot counting while its widget is visible, but not the
    // ones that hang themselves), or the entry itself.
    function box(entry: var): var {
        const parts = entry.widget !== undefined ? [entry]
            : Array.from(entry.children ?? []).filter(c => c.visible && c.width > 0 && (c.item?.visible ?? true) && !hangsItself.includes(c.widget ?? ""));
        if (!parts.length || !entry.visible || !(entry.item?.visible ?? true))
            return null;
        const start = Math.min(...parts.map(p => p === entry ? 0 : p.x));
        const end = Math.max(...parts.map(p => p === entry ? p.width : p.x + p.width));
        const pad = 5 * px;
        return { x: snap(entry.x + start - pad), w: snap(end - start + 2 * pad) };
    }

    readonly property var signs: entries().filter(i => i && !hangsItself.includes(i.widget ?? "")).map(e => box(e)).filter(b => b && b.w > 0)
    // The carved keys' brackets: around each, from the beam down to the
    // signs' foot.
    readonly property var brackets: {
        const out = [];
        for (const e of entries().filter(i => i && i.visible)) {
            const kids = e.widget !== undefined ? [[e, 0]] : Array.from(e.children ?? []).map(k => [k, e.x]);
            for (const [k, dx] of kids)
                if (carved.includes(k.widget ?? "") && k.visible && k.width > 0)
                    out.push({ x: snap(dx + k.x - 4 * px), w: snap(k.width + 8 * px), carved: true });
        }
        return out;
    }
    // Where a rope's top runs into a sign, and lower, into a bracket (a
    // tunnel's mouth).
    readonly property int ropeHigh: signTop + px
    readonly property int ropeLow: signTop + signHeight - 3 * px
    // Ropes from each sign or bracket to the next; they pass behind what
    // hangs by itself, so the cat can get from one end of the bar to the
    // other. None between two brackets side by side: that's a tunnel, a
    // portal from one to the other (see `portals`).
    readonly property var ropes: {
        const s = signs.concat(brackets).sort((a, b) => a.x - b.x);
        const out = [];
        for (let i = 0; i + 1 < s.length; i++) {
            if (s[i].carved && s[i + 1].carved)
                continue;
            const from = s[i].x + s[i].w - 2 * px, to = s[i + 1].x + 2 * px;
            if (to - from > 4 * px)
                out.push({
                    from: from,
                    to: to,
                    y1: s[i].carved ? ropeLow : ropeHigh,
                    y2: s[i + 1].carved ? ropeLow : ropeHigh,
                    sag: Math.min(8 * px, (to - from) * 0.06)
                });
        }
        return out;
    }
    // The portals: from the left bracket's mouth to the right one's, for
    // each pair of brackets side by side.
    readonly property var portals: {
        const s = brackets.slice().sort((a, b) => a.x - b.x);
        const out = [];
        for (let i = 0; i + 1 < s.length; i++)
            out.push({ a: s[i].x + 2 * px, b: s[i + 1].x + s[i + 1].w - 2 * px });
        return out;
    }
    // A rope's end dangling from the middle of the longest rope: the cat
    // climbs back up it after a fall.
    readonly property var vine: {
        const r = ropes.slice().sort((p, q) => (q.to - q.from) - (p.to - p.from))[0];
        if (!r)
            return null;
        const x = snap((r.from + r.to) / 2);
        return { x: x, top: ropeY(r, x), length: 14 * px };
    }

    function ropeY(r: var, x: real): real {
        const t = (x - r.from) / (r.to - r.from);
        return r.y1 + (r.y2 - r.y1) * t + Math.round(4 * r.sag * t * (1 - t) / px) * px;
    }
    // Where the cat's feet go at x: on a rope, along it; on a sign (or past
    // the ends), the signs' top.
    function groundAt(x: real): real {
        for (const r of ropes)
            if (x >= r.from && x <= r.to)
                return snap(ropeY(r, x));
        for (const p of portals) {
            if (x >= p.a - 2 * px && x <= p.a)
                return ropeLow;
            if (x >= p.b && x <= p.b + 2 * px)
                return ropeLow;
        }
        return signTop;
    }
    // How far along the bar the cat wanders: the first sign's start to the
    // last one's end.
    readonly property var walkable: {
        const all = signs.concat(brackets);
        if (!all.length)
            return [0, 0];
        return [Math.min(...all.map(b => b.x)) + 6 * px, Math.max(...all.map(b => b.x + b.w)) - 6 * px];
    }

    Ticker { id: clock }

    // ── The beam ──────────────────────────────────────────────────────────
    Canvas {
        id: beam

        width: root.width
        height: root.bough + root.px
        antialiasing: false
        renderStrategy: Canvas.Immediate

        onPaint: {
            const ctx = getContext("2d");
            const p = root.px, W = width, c = root.c;
            const rnd = (i, s) => {
                const v = Math.sin(i * 127.1 + s * 311.7) * 43758.5453;
                return v - Math.floor(v);
            };
            ctx.clearRect(0, 0, W, height);
            ctx.fillStyle = c.wood;
            ctx.fillRect(0, 0, W, 5 * p);
            ctx.fillStyle = c.woodLight;
            ctx.fillRect(0, 0, W, p);
            ctx.fillStyle = c.woodDark;
            ctx.fillRect(0, 4 * p, W, p);
            ctx.fillStyle = c.under;
            ctx.fillRect(0, 5 * p, W, p);
            // Grain: long thin streaks, a knot now and then.
            ctx.fillStyle = c.grain;
            for (let i = 0; i < W / (6 * p); i++) {
                const x = Math.round(rnd(i, 1) * W / p) * p;
                const y = (1 + Math.floor(rnd(i, 2) * 3)) * p;
                ctx.fillRect(x, y, (6 + Math.floor(rnd(i, 3) * 18)) * p, p);
            }
            for (let i = 0; i < W / (90 * p); i++) {
                const x = Math.round(rnd(i, 4) * W / p) * p;
                ctx.fillRect(x, 2 * p, 3 * p, 2 * p);
                ctx.fillStyle = c.woodDark;
                ctx.fillRect(x + p, 2 * p, p, p);
                ctx.fillStyle = c.grain;
            }
        }

        Connections {
            target: root

            function onWidthChanged() { beam.requestPaint(); }
        }
    }

    // Drops gathering under the beam and falling: 28 frames each.
    Repeater {
        model: Math.ceil(root.width / 300)

        Rectangle {
            required property int index
            readonly property int t: (clock.frame + index * 9) % 28

            x: root.snap((index * 0.167 + 0.06) * root.width + (index * 37 % 90))
            y: t < 20 ? root.bough : root.bough + [1, 4, 9, 16, 25, 25, 25, 25][t - 20] * root.px
            width: root.px
            height: t < 17 ? root.px : 2 * root.px
            color: root.c.drip
            opacity: t < 4 ? 0 : t < 25 ? 0.9 : 0
        }
    }

    // ── Ropes between signs ───────────────────────────────────────────────
    Repeater {
        model: root.ropes

        Canvas {
            id: rope

            required property var modelData
            readonly property real sag: modelData.sag

            x: modelData.from
            y: Math.min(modelData.y1, modelData.y2) - 3 * root.px
            width: modelData.to - modelData.from
            height: Math.abs(modelData.y2 - modelData.y1) + sag + 10 * root.px
            antialiasing: false
            renderStrategy: Canvas.Immediate

            onPaint: {
                const ctx = getContext("2d"), p = root.px, c = root.c;
                const rnd = (i, k) => {
                    const v = Math.sin((i + modelData.from) * 12.9898 + k * 78.233) * 43758.5453;
                    return v - Math.floor(v);
                };
                const put = (x, y, col) => {
                    ctx.fillStyle = col;
                    ctx.fillRect(x, y, p, p);
                };
                ctx.clearRect(0, 0, width, height);
                for (let x = 0, i = 0; x < width; x += p, i++) {
                    const y = root.snap(root.ropeY(modelData, modelData.from + x)) - rope.y;
                    // Two strands twisted: a light fleck every third pixel.
                    put(x, y, i % 3 === 0 ? c.ropeLight : c.rope);
                    put(x, y + p, i % 3 === 1 ? c.rope : c.ropeDark);
                    // Moss along the top, in clumps, and a strand hanging
                    // off it now and then.
                    const m = rnd(Math.floor(i / 4), 1);
                    if (m < 0.55 && rnd(i, 2) < 0.8) {
                        put(x, y, rnd(i, 3) < 0.5 ? c.moss : c.mossDark);
                        put(x, y - p, rnd(i, 4) < 0.4 ? c.mossLight : c.moss);
                        if (rnd(i, 5) < 0.25)
                            put(x, y - 2 * p, c.moss);
                    }
                    if (m < 0.55 && rnd(i, 6) < 0.12) {
                        const n = 1 + Math.floor(rnd(i, 7) * 4);
                        for (let k = 0; k < n; k++)
                            put(x, y + (2 + k) * p, k === n - 1 ? c.mossLight : c.mossDark);
                    }
                }
            }
            onWidthChanged: requestPaint()
        }
    }

    // ── Brackets: the carved keys' wood, coming down out of the beam ─────
    Repeater {
        model: root.brackets

        Canvas {
            required property var modelData

            x: modelData.x
            y: root.bough - root.px
            width: modelData.w
            // Down past the signs' foot: its carved panel spans what a sign
            // would, so the key sits in its middle.
            height: root.signTop + root.signHeight + 2 * root.px - y
            antialiasing: false
            renderStrategy: Canvas.Immediate

            onPaint: {
                const ctx = getContext("2d"), p = root.px, c = root.c;
                const W = Math.round(width / p), H = Math.round(height / p);
                const rect = (x, y, w, h, col) => {
                    ctx.fillStyle = col;
                    ctx.fillRect(x * p, y * p, w * p, h * p);
                };
                ctx.clearRect(0, 0, width, height);
                // The block, its lower corners cut; it runs up into the beam.
                rect(0, 0, W, H - 2, c.under);
                rect(1, H - 2, W - 2, 1, c.under);
                rect(2, H - 1, W - 4, 1, c.under);
                rect(1, 0, W - 2, H - 3, c.wood);
                rect(2, H - 3, W - 4, 1, c.wood);
                rect(1, 0, 1, H - 3, c.woodLight);
                rect(W - 2, 0, 1, H - 3, c.woodDark);
                rect(2, H - 3, W - 4, 1, c.woodDark);
                // Grain down its sides, and the panel the key's carved into.
                rect(2, 1, 1, 3, c.grain);
                rect(W - 3, 2, 1, 2, c.grain);
                const top = Math.round((root.signTop - y) / p) + 1;
                const bottom = top + root.signHeight / p - 2;
                rect(3, top, W - 6, bottom - top, c.under);
                rect(3, top, W - 6, 1, c.grain);
                // Pegs holding it to the beam.
                rect(2, 1, 1, 1, c.peg);
                rect(W - 3, 1, 1, 1, c.peg);
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            // The portal lighting up as the cat goes through: the carved
            // panel glows, a lit rim round it, a few sparks.
            Item {
                readonly property int panelTop: (Math.round((root.signTop - parent.y) / root.px) + 1) * root.px

                x: 3 * root.px
                y: panelTop
                width: parent.width - 6 * root.px
                height: root.signHeight - 2 * root.px
                opacity: cat.portalGlow
                visible: opacity > 0

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0.71, 0.66, 0.88, 0.28)
                    border.width: root.px
                    border.color: Theme.palette.dim
                }
                Repeater {
                    model: 4

                    Rectangle {
                        required property int index

                        x: ((index * 7 + clock.frame * 3) % 9) * root.px
                        y: (index % 2 ? 2 : -1) * root.px - (clock.frame + index) % 3 * root.px
                        width: root.px
                        height: root.px
                        color: index % 2 ? Theme.palette.accent : "#fff6dc"
                    }
                }
            }
        }
    }

    // ── Signs ─────────────────────────────────────────────────────────────
    Repeater {
        model: root.signs

        Item {
            id: sign

            required property var modelData

            x: modelData.x
            y: root.signTop
            width: modelData.w
            height: root.signHeight

            // Twine, from a peg on the beam to the sign's top corners.
            Repeater {
                model: [2, sign.width / root.px - 3]

                Item {
                    required property real modelData

                    x: Math.round(modelData) * root.px
                    y: root.bough - sign.y

                    Rectangle {
                        x: -root.px
                        y: -2 * root.px
                        width: 3 * root.px
                        height: 2 * root.px
                        color: root.c.peg
                    }
                    Rectangle {
                        width: root.px
                        height: sign.y - root.bough
                        color: root.c.twine
                    }
                    Rectangle {
                        y: sign.y - root.bough - root.px
                        width: root.px
                        height: root.px
                        color: root.c.knot
                    }
                }
            }

            Frame {
                anchors.fill: parent
            }
        }
    }

    // ── The rope's end the cat climbs back up after a fall ────────────────
    Item {
        visible: root.vine !== null
        x: root.vine?.x ?? 0
        y: root.vine?.top ?? 0

        Repeater {
            model: root.vine ? Math.round(root.vine.length / root.px) : 0

            Rectangle {
                required property int index

                // Swaying a pixel side to side lower down.
                x: (index > 8 && Math.floor(clock.frame / 4) % 2 ? root.px : 0)
                y: index * root.px
                width: root.px
                height: root.px
                color: index % 3 === 0 ? root.c.ropeLight : root.c.rope
            }
        }
        Rectangle {
            x: -root.px
            y: (root.vine?.length ?? 0) - root.px
            width: 3 * root.px
            height: 2 * root.px
            color: root.c.ropeDark
        }
        Rectangle {
            y: 3 * root.px
            width: root.px
            height: 2 * root.px
            color: root.c.moss
        }
    }

    // ── The cat, living on the bar (see BarCat) ───────────────────────────
    BarCat {
        id: cat

        anchors.fill: parent
        portals: root.portals
        vine: root.vine
        onRope: x => root.ropes.some(r => x >= r.from && x <= r.to)
        px: root.px
        groundAt: x => root.groundAt(x)
        minX: root.walkable[0]
        maxX: root.walkable[1]
        drop: root.control.openDropItem
        hidden: CatState.peeking
    }
}
