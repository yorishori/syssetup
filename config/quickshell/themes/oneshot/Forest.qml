import QtQuick
import qs.core

// The forest on a rainy night, in pixel art (the wallpaper, and behind the
// lock screen), as seen from inside a cabin (the beam across the top is
// the bar's). Back to front: banded sky, the moon in a dithered halo
// behind cloud, the far treeline; a band of mist; the clearing with
// puddles, stepping stones and a stone lantern, its light a dithered glow
// with a pool on the ground; mist again, lower; the big pines framing the
// edges, ferns and bushes in front, wet with highlights. Live on top:
// stars, the flame, glowing mushrooms, fireflies. The rain is its own
// layer: streaks in two depths, splashes on the ground and on the
// lantern's roof, rings spreading in the puddles.
//
// Drawn in art pixels (the screen divided by pixel.scale) and blown up
// without smoothing, so every pixel stays square. What never moves is
// painted once on canvases; the loops are live pixels on Tickers (the
// scene's slow ones, the rain's at 30 a second). Places are fractions of
// the screen, so any size works; the "random" bits are fixed per index.
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
        groundLit: "#1a1729",
        path: "#221f33",
        pathWet: "#2e2b45",
        puddle: "#1b1e3b",
        puddleRim: "#2a2f58",
        moon: "#e8dcc0",
        moonShade: "#cbbf9f",
        halo: "#e8dcc0",
        cloud: "#262848",
        cloud2: "#22243f",
        star: "#ece3d2",
        starAlt: "#b5a8e0",
        far: "#1d1b34",
        farAlt: "#1a182f",
        farRim: "#22203f",
        farDark: "#171529",
        farTrunk: "#141224",
        near: "#0f0d18",
        nearAlt: "#110f1c",
        nearRim: "#18152a",
        nearDark: "#0b0a13",
        nearTrunk: "#0b0a12",
        mist: "#3a3c66",
        stone: "#3a3552",
        stoneLight: "#4a4466",
        stoneShade: "#2c2840",
        stoneDark: "#211e33",
        moss: "#2c4236",
        mossLight: "#3f5e4a",
        flame: "#f2c46d",
        glow: "#f2c46d",
        stem: "#cfc6b4",
        fernDark: "#0b1413",
        fern: "#0f1d1b",
        fernMid: "#152824",
        fernLight: "#1f3a33",
        wet: "#4b7a6c",
        rainFar: "#56618f",
        rainNear: "#9aa8d8",
        splash: "#b5bfe6"
    })

    readonly property var mushrooms: [
        { x: 0.431, y: 0.778, cap: "#8fd6b4" }, { x: 0.447, y: 0.791, cap: "#b5a8e0" },
        { x: 0.564, y: 0.771, cap: "#8fd6b4" }, { x: 0.292, y: 0.844, cap: "#b5a8e0" },
        { x: 0.694, y: 0.822, cap: "#8fd6b4" }, { x: 0.711, y: 0.836, cap: "#e8a0b4" }
    ]
    // Puddles: centre (fractions), half-width and half-height (art pixels).
    readonly property var puddles: [
        { x: 0.385, y: 0.93, rx: 15, ry: 3 },
        { x: 0.575, y: 0.885, rx: 10, ry: 2 },
        { x: 0.635, y: 0.955, rx: 13, ry: 3 },
        { x: 0.21, y: 0.9, rx: 9, ry: 2 }
    ]

    // A fixed pseudo-random number in [0, 1) for (index, salt).
    function rnd(i: int, salt: int): real {
        const v = Math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
        return v - Math.floor(v);
    }

    // A dither: of the pixels in the rectangle, a share (1, 1/2, 1/4, 1/8)
    // in an ordered pattern, where keep(x, y) agrees.
    function dither(ctx: var, x0: int, y0: int, w: int, h: int, share: real, keep: var): void {
        for (let y = y0; y < y0 + h; y++) {
            for (let x = x0; x < x0 + w; x++) {
                const on = share >= 1 ? true
                    : share >= 0.5 ? (x + y) % 2 === 0
                    : share >= 0.25 ? x % 2 === 0 && y % 2 === 0
                    : x % 4 === 0 && y % 2 === 0 && (x / 4 + y / 2) % 2 === 0;
                if (on && (!keep || keep(x, y)))
                    ctx.fillRect(x, y, 1, 1);
            }
        }
    }

    // A pine standing at (x, bottom): a trunk, then five tiers, each a
    // stepped triangle; the moonlit (right) edge a pixel lighter, the
    // underside of each tier dithered darker.
    function pine(ctx: var, x: int, bottom: int, w: int, h: int, fill: string, rim: string, dark: string, trunk: string): void {
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
                if (r >= tierH - 3) {
                    ctx.fillStyle = dark;
                    for (let k = rx + 1 + (ry % 2); k < rx + rw - 2; k += 2)
                        ctx.fillRect(k, ry, 1, 1);
                }
                ctx.fillStyle = rim;
                ctx.fillRect(rx + rw - 1, ry, 1, 1);
                if (r % 3 === 1)
                    ctx.fillRect(rx + rw - 2, ry, 1, 1);
            }
        }
    }

    // A bush: overlapping blobs, lit from the upper right, wet glints.
    function bush(ctx: var, cx: int, base: int, w: int, h: int, seed: int): void {
        const blobs = 5 + Math.round(rnd(seed, 30) * 4);
        for (let pass = 0; pass < 2; pass++) {
            for (let b = 0; b < blobs; b++) {
                const bx = cx - w / 2 + rnd(seed * 13 + b, 31) * w;
                const by = base - rnd(seed * 17 + b, 32) * h * 0.6;
                const r = 3 + rnd(seed * 19 + b, 33) * h * 0.45;
                for (let y = Math.floor(by - r); y < by + r; y++) {
                    for (let x = Math.floor(bx - r); x < bx + r; x++) {
                        const d = Math.hypot(x - bx, y - by);
                        if (d >= r || y >= base)
                            continue;
                        if (pass === 0) {
                            ctx.fillStyle = c.fernDark;
                        } else {
                            const lit = (x - bx) * 0.6 - (y - by);
                            ctx.fillStyle = d > r - 1.2 && lit > r * 0.3 ? c.fernLight
                                : lit > r * 0.2 ? c.fernMid : c.fern;
                            if (lit < -r * 0.3 && (x + y) % 2)
                                ctx.fillStyle = c.fernDark;
                        }
                        ctx.fillRect(x, y, 1, 1);
                    }
                }
            }
        }
        ctx.fillStyle = c.wet;
        for (let g = 0; g < w / 4; g++)
            ctx.fillRect(Math.round(cx - w / 2 + rnd(seed * 23 + g, 34) * w), Math.round(base - rnd(seed * 29 + g, 35) * h * 0.9), 1, 1);
    }

    // A fern: fronds arching out from its base, leaflets along them.
    function fern(ctx: var, cx: int, base: int, size: int, seed: int): void {
        const fronds = 5;
        for (let f = 0; f < fronds; f++) {
            const dir = (f - (fronds - 1) / 2) / ((fronds - 1) / 2);
            const len = size * (0.7 + rnd(seed * 7 + f, 36) * 0.4);
            for (let t = 0; t < len; t++) {
                const s = t / len;
                const x = Math.round(cx + dir * s * size * 0.9);
                const y = Math.round(base - len * Math.sin(s * Math.PI * 0.55) * (1 - Math.abs(dir) * 0.45));
                ctx.fillStyle = s > 0.75 ? c.fernLight : c.fernMid;
                ctx.fillRect(x, y, 1, 1);
                if (t % 2 === 0 && s < 0.9) {
                    ctx.fillStyle = c.fern;
                    ctx.fillRect(x - 1, y + 1, 1, 1);
                    ctx.fillRect(x + 1, y + 1, 1, 1);
                }
            }
        }
    }

    // A pixel ellipse's rows: [dy, half-width] for half-axes (rx, ry).
    function ellipse(rx: int, ry: int): var {
        const rows = [];
        for (let dy = -ry; dy <= ry; dy++)
            rows.push([dy, Math.round(rx * Math.sqrt(Math.max(0, 1 - (dy * dy) / ((ry + 0.5) * (ry + 0.5)))))]);
        return rows;
    }

    // The scene's idle loops step slowly; the rain falls at 30 a second.
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

        // ── Back: sky, moon, far trees ────────────────────────────────────
        Canvas {
            id: back

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
                // Band edges, dithered so they don't step hard.
                ctx.fillStyle = c.sky2;
                root.dither(ctx, 0, Math.round(H * 0.333) - 2, W, 2, 0.5, null);
                ctx.fillStyle = c.sky3;
                root.dither(ctx, 0, Math.round(H * 0.511) - 2, W, 2, 0.5, null);

                // The moon in its halo: two dithered rings, then the disc,
                // shaded where it turns away, then cloud across it.
                const r = 15, mx = Math.round(W * 0.667), my = Math.round(H * 0.13);
                const cx = mx + r, cy = my + r;
                ctx.fillStyle = Qt.rgba(0.91, 0.86, 0.75, 0.16);
                root.dither(ctx, cx - 30, cy - 30, 60, 60, 0.5, (x, y) => Math.hypot(x - cx, y - cy) < r + 7);
                ctx.fillStyle = Qt.rgba(0.91, 0.86, 0.75, 0.1);
                root.dither(ctx, cx - 30, cy - 30, 60, 60, 0.25, (x, y) => {
                    const d = Math.hypot(x - cx, y - cy);
                    return d >= r + 7 && d < r + 14;
                });
                for (let y = 0; y < 2 * r; y++) {
                    const d = y - r + 0.5;
                    const half = Math.round(Math.sqrt(Math.max(0, r * r - d * d)));
                    ctx.fillStyle = c.moonShade;
                    ctx.fillRect(mx + r - half, my + y, 2 * half, 1);
                    const d2 = y + 2 - r + 0.5;
                    if (Math.abs(d2) < r) {
                        const h2 = Math.round(Math.sqrt(r * r - d2 * d2));
                        const la = Math.max(r - half, r - h2 - 2), lb = Math.min(r + half, r + h2 - 2);
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
                ctx.fillRect(mx + 30, my + 8, 28, 2);

                // The far treeline on the horizon.
                const n = Math.ceil(W / 30) + 2;
                for (let i = 0; i < n; i++) {
                    const w = 30 + Math.round(root.rnd(i, 3) * 20);
                    const h = 67 + Math.round(root.rnd(i, 4) * 40);
                    const x = -10 + i * 30 + Math.round(root.rnd(i, 5) * 8);
                    const bottom = root.horizon - Math.round(root.rnd(i, 6) * 10);
                    root.pine(ctx, x, bottom, w, h, i % 2 ? c.far : c.farAlt, c.farRim, c.farDark, c.farTrunk);
                }
            }
        }

        // Stars.
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

        // ── Mist among the far trunks, drifting ───────────────────────────
        Repeater {
            model: 2

            Canvas {
                required property int index
                readonly property int band: 26

                x: index * root.aw - Math.floor(slow.frame / 3) % root.aw
                y: root.horizon - band + 4
                width: root.aw
                height: band
                antialiasing: false
                renderStrategy: Canvas.Immediate
                opacity: 0.5

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.fillStyle = root.c.mist;
                    for (let y = 0; y < height; y++) {
                        const t = y / height;
                        const share = t < 0.2 || t > 0.85 ? 0.125 : t < 0.4 || t > 0.7 ? 0.25 : 0.5;
                        root.dither(ctx, 0, y, width, 1, share, x => Math.sin(x / 23 + y / 7) > -0.6);
                    }
                }
            }
        }

        // ── Middle: the clearing, the lantern ─────────────────────────────
        Canvas {
            id: middle

            anchors.fill: parent
            antialiasing: false
            renderStrategy: Canvas.Immediate

            onPaint: {
                const ctx = getContext("2d");
                const W = root.aw, H = root.ah, c = root.c;
                ctx.clearRect(0, 0, W, H);
                ctx.fillStyle = c.ground;
                ctx.fillRect(0, root.horizon, W, H);
                ctx.fillRect(Math.round(W * 0.29), root.horizon - 4, Math.round(W * 0.42), 5);
                // The ground's texture: a few darker and lighter flecks.
                for (let i = 0; i < W * 1.5; i++) {
                    ctx.fillStyle = i % 3 ? c.nearDark : c.groundLit;
                    ctx.fillRect(Math.round(root.rnd(i, 40) * W), root.horizon + 2 + Math.round(root.rnd(i, 41) * (H - root.horizon)), 1 + (i % 2), 1);
                }

                // Puddles: dark water, a lighter rim, the lantern in them.
                for (const p of root.puddles) {
                    const px0 = Math.round(W * p.x), py0 = Math.round(H * p.y);
                    for (const [dy, half] of root.ellipse(p.rx, p.ry)) {
                        ctx.fillStyle = c.puddleRim;
                        ctx.fillRect(px0 - half, py0 + dy, 2 * half + 1, 1);
                        ctx.fillStyle = c.puddle;
                        if (half > 1)
                            ctx.fillRect(px0 - half + 1, py0 + dy, 2 * half - 1, 1);
                    }
                    const lx = root.lanternX + 15;
                    if (Math.abs(px0 - lx) < p.rx + 6) {
                        ctx.fillStyle = Qt.rgba(0.95, 0.77, 0.43, 0.45);
                        for (let dy = -p.ry + 1; dy < p.ry; dy++)
                            if (dy % 2 === 0)
                                ctx.fillRect(lx - 1 + (dy % 4 ? 1 : 0), py0 + dy, 2, 1);
                    }
                }

                // Stepping stones, wet on top.
                const stones = [[0.458, 0.844, 21, 4], [0.424, 0.9, 24, 5], [0.389, 0.962, 28, 5]];
                for (const [sx, sy, sw, sh] of stones) {
                    const x = Math.round(W * sx), y = Math.round(H * sy);
                    ctx.fillStyle = c.path;
                    ctx.fillRect(x + 1, y, sw - 2, sh);
                    ctx.fillRect(x, y + 1, sw, sh - 2);
                    ctx.fillStyle = c.pathWet;
                    ctx.fillRect(x + 2, y, sw - 6, 1);
                    ctx.fillStyle = c.stoneDark;
                    ctx.fillRect(x + 1, y + sh - 1, sw - 2, 1);
                }

                // The lantern's shadow pooled at its foot.
                const lx = root.lanternX, lb = root.lanternBase;
                ctx.fillStyle = c.nearDark;
                for (const [dy, half] of root.ellipse(16, 2))
                    root.dither(ctx, lx + 15 - half, lb + dy, 2 * half, 1, Math.abs(dy) < 1 ? 0.5 : 0.25, null);

                // The stone lantern: lit faces, shaded left sides, texture,
                // moss on the roofs.
                const stone = (x, y, w, h, col) => {
                    ctx.fillStyle = col;
                    ctx.fillRect(lx + x, lb + y, w, h);
                };
                stone(0, -5, 30, 5, c.stone);           // foot
                stone(0, -5, 4, 5, c.stoneShade);
                stone(0, -1, 30, 1, c.stoneDark);
                stone(11, -26, 8, 21, c.stone);         // post
                stone(11, -26, 3, 21, c.stoneShade);
                stone(18, -26, 1, 21, c.stoneLight);
                stone(3, -30, 24, 4, c.stone);          // shelf
                stone(3, -30, 4, 4, c.stoneShade);
                stone(3, -27, 24, 1, c.stoneDark);
                stone(5, -45, 20, 15, c.stoneShade);    // firebox
                stone(5, -45, 3, 15, c.stoneDark);
                stone(24, -45, 1, 15, c.stoneLight);
                stone(1, -50, 28, 5, c.stone);          // roof
                stone(1, -50, 5, 5, c.stoneShade);
                stone(1, -46, 28, 1, c.stoneDark);
                stone(1, -50, 28, 1, c.stoneLight);
                stone(7, -54, 16, 4, c.stone);          // cap
                stone(7, -54, 3, 4, c.stoneShade);
                stone(13, -58, 4, 4, c.stone);          // finial
                stone(13, -58, 1, 4, c.stoneShade);
                ctx.fillStyle = c.stoneDark;
                for (let i = 0; i < 26; i++)
                    ctx.fillRect(lx + 1 + Math.round(root.rnd(i, 42) * 27), lb - 50 + Math.round(root.rnd(i, 43) * 49), 1, 1);
                for (const [x, y, w] of [[2, -50, 6], [12, -50, 3], [20, -50, 5], [8, -54, 4], [17, -54, 3], [0, -5, 3], [25, -5, 4]]) {
                    ctx.fillStyle = c.moss;
                    ctx.fillRect(lx + x, lb + y, w, 1);
                    ctx.fillStyle = c.mossLight;
                    ctx.fillRect(lx + x + 1, lb + y, Math.max(1, w - 3), 1);
                }
                ctx.fillStyle = c.moss;
                ctx.fillRect(lx + 2, lb - 49, 1, 2);
                ctx.fillRect(lx + 27, lb - 49, 1, 3);

                // Mushroom stems (their caps glow, on top).
                ctx.fillStyle = c.stem;
                for (const m of root.mushrooms)
                    ctx.fillRect(Math.round(W * m.x) + 2, Math.round(H * m.y) + 3, 2, 3);
            }
        }

        // The lantern's light: a dithered glow round the window and a pool
        // on the ground, breathing with the flame.
        Canvas {
            id: glow

            readonly property int cx: root.lanternX + 15
            readonly property int cy: root.lanternBase - 38

            anchors.fill: parent
            antialiasing: false
            renderStrategy: Canvas.Immediate
            opacity: [1, 1, 0.85, 1, 1, 1, 0.92, 1, 0.88, 1, 1][slow.frame % 11]

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = Qt.rgba(0.95, 0.77, 0.43, 0.2);
                const R = 44;
                root.dither(ctx, cx - R, cy - R, 2 * R, 2 * R, 0.5, (x, y) => Math.hypot(x - cx, (y - cy) * 1.15) < 12);
                root.dither(ctx, cx - R, cy - R, 2 * R, 2 * R, 0.25, (x, y) => {
                    const d = Math.hypot(x - cx, (y - cy) * 1.15);
                    return d >= 12 && d < 24;
                });
                root.dither(ctx, cx - R, cy - R, 2 * R, 2 * R, 0.125, (x, y) => {
                    const d = Math.hypot(x - cx, (y - cy) * 1.15);
                    return d >= 24 && d < R;
                });
                // The pool of light on the ground.
                const gy = root.lanternBase + 2;
                ctx.fillStyle = Qt.rgba(0.95, 0.77, 0.43, 0.22);
                for (const [dy, half] of root.ellipse(46, 6))
                    root.dither(ctx, cx - half, gy + dy, 2 * half, 1, Math.abs(dy) < 3 ? 0.5 : 0.25, null);
            }
        }
        Rectangle {
            x: root.lanternX + 11
            y: root.lanternBase - 42
            width: 8
            height: 8
            color: root.c.flame
            opacity: [1, 1, 0.8, 1, 1, 1, 0.9, 1, 0.85, 1, 1][slow.frame % 11]

            Rectangle {
                x: 3
                y: 2
                width: 2
                height: 4
                color: "#fff1c9"
            }
        }

        // ── Mist again, lower, over the clearing ──────────────────────────
        Repeater {
            model: 2

            Canvas {
                required property int index
                readonly property int band: 18

                x: index * root.aw - (root.aw - Math.floor(slow.frame / 4) % root.aw)
                y: root.lanternBase - 10
                width: root.aw
                height: band
                antialiasing: false
                renderStrategy: Canvas.Immediate
                opacity: 0.35

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.fillStyle = root.c.mist;
                    for (let y = 0; y < height; y++) {
                        const t = y / height;
                        const share = t < 0.25 || t > 0.8 ? 0.125 : 0.25;
                        root.dither(ctx, 0, y, width, 1, share, x => Math.sin(x / 31 - y / 5) > -0.3);
                    }
                }
            }
        }

        // ── Front: big pines, bushes, ferns ───────────────────────────────
        Canvas {
            id: front

            anchors.fill: parent
            antialiasing: false
            renderStrategy: Canvas.Immediate

            onPaint: {
                const ctx = getContext("2d");
                const W = root.aw, H = root.ah, c = root.c;
                ctx.clearRect(0, 0, W, H);
                root.pine(ctx, -30, H, 93, H + 12, c.near, c.nearRim, c.nearDark, c.nearTrunk);
                root.pine(ctx, 50, H, 63, Math.round(H * 0.58), c.nearAlt, c.nearRim, c.nearDark, c.nearTrunk);
                root.pine(ctx, W - 87, H, 77, Math.round(H * 0.69), c.nearAlt, c.nearRim, c.nearDark, c.nearTrunk);
                root.pine(ctx, W - 47, H, 93, H + 12, c.near, c.nearRim, c.nearDark, c.nearTrunk);

                // Grass tufts across the clearing.
                for (let i = 0; i < W / 3; i++) {
                    const x = Math.round(root.rnd(i, 50) * W), y = root.horizon + 6 + Math.round(root.rnd(i, 51) * (H - root.horizon - 6));
                    if (Math.abs(x - root.lanternX - 15) < 18 && y > root.lanternBase - 4)
                        continue;
                    ctx.fillStyle = i % 4 ? c.fern : c.fernMid;
                    ctx.fillRect(x, y - 2, 1, 2);
                    ctx.fillRect(x + 2, y - 3, 1, 3);
                    if (i % 3 === 0)
                        ctx.fillRect(x + 1, y - 1, 1, 1);
                }

                // Bushes along the bottom, leaving the path clear; ferns
                // among them.
                const bushes = [[0.04, 1.0, 70, 40], [0.15, 1.02, 54, 30], [0.27, 1.03, 40, 22],
                                [0.74, 1.03, 44, 24], [0.86, 1.01, 60, 34], [0.97, 1.0, 72, 42]];
                bushes.forEach(([bx, by, bw, bh], i) => root.bush(ctx, Math.round(W * bx), Math.round(H * by), bw, bh, i + 1));
                const ferns = [[0.11, 0.985, 16], [0.31, 0.99, 12], [0.69, 0.99, 13], [0.9, 0.98, 17], [0.35, 0.86, 8], [0.66, 0.84, 9]];
                ferns.forEach(([fx, fy, fs], i) => root.fern(ctx, Math.round(W * fx), Math.round(H * fy), fs, i + 7));
            }
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

        Connections {
            target: root

            function onAwChanged() {
                back.requestPaint();
                middle.requestPaint();
                glow.requestPaint();
                front.requestPaint();
            }
            function onAhChanged() { onAwChanged(); }
        }
    }

    // ── The rain, in its own layer (falling doesn't redraw the forest) ────
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
                readonly property int span: root.ah + height
                readonly property real speed: (near ? 7 : 4) + root.rnd(index, 21) * 2

                x: Math.round(root.rnd(index, 9) * root.aw)
                y: -height + Math.floor((root.rnd(index, 10) * span + rainClock.frame * speed) % span)
                width: 1
                height: near ? 7 + Math.round(root.rnd(index, 22) * 5) : 3 + Math.round(root.rnd(index, 23) * 3)
                color: near ? root.c.rainNear : root.c.rainFar
                opacity: near ? 0.5 : 0.35
            }
        }

        // A drop's crown, two frames: on the ground here and there, and
        // often on the lantern's roof and cap.
        component Splash: Item {
            property int t: 0

            visible: t < 4

            Rectangle { x: 1; width: 1; height: 1; color: root.c.splash; visible: parent.t < 2 }
            Rectangle { x: 0; y: -1; width: 1; height: 1; color: root.c.splash; opacity: 0.7; visible: parent.t >= 2 }
            Rectangle { x: 2; y: -1; width: 1; height: 1; color: root.c.splash; opacity: 0.7; visible: parent.t >= 2 }
        }
        Repeater {
            model: Math.ceil(root.aw / 40)

            Splash {
                required property int index
                readonly property int round: Math.floor((rainClock.frame + index * 7) / 24)

                t: (rainClock.frame + index * 7) % 24
                x: Math.round(root.rnd(index * 31 + round, 24) * (root.aw - 4))
                y: root.horizon + 4 + Math.round(root.rnd(index * 17 + round, 25) * (root.ah - root.horizon - 8))
            }
        }
        Repeater {
            model: 6

            Splash {
                required property int index
                readonly property int round: Math.floor((rainClock.frame + index * 5) / 12)
                readonly property bool onCap: index % 3 === 0

                t: (rainClock.frame + index * 5) % 12
                x: root.lanternX + (onCap ? 7 + Math.round(root.rnd(index + round, 26) * 13) : 1 + Math.round(root.rnd(index + round, 27) * 25))
                y: root.lanternBase + (onCap ? -55 : -51)
            }
        }

        // Rings spreading in the puddles: a dot, then wider rings, fading.
        Repeater {
            model: root.puddles.length * 2

            Item {
                required property int index
                readonly property var p: root.puddles[index % root.puddles.length]
                readonly property int t: (rainClock.frame + index * 11) % 30
                readonly property int round: Math.floor((rainClock.frame + index * 11) / 30)
                readonly property int r: t < 3 ? 0 : t < 7 ? 1 : t < 12 ? 2 : 3

                x: Math.round(root.aw * p.x + (root.rnd(index + round, 28) - 0.5) * p.rx * 1.2)
                y: Math.round(root.ah * p.y + (root.rnd(index + round, 29) - 0.5) * p.ry)
                visible: t < 16
                opacity: t < 12 ? 0.7 : 0.35

                Rectangle { visible: parent.r === 0; width: 1; height: 1; color: root.c.splash }
                Rectangle { visible: parent.r > 0; x: -parent.r * 2; width: 1; height: 1; color: root.c.splash }
                Rectangle { visible: parent.r > 0; x: parent.r * 2; width: 1; height: 1; color: root.c.splash }
                Rectangle { visible: parent.r > 0; x: -parent.r * 2 + 1; y: -1; width: parent.r * 4 - 1; height: 1; color: root.c.splash }
                Rectangle { visible: parent.r > 1; x: -parent.r * 2 + 1; y: 1; width: parent.r * 4 - 1; height: 1; color: root.c.splash; opacity: 0.6 }
            }
        }
    }
}
