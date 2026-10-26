import QtQuick
import qs.core

// The forest on a rainy night, in pixel art (the wallpaper, and behind the
// lock screen): banded sky with a moon behind cloud, a far treeline, a
// stone lantern on a path with glowing mushrooms, fireflies, big pines
// framing the edges, and rain. Across the top runs the mossy bough the
// bar's applets hang from; it drips now and then.
//
// Drawn in art pixels (the screen divided by pixel.scale) and blown up
// without smoothing, so every pixel stays square. What never moves is
// painted once on canvases; only the loops are live pixels, stepped by
// Tickers. Places are fractions of the screen, so any size works; the
// "random" bits are fixed per index.
Item {
    id: root

    readonly property int px: Math.max(1, Theme.get("pixel.scale") ?? 3)
    readonly property int aw: Math.ceil(width / px)
    readonly property int ah: Math.ceil(height / px)
    readonly property int horizon: Math.round(ah * 0.667)
    readonly property int lanternX: Math.round(aw * 0.5) - 15
    readonly property int lanternBase: Math.round(ah * 0.804)

    readonly property var c: ({
        sky: "#14152a",
        sky2: "#181a33",
        sky3: "#1c1d3a",
        ground: "#141224",
        path: "#221f33",
        moon: "#e8dcc0",
        moonShade: "#cbbf9f",
        cloud: "#262848",
        cloud2: "#22243f",
        star: "#ece3d2",
        starAlt: "#b5a8e0",
        far: "#1d1b34",
        farAlt: "#1a182f",
        farRim: "#201e3c",
        farTrunk: "#141224",
        near: "#0f0d18",
        nearAlt: "#110f1c",
        nearRim: "#141120",
        nearTrunk: "#0b0a12",
        stone: "#3a3552",
        stoneShade: "#2c2840",
        flame: "#f2c46d",
        stem: "#cfc6b4",
        rainFar: "#56618f",
        rainNear: "#9aa8d8",
        splash: "#b5bfe6",
        drip: "#8fa0dc",
        bark: "#3a2a24",
        barkDark: "#2c1f1a",
        barkUnder: "#241915",
        moss: "#2c4236",
        mossLight: "#4f7a5a"
    })

    // A fixed pseudo-random number in [0, 1) for (index, salt).
    function rnd(i: int, salt: int): real {
        const v = Math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
        return v - Math.floor(v);
    }

    // A pine standing at (x, bottom): a trunk, then five tiers, each a
    // stepped triangle, the moonlit (right) edge a pixel lighter.
    function pine(ctx: var, x: int, bottom: int, w: int, h: int, fill: string, rim: string, trunk: string): void {
        const trunkH = Math.max(1, Math.round(h * 0.12));
        const tw = Math.max(1, Math.round(w * 0.14));
        ctx.fillStyle = trunk;
        ctx.fillRect(x + Math.round((w - tw) / 2), bottom - trunkH, tw, trunkH);
        const step = (h - trunkH) / 5.5;
        const tierH = Math.max(2, Math.round(step * 1.6));
        for (let i = 4; i >= 0; i--) {
            const tierW = w * (1 - i * 0.17);
            const tierBottom = Math.round(bottom - trunkH - i * step);
            for (let r = 0; r < tierH; r++) {
                // Two pixels wider every row down, from the top of the tier.
                const rw = Math.max(1, Math.min(Math.round(tierW), 1 + 2 * Math.round((r + 1) * tierW / (2 * tierH))));
                const rx = x + Math.round((w - rw) / 2);
                const ry = tierBottom - tierH + r;
                ctx.fillStyle = fill;
                ctx.fillRect(rx, ry, rw, 1);
                ctx.fillStyle = rim;
                ctx.fillRect(rx + rw - 1, ry, 1, 1);
            }
        }
    }

    // A pixel disc's rows: [y, from, to) spans, for a radius r at (cx, cy).
    function disc(r: int): var {
        const rows = [];
        for (let y = 0; y < 2 * r; y++) {
            const d = y - r + 0.5;
            const half = Math.round(Math.sqrt(Math.max(0, r * r - d * d)));
            rows.push([y, r - half, r + half]);
        }
        return rows;
    }

    // Idle loops (stars, lantern, mushrooms, fireflies, drips) step slowly;
    // the rain falls smoothly, at 30 frames a second.
    Ticker { id: slow }
    Ticker { id: rainClock; fps: 30 }

    Rectangle {
        anchors.fill: parent
        color: root.c.sky
    }

    Item {
        id: art

        width: root.aw
        height: root.ah
        scale: root.px
        transformOrigin: Item.TopLeft
        layer.enabled: true
        layer.smooth: false

        // Everything that stands still, behind the loops.
        Canvas {
            id: scene

            anchors.fill: parent
            antialiasing: false
            renderStrategy: Canvas.Immediate

            onPaint: {
                const ctx = getContext("2d");
                const W = root.aw, H = root.ah, c = root.c;
                ctx.fillStyle = c.sky;
                ctx.fillRect(0, 0, W, H);
                ctx.fillStyle = c.sky2;
                ctx.fillRect(0, Math.round(H * 0.333), W, H);
                ctx.fillStyle = c.sky3;
                ctx.fillRect(0, Math.round(H * 0.511), W, H);

                // The moon: a disc, shaded where it turns away, behind cloud.
                const mx = Math.round(W * 0.667), my = Math.round(H * 0.13), r = 15;
                for (const [y, a, b] of root.disc(r)) {
                    ctx.fillStyle = c.moonShade;
                    ctx.fillRect(mx + a, my + y, b - a, 1);
                    // The lit part: the same disc shifted up and left, inside this one.
                    const d = y + 2 - r + 0.5;
                    if (Math.abs(d) < r) {
                        const half = Math.round(Math.sqrt(r * r - d * d));
                        const la = Math.max(a, r - half - 2), lb = Math.min(b, r + half - 2);
                        ctx.fillStyle = c.moon;
                        if (lb > la)
                            ctx.fillRect(mx + la, my + y, lb - la, 1);
                    }
                }
                ctx.fillStyle = c.cloud;
                ctx.fillRect(mx - 20, my + 17, 67, 4);
                ctx.fillRect(mx - 14, my + 16, 30, 1);
                ctx.fillStyle = c.cloud2;
                ctx.fillRect(mx - 7, my + 22, 47, 3);

                // The far treeline on the horizon.
                const n = Math.ceil(W / 30) + 2;
                for (let i = 0; i < n; i++) {
                    const w = 30 + Math.round(root.rnd(i, 3) * 20);
                    const h = 67 + Math.round(root.rnd(i, 4) * 40);
                    const x = -10 + i * 30 + Math.round(root.rnd(i, 5) * 8);
                    const bottom = root.horizon - Math.round(root.rnd(i, 6) * 10);
                    root.pine(ctx, x, bottom, w, h, i % 2 ? c.far : c.farAlt, c.farRim, c.farTrunk);
                }

                // Ground, a low mound behind the lantern, stepping stones.
                ctx.fillStyle = c.ground;
                ctx.fillRect(0, root.horizon, W, H);
                ctx.fillRect(Math.round(W * 0.29), root.horizon - 4, Math.round(W * 0.42), 5);
                ctx.fillStyle = c.path;
                ctx.fillRect(Math.round(W * 0.458), Math.round(H * 0.844), 21, 4);
                ctx.fillRect(Math.round(W * 0.424), Math.round(H * 0.9), 24, 5);
                ctx.fillRect(Math.round(W * 0.389), Math.round(H * 0.962), 28, 5);

                // The stone lantern (its light is a loop, on top).
                const lx = root.lanternX, lb = root.lanternBase;
                const stone = (x, y, w, h, col) => {
                    ctx.fillStyle = col;
                    ctx.fillRect(lx + x, lb + y, w, h);
                };
                stone(0, -5, 30, 5, c.stone);
                stone(0, -1, 30, 1, c.stoneShade);
                stone(11, -26, 8, 21, c.stoneShade);
                stone(11, -26, 2, 21, c.stone);
                stone(3, -30, 24, 4, c.stone);
                stone(5, -45, 20, 15, c.stoneShade);
                stone(1, -50, 28, 5, c.stone);
                stone(1, -46, 28, 1, c.stoneShade);
                stone(7, -54, 16, 4, c.stone);
                stone(13, -58, 4, 4, c.stone);

                // Mushroom stems (their caps glow, on top).
                ctx.fillStyle = c.stem;
                for (const m of root.mushrooms)
                    ctx.fillRect(Math.round(W * m.x) + 2, Math.round(H * m.y) + 3, 2, 3);

                // The big pines framing the edges; the outer two reach the bough.
                root.pine(ctx, -30, H, 93, H + 12, c.near, c.nearRim, c.nearTrunk);
                root.pine(ctx, 50, H, 63, Math.round(H * 0.58), c.nearAlt, c.nearRim, c.nearTrunk);
                root.pine(ctx, W - 87, H, 77, Math.round(H * 0.69), c.nearAlt, c.nearRim, c.nearTrunk);
                root.pine(ctx, W - 47, H, 93, H + 12, c.near, c.nearRim, c.nearTrunk);
            }

            Connections {
                target: root

                function onAwChanged() { scene.requestPaint(); }
                function onAhChanged() { scene.requestPaint(); }
            }
        }

        // Stars, each dimming for two frames out of twenty at its own time.
        Repeater {
            model: 14

            Rectangle {
                required property int index

                x: Math.round(root.rnd(index, 1) * root.aw)
                y: Math.round(root.rnd(index, 2) * root.ah * 0.3) + 8
                width: 1
                height: 1
                color: index % 3 ? root.c.star : root.c.starAlt
                opacity: (slow.frame + index * 7) % 20 < 2 ? 0.3 : 0.9
            }
        }

        // The lantern's light: a soft stepped halo and the flickering window.
        Repeater {
            model: [[-13, -50, 56, 38], [-6, -57, 42, 52], [1, -62, 28, 60]]

            Rectangle {
                required property var modelData
                required property int index

                x: root.lanternX + modelData[0]
                y: root.lanternBase + modelData[1]
                width: modelData[2]
                height: modelData[3]
                color: root.c.flame
                opacity: (slow.frame + index * 3) % 10 < 5 ? 0.035 : 0.025
            }
        }
        Rectangle {
            x: root.lanternX + 11
            y: root.lanternBase - 42
            width: 8
            height: 8
            color: root.c.flame
            opacity: [1, 1, 0.8, 1, 1, 1, 0.9, 1, 0.85, 1, 1][slow.frame % 11]
        }

        // Mushroom caps, glowing on and off out of step.
        Repeater {
            model: root.mushrooms

            Rectangle {
                required property var modelData
                required property int index

                x: Math.round(root.aw * modelData.x)
                y: Math.round(root.ah * modelData.y)
                width: 5
                height: 3
                color: modelData.cap
                opacity: (slow.frame + index * 5) % 16 < 8 ? 1 : 0.65
            }
        }

        // Fireflies drifting up and back, fading at the far end.
        Repeater {
            model: 12

            Rectangle {
                required property int index
                readonly property int t: (slow.frame + index * 3) % 18
                readonly property int leg: t < 9 ? t : 18 - t

                x: Math.round(root.aw * 0.26 + root.rnd(index, 7) * root.aw * 0.49) + Math.floor(leg * 0.7)
                y: Math.round(root.ah * 0.52 + root.rnd(index, 8) * root.ah * 0.29) - leg
                width: 1
                height: 1
                color: root.c.flame
                opacity: 0.9 - leg * 0.07
            }
        }

        // The bough across the top: bark, its knots, its dark underside,
        // moss on it and hanging off it.
        Canvas {
            id: bough

            width: root.aw
            height: 12
            antialiasing: false
            renderStrategy: Canvas.Immediate

            onPaint: {
                const ctx = getContext("2d");
                const W = root.aw, c = root.c;
                ctx.clearRect(0, 0, W, height);
                ctx.fillStyle = c.bark;
                ctx.fillRect(0, 0, W, 5);
                ctx.fillStyle = c.barkUnder;
                ctx.fillRect(0, 5, W, 1);
                ctx.fillStyle = c.moss;
                ctx.fillRect(0, 0, W, 1);
                ctx.fillStyle = c.barkDark;
                for (let i = 0; i < Math.ceil(W / 18); i++)
                    ctx.fillRect(Math.round(root.rnd(i, 11) * W), 1 + Math.round(root.rnd(i, 12) * 2), 4 + Math.round(root.rnd(i, 13) * 8), 1);
                ctx.fillStyle = c.mossLight;
                for (let i = 0; i < Math.ceil(W / 26); i++)
                    ctx.fillRect(Math.round(root.rnd(i, 14) * W), 0, 2, 1);
                ctx.fillStyle = c.moss;
                for (let i = 0; i < Math.ceil(W / 10); i++)
                    ctx.fillRect(Math.round(root.rnd(i, 15) * W), 6, i % 3 ? 1 : 2, 1 + Math.round(root.rnd(i, 16) * 5));
            }

            Connections {
                target: root

                function onAwChanged() { bough.requestPaint(); }
            }
        }

        // Drops gathering under the bough and falling: 28 frames each,
        // gathering for 20, falling for 5, then gone.
        Repeater {
            model: Math.ceil(root.aw / 100)

            Rectangle {
                required property int index
                readonly property int t: (slow.frame + index * 9) % 28

                x: Math.round(root.aw * (0.06 + index * 0.167) + root.rnd(index, 17) * 30)
                y: t < 20 ? 6 : [7, 10, 15, 22, 31, 31, 31, 31][t - 20]
                width: 1
                height: t < 17 ? 1 : 2
                color: root.c.drip
                opacity: t < 4 ? 0 : t < 25 ? 0.9 : 0
            }
        }
    }

    // The rain, in its own layer over the scene (so falling doesn't redraw
    // the forest): long thin streaks, the far ones dimmer, shorter and
    // slower, the near ones brighter, longer and faster; it starts under
    // the bough. Splashes pop on the ground where it lands.
    Item {
        width: root.aw
        height: root.ah
        scale: root.px
        transformOrigin: Item.TopLeft
        layer.enabled: true
        layer.smooth: false

        Repeater {
            model: Math.ceil(root.aw * root.ah / 650)

            Rectangle {
                required property int index
                readonly property bool near: index % 5 < 2
                readonly property int start: 6
                readonly property int span: root.ah - start + height
                readonly property real speed: (near ? 7 : 4) + root.rnd(index, 21) * 2

                x: Math.round(root.rnd(index, 9) * root.aw)
                y: start - height + Math.floor((root.rnd(index, 10) * span + rainClock.frame * speed) % span)
                width: 1
                height: near ? 7 + Math.round(root.rnd(index, 22) * 5) : 3 + Math.round(root.rnd(index, 23) * 3)
                color: near ? root.c.rainNear : root.c.rainFar
                opacity: near ? 0.5 : 0.35
            }
        }

        // Splashes: a drop's crown, two frames, here and there on the ground.
        Repeater {
            model: Math.ceil(root.aw / 40)

            Item {
                required property int index
                readonly property int t: (rainClock.frame + index * 7) % 24
                readonly property int round: Math.floor((rainClock.frame + index * 7) / 24)

                x: Math.round(root.rnd(index * 31 + round, 24) * (root.aw - 4))
                y: root.horizon + 4 + Math.round(root.rnd(index * 17 + round, 25) * (root.ah - root.horizon - 8))
                visible: t < 4

                Rectangle { x: 1; width: 1; height: 1; color: root.c.splash; visible: parent.t < 2 }
                Rectangle { x: 0; y: -1; width: 1; height: 1; color: root.c.splash; opacity: 0.7; visible: parent.t >= 2 }
                Rectangle { x: 2; y: -1; width: 1; height: 1; color: root.c.splash; opacity: 0.7; visible: parent.t >= 2 }
            }
        }
    }

    readonly property var mushrooms: [
        { x: 0.431, y: 0.778, cap: "#8fd6b4" }, { x: 0.447, y: 0.791, cap: "#b5a8e0" },
        { x: 0.564, y: 0.771, cap: "#8fd6b4" }, { x: 0.292, y: 0.844, cap: "#b5a8e0" },
        { x: 0.694, y: 0.822, cap: "#8fd6b4" }, { x: 0.711, y: 0.836, cap: "#e8a0b4" }
    ]
}
