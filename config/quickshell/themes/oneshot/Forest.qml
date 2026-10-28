import QtQuick
import qs.core

// The forest on a misty night, in pixel art (the wallpaper, and behind the
// lock screen), as seen from inside a cabin (the beam across the top is
// the bar's). Back to front: a sky heavy with cloud, the moon barely
// peeking through a gap in it, its light bleeding through round it; two
// dark mountain ranges, their ridges catching a little of it; three rows
// of pines, each nearer one darker, mist between them; the clearing,
// grassy, with stepping stones and a stone lantern, its light a dithered
// glow with a pool on the ground; the big pines framing the edges, ferns
// and bushes in front. Fog drifts through it in bands of its own, each at
// its own height, thickness and pace, thickening and thinning. Live on
// top: the flame, and fireflies lighting up, wandering, dimming and going
// out, to light up again somewhere else.
//
// Drawn in art pixels (the screen divided by pixel.scale) and blown up
// without smoothing, so every pixel stays square. What never moves is
// painted once on canvases; the loops are live pixels on Tickers (the
// scene's slow ones; the fireflies' quicker, in a layer of their own).
// Places are fractions of the screen, so any size works; the "random"
// bits are fixed per index.
Item {
    id: root

    // Holds every loop still (the fog, the flame, the fireflies):
    // set while something covers the whole screen, so nothing's drawn for
    // nobody.
    property bool paused: false

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
        moon: "#e8dcc0",
        moonShade: "#cbbf9f",
        halo: "#e8dcc0",
        cloud: "#24253f",
        cloud2: "#1f2038",
        cloudDark: "#1a1b31",
        cloudLit: "#3a3a5c",
        ridge: "#161629",
        ridgeLit: "#262644",
        ridgeNear: "#131225",
        ridgeNearLit: "#1f1e3a",
        far3: "#171629",
        far3Rim: "#1c1b33",
        far2: "#151427",
        far2Rim: "#1a1930",
        far: "#131224",
        farAlt: "#121122",
        farRim: "#19182f",
        farDark: "#0f0e1d",
        farTrunk: "#100f1e",
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
        fernDark: "#0b1413",
        fern: "#0f1d1b",
        fernMid: "#152824",
        fernLight: "#1f3a33",
        wet: "#4b7a6c",
        firefly: "#e6f59a",
        fireflyGlow: "#b7d96a"
    })

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

    // A band of fog: [top, height, opacity, drift (art px per slow step,
    // signed), wave lengths a and b, how patchy (-1 solid to 1 sparse),
    // seed]. It drifts at its own pace (some left, some right), thickening
    // and thinning.
    component FogBand: Item {
        id: band

        required property var modelData
        readonly property real drift: modelData[3]
        readonly property int offset: Math.floor(slow.frame * Math.abs(drift)) % root.aw

        y: modelData[0]
        width: root.aw
        height: modelData[1]
        // Breathing: thicker, thinner, slowly, out of step.
        opacity: modelData[2] * (0.8 + 0.2 * Math.sin(slow.frame / 23 + modelData[7] * 1.7))

        Repeater {
            model: 2

            Canvas {
                required property int index

                x: band.drift > 0 ? index * root.aw - band.offset : (index - 1) * root.aw + band.offset
                width: root.aw
                height: band.height
                antialiasing: false
                smooth: false
                renderStrategy: Canvas.Immediate

                onPaint: {
                    const ctx = getContext("2d"), m = band.modelData;
                    ctx.clearRect(0, 0, width, height);
                    ctx.fillStyle = root.c.mist;
                    // Wraps round, so the two canvases join.
                    const k = 2 * Math.PI / width;
                    for (let y = 0; y < height; y++) {
                        const t = y / height;
                        const share = t < 0.2 || t > 0.85 ? 0.125 : t < 0.4 || t > 0.7 ? 0.25 : 0.5;
                        root.dither(ctx, 0, y, width, 1, share, x =>
                            Math.sin(x * k * Math.round(width / m[4]) + y / 7 + m[7]) * 0.6
                            + Math.sin(x * k * Math.round(width / (m[4] * 2.7)) - y / m[5] + m[7] * 2) * 0.4 > m[6]);
                    }
                }
                onWidthChanged: requestPaint()
            }
        }
    }

    // The scene's idle loops step slowly; the fireflies at 12 a second.
    Ticker {
        id: slow

        running: !root.paused && (Theme.get("pixel.animate") ?? true)
    }
    Ticker {
        id: flyClock

        fps: 12
        running: !root.paused && (Theme.get("pixel.animate") ?? true)
    }

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
        // One texture for the whole forest, redrawn only when its slow loops
        // step: far cheaper to put on screen than its canvases one by one.
        layer.enabled: true
        layer.smooth: false

        // ── Back: sky, moon, far trees ────────────────────────────────────
        Canvas {
            id: back

            anchors.fill: parent
            antialiasing: false
            smooth: false
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

                // A cloud bank: puffs along a line, flat underneath, its top
                // edge lit where the moon's near.
                const moonX = Math.round(W * 0.667) + 15, moonY = Math.round(H * 0.13) + 15;
                const bank = (x0, y0, w, h, fill, seed) => {
                    const puffs = Math.max(3, Math.round(w / (h * 0.9)));
                    // Each row's spans, puff by puff (no pixel tests).
                    const by = Math.floor(y0 - h), bh = Math.ceil(2 * h) + 2;
                    const spans = [];
                    for (let j = 0; j < bh; j++)
                        spans.push([]);
                    for (let i = 0; i < puffs; i++) {
                        const t = (i + 0.5) / puffs;
                        const r = h * (0.45 + root.rnd(seed * 7 + i, 60) * 0.55) * (1 - Math.abs(t - 0.5) * 0.8);
                        const sx = x0 + t * w, sy = y0 + h - r * 0.8;
                        for (let y = Math.ceil(sy - r / 1.5); y <= Math.floor(Math.min(sy + r / 1.5, y0 + h)); y++) {
                            const half = Math.sqrt(Math.max(0, r * r - Math.pow((y - sy) * 1.5, 2)));
                            const from = Math.ceil(sx - half), to = Math.ceil(sx + half);
                            if (to > from && y >= by && y < by + bh)
                                spans[y - by].push([from, to]);
                        }
                    }
                    // Merged, so each row is a few runs.
                    for (let j = 0; j < bh; j++) {
                        const row = spans[j].sort((p, q) => p[0] - q[0]);
                        const out = [];
                        for (const [f, t] of row) {
                            if (out.length && f <= out[out.length - 1][1])
                                out[out.length - 1][1] = Math.max(out[out.length - 1][1], t);
                            else
                                out.push([f, t]);
                        }
                        spans[j] = out;
                    }
                    ctx.fillStyle = fill;
                    for (let j = 0; j < bh; j++)
                        for (const [f, t] of spans[j])
                            ctx.fillRect(f, by + j, t - f, 1);
                    // Near the moon, its upper edge lit: the pixels of a row
                    // that the rows above don't cover.
                    const bx = x0 - h, bw = w + 2 * h;
                    if (Math.hypot(Math.max(bx - moonX, 0, moonX - bx - bw), Math.max(by - moonY, 0, moonY - by - bh)) >= 120)
                        return;
                    // A coverage grid round the moon only (where any edge can
                    // be lit), then the edge pixels in it.
                    const gx = Math.round(moonX - 120), gw = 240;
                    const grid = new Uint8Array(gw * bh);
                    for (let j = 0; j < bh; j++)
                        for (const [f, t] of spans[j])
                            for (let x = Math.max(f, gx); x < Math.min(t, gx + gw); x++)
                                grid[j * gw + x - gx] = 1;
                    for (let j = 0; j < bh; j++) {
                        const dy = by + j - moonY;
                        if (Math.abs(dy) >= 120)
                            continue;
                        for (let i = 0; i < gw; i++) {
                            if (grid[j * gw + i] === 0 || (j >= 2 && grid[(j - 1) * gw + i] === 1 && grid[(j - 2) * gw + i] === 1))
                                continue;
                            const near = Math.hypot(gx + i - moonX, dy);
                            if (near < 120) {
                                ctx.fillStyle = near < 70 ? c.cloudLit : c.cloud;
                                ctx.fillRect(gx + i, by + j, 1, 1);
                            }
                        }
                    }
                };

                // The moon, mostly hidden: the cloud goes over it, but for a
                // gap its top right peeks through.
                const r = 15, mx = Math.round(W * 0.667), my = Math.round(H * 0.13);
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

                // The overcast: banks across the whole sky, darker and
                // heavier lower down; one across the moon's lower part and
                // one over its top left, leaving it a gap.
                const rows = Math.ceil(H * 0.5 / 14);
                for (let k = 0; k < rows; k++) {
                    const y = 4 + k * 14 + Math.round(root.rnd(k, 61) * 6);
                    const fill = k < rows * 0.35 ? c.cloud2 : c.cloudDark;
                    for (let x = -40 + Math.round(root.rnd(k, 62) * 60); x < W; x += 90 + Math.round(root.rnd(k * 3 + x, 63) * 70)) {
                        // Keep the gap the moon peeks through clear.
                        if (Math.abs(x + 60 - moonX) < 70 && Math.abs(y + 8 - moonY) < 22)
                            continue;
                        bank(x, y, 110 + Math.round(root.rnd(k * 5 + x, 64) * 90), 9 + Math.round(root.rnd(k * 7 + x, 65) * 6), fill, k * 31 + x);
                    }
                }
                // Over the moon itself: everything but a sliver at its top
                // right, the cloud's edge lit where it crosses.
                for (let y = moonY - r - 1; y <= moonY + r + 1; y++) {
                    for (let x = moonX - r - 1; x <= moonX + r + 1; x++) {
                        const dx = x - moonX, dy = y - moonY;
                        if (Math.hypot(dx, dy) > r + 1)
                            continue;
                        const peek = dx - dy * 1.3 - 9 - Math.round(Math.sin(dy / 2) * 1.5);
                        if (peek > 0)
                            continue;
                        ctx.fillStyle = peek > -2 ? c.cloudLit : c.cloud2;
                        ctx.fillRect(x, y, 1, 1);
                    }
                }
                bank(mx - 50, my + 18, 110, 12, c.cloud2, 701);
                bank(mx + 22, my + 24, 70, 10, c.cloudDark, 703);

                // Its light bleeding through the cloud round it.
                ctx.fillStyle = Qt.rgba(0.91, 0.86, 0.75, 0.07);
                root.dither(ctx, moonX - 44, moonY - 44, 88, 88, 0.25, (x, y) => {
                    const d = Math.hypot(x - moonX, y - moonY);
                    return d > r + 1 && d < 40;
                });
                ctx.fillStyle = Qt.rgba(0.91, 0.86, 0.75, 0.05);
                root.dither(ctx, moonX - 60, moonY - 60, 120, 120, 0.125, (x, y) => {
                    const d = Math.hypot(x - moonX, y - moonY);
                    return d >= 40 && d < 58;
                });

                // Two mountain ranges, dark: a far one and a nearer one,
                // the slopes facing the moon catching an edge of light.
                const range = (base, height, freq, seed, fill, lit) => {
                    const ridge = x => base - height * (0.55
                        + 0.25 * Math.sin(x / (freq * 1.0) + seed)
                        + 0.15 * Math.sin(x / (freq * 0.37) + seed * 2)
                        + 0.06 * Math.sin(x / (freq * 0.13) + seed * 3));
                    for (let x = 0; x < W; x++) {
                        const top = Math.round(ridge(x));
                        ctx.fillStyle = fill;
                        ctx.fillRect(x, top, 1, root.horizon - top);
                        // Lit where it falls away toward the moon's side.
                        if (ridge(x + 1) > ridge(x - 1)) {
                            ctx.fillStyle = lit;
                            ctx.fillRect(x, top, 1, 1);
                            if (ridge(x + 2) - ridge(x - 2) > 2)
                                ctx.fillRect(x, top + 1, 1, 1);
                        }
                    }
                };
                range(root.horizon - 40, 90, 70, 1.3, c.ridge, c.ridgeLit);
                range(root.horizon - 22, 60, 45, 4.1, c.ridgeNear, c.ridgeNearLit);
                // Mist lying at their feet.
                ctx.fillStyle = Qt.rgba(0.23, 0.24, 0.4, 0.35);
                root.dither(ctx, 0, root.horizon - 40, W, 8, 0.125, null);
                root.dither(ctx, 0, root.horizon - 32, W, 6, 0.25, x => Math.sin(x / 19) > -0.4);

                // Three rows of pines, each nearer one bigger and darker,
                // mist between them.
                const row = (spacing, minW, extraW, minH, extraH, bottom, jitter, fill, rim, salt) => {
                    const n = Math.ceil(W / spacing) + 2;
                    for (let i = 0; i < n; i++) {
                        const w = minW + Math.round(root.rnd(i, salt) * extraW);
                        const h = minH + Math.round(root.rnd(i, salt + 1) * extraH);
                        const x = -10 + i * spacing + Math.round(root.rnd(i, salt + 2) * spacing * 0.5);
                        root.pine(ctx, x, bottom - Math.round(root.rnd(i, salt + 3) * jitter), w, h, fill, rim, c.farDark, c.farTrunk);
                    }
                };
                row(9, 12, 8, 26, 16, root.horizon - 16, 6, c.far3, c.far3Rim, 70);
                ctx.fillStyle = Qt.rgba(0.23, 0.24, 0.4, 0.4);
                root.dither(ctx, 0, root.horizon - 24, W, 10, 0.125, x => Math.sin(x / 27) > -0.5);
                row(15, 20, 12, 44, 24, root.horizon - 6, 6, c.far2, c.far2Rim, 74);
                ctx.fillStyle = Qt.rgba(0.23, 0.24, 0.4, 0.35);
                root.dither(ctx, 0, root.horizon - 14, W, 8, 0.125, x => Math.sin(x / 33 + 2) > -0.4);
                row(24, 30, 20, 67, 40, root.horizon, 10, c.far, c.farRim, 3);
            }
        }

        // ── Fog among the far rows, each band its own ─────────────────────
        Repeater {
            model: [
                [root.horizon - 72, 16, 0.32, 0.20, 41, 13, 0.1, 1],
                [root.horizon - 26, 26, 0.5, 0.33, 23, 7, -0.6, 2],
                [root.horizon - 6, 14, 0.42, -0.25, 37, 11, 0, 3]
            ]

            FogBand {}
        }

        // ── Middle: the clearing, the lantern ─────────────────────────────
        Canvas {
            id: middle

            anchors.fill: parent
            antialiasing: false
            smooth: false
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
            smooth: false
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

        // ── Fog over the clearing, in front of the lantern ─────────────────
        Repeater {
            model: [[root.lanternBase - 12, 20, 0.45, -0.25, 31, 5, -0.4, 4]]

            FogBand {}
        }

        // ── Front: big pines, bushes, ferns ───────────────────────────────
        Canvas {
            id: front

            anchors.fill: parent
            antialiasing: false
            smooth: false
            renderStrategy: Canvas.Immediate

            onPaint: {
                const ctx = getContext("2d");
                const W = root.aw, H = root.ah, c = root.c;
                ctx.clearRect(0, 0, W, H);
                // Grass over the clearing, taller toward the front; none on
                // the stones or at the lantern's foot. Drawn first, so the
                // big pines stand in front of it.
                const onStone = (x, y) => [[0.458, 0.844, 21, 4], [0.424, 0.9, 24, 5], [0.389, 0.962, 28, 5]]
                    .some(([sx, sy, sw, sh]) => x >= W * sx - 2 && x < W * sx + sw + 1 && y >= H * sy && y < H * sy + sh + 3);
                for (let i = 0; i < W * 3.4; i++) {
                    const x = Math.round(root.rnd(i, 50) * W), y = root.horizon + 3 + Math.round(root.rnd(i, 51) * (H - root.horizon - 3));
                    if ((Math.abs(x - root.lanternX - 15) < 18 && Math.abs(y - root.lanternBase) < 5) || onStone(x, y))
                        continue;
                    const depth = (y - root.horizon) / (H - root.horizon);
                    const tall = 1 + Math.round(depth * 3 + root.rnd(i, 52) * 1.5);
                    ctx.fillStyle = i % 4 ? c.fern : c.fernMid;
                    ctx.fillRect(x, y - tall, 1, tall);
                    ctx.fillRect(x + 2, y - tall - 1, 1, tall + 1);
                    if (i % 3 === 0)
                        ctx.fillRect(x + 1, y - Math.max(1, tall - 1), 1, Math.max(1, tall - 1));
                    if (depth > 0.5 && i % 5 === 0) {
                        ctx.fillStyle = c.fernLight;
                        ctx.fillRect(x + 2, y - tall - 1, 1, 1);
                    }
                }

                root.pine(ctx, -30, H, 93, H + 12, c.near, c.nearRim, c.nearDark, c.nearTrunk);
                root.pine(ctx, 50, H, 63, Math.round(H * 0.58), c.nearAlt, c.nearRim, c.nearDark, c.nearTrunk);
                root.pine(ctx, W - 87, H, 77, Math.round(H * 0.69), c.nearAlt, c.nearRim, c.nearDark, c.nearTrunk);
                root.pine(ctx, W - 47, H, 93, H + 12, c.near, c.nearRim, c.nearDark, c.nearTrunk);

                // Bushes along the bottom, leaving the path clear; ferns
                // among them.
                const bushes = [[0.04, 1.0, 70, 40], [0.15, 1.02, 54, 30], [0.27, 1.03, 40, 22],
                                [0.74, 1.03, 44, 24], [0.86, 1.01, 60, 34], [0.97, 1.0, 72, 42]];
                bushes.forEach(([bx, by, bw, bh], i) => root.bush(ctx, Math.round(W * bx), Math.round(H * by), bw, bh, i + 1));
                const ferns = [[0.11, 0.985, 16], [0.31, 0.99, 12], [0.69, 0.99, 13], [0.9, 0.98, 17], [0.35, 0.86, 8], [0.66, 0.84, 9]];
                ferns.forEach(([fx, fy, fs], i) => root.fern(ctx, Math.round(W * fx), Math.round(H * fy), fs, i + 7));
            }
        }

        // ── Fog low over the grass, in front of it all ────────────────────
        Repeater {
            model: [
                [Math.round(root.ah * 0.85), 14, 0.45, 0.2, 19, 9, 0.25, 5],
                [Math.round(root.ah * 0.93), 12, 0.4, -0.4, 27, 6, 0.4, 6]
            ]

            FogBand {}
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

    // ── Fireflies, in their own layer (they move often; the forest needn't
    // redraw for them) ────────────────────────────────────────────────────
    // Each lives a cycle of its own length: lights up, wanders a meandering
    // path, its light pulsing, dims down and goes out; a while later it
    // lights up again somewhere else.
    Item {
        width: root.aw
        height: root.ah
        scale: root.px
        transformOrigin: Item.TopLeft

        Repeater {
            model: 14

            Item {
                id: fly

                required property int index
                readonly property real time: flyClock.frame / 12 + root.rnd(index, 80) * 40
                readonly property real cycle: 9 + root.rnd(index, 81) * 7
                readonly property int round: Math.floor(time / cycle)
                readonly property real t: time / cycle - round
                // In, lit, down, then out for the rest of the cycle.
                readonly property real life: t < 0.12 ? t / 0.12 : t < 0.62 ? 1 : t < 0.78 ? 1 - (t - 0.62) / 0.16 : 0
                readonly property real pulse: 0.55 + 0.45 * Math.sin(time * (2.2 + root.rnd(index, 82)) + index)
                readonly property real bright: life * pulse
                readonly property real baseX: root.aw * (0.12 + root.rnd(index * 31 + round, 83) * 0.76)
                readonly property real baseY: root.ah * (0.56 + root.rnd(index * 17 + round, 84) * 0.34)
                readonly property real s: t * cycle

                visible: life > 0
                x: Math.round(baseX + 10 * Math.sin(s * 0.7 + index) + 5 * Math.sin(s * 1.9 + index * 2))
                y: Math.round(baseY + 5 * Math.sin(s * 0.9 + index * 3) - s * 0.9)

                // A soft glow round it while it's bright.
                Rectangle { x: -1; width: 3; height: 1; color: root.c.fireflyGlow; opacity: 0.35 * fly.bright }
                Rectangle { y: -1; width: 1; height: 3; color: root.c.fireflyGlow; opacity: 0.35 * fly.bright }
                Rectangle {
                    width: 1
                    height: 1
                    color: root.c.firefly
                    opacity: 0.25 + 0.75 * fly.bright
                }
            }
        }
    }
}
