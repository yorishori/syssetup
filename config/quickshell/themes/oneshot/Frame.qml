import QtQuick
import qs.core

// The RPG window: a dark outline with its corners cut, a band, a plum face.
// Everything framed in the theme (panels, signs, the lock) is one of these,
// on the art-pixel grid. `kind` dresses it for what it holds, out of the
// cabin and the forest: the same outline, face and size inside, but its
// band's material and what's fixed to it differ, and some of that sticks
// out past its edges (`reach` art pixels at most, so keep that clear).
// A dressed frame's band is chunky, lit from the top left, and grows
// outward (`grow` art pixels) so the window inside keeps its size.
//
//   ""             cream band (signs, prompts, menus)
//   network        a radio set: steel, rivets, corner plates
//   bluetooth      a rune stone: bevelled, speckled, a keystone with ᛒ
//   audio          a speaker cabinet: wood, brass corners, little feet
//   calendar       a wall calendar: rings, hung on a nail, a dog-ear
//   notifications  an envelope: airmail stripes, a stamp
//   control        the cat's: ears, whiskers, a tail
//   session        a hearth: stone blocks, a mantel, embers
//   settings       a toolbox: wood, braces, side handles, a latch
//   keys           a keyboard case: slate, screws, plugged into the bar
//   clipboard      a satchel: leather, stitching, a strap and buckle
//   launcher       a spellbook: a spine, gilt corners, a ribbon
//   lock           a cabin window: a sill for the cat, a padlock
//   tray           a scroll: parchment between two wooden rollers
Item {
    id: root

    property int px: Theme.get("pixel.scale") ?? 3
    property string kind: ""
    property color face: Theme.palette.bg
    property color frame: Theme.palette.border
    property color outline: Theme.palette.shadow
    // How much of what sticks out shows (fade it in with the window).
    property real trim: 1

    readonly property int reach: 20
    // How far a dressed frame's band reaches outside the window.
    readonly property int grow: dressed ? 3 : 0
    // Whether `kind` is one this dresses (the rest get the cream band).
    readonly property bool dressed: ["network", "bluetooth", "audio", "calendar", "notifications", "control", "session", "settings", "keys", "clipboard", "launcher", "lock", "tray"].includes(kind)
    readonly property bool lively: ["bluetooth", "session"].includes(kind)

    readonly property var c: ({
        wood: "#6e5034",
        woodLight: "#8a6844",
        woodDark: "#4a3428",
        steel: "#7d7590",
        steelLight: "#a49bb5",
        steelDark: "#4f4866",
        stone: "#615b72",
        stoneLight: "#787088",
        stoneDark: "#4a4558",
        brass: "#c9a24a",
        brassDark: "#8a6a2e",
        leather: "#7a4e34",
        leatherDark: "#5a3826",
        rune: "#8fa0dc",
        red: "#b05a64",
        blue: "#5a6fb0",
        spine: "#6a2f3a",
        paper: "#b5a888",
        ember: "#ff9a2e",
        emberDim: "#a8452a"
    })

    Ticker {
        id: clock

        running: root.lively && root.visible && (Theme.get("pixel.animate") ?? true)
    }

    Canvas {
        id: canvas

        readonly property int frameNo: root.lively ? clock.frame : 0

        x: -root.reach * root.px
        y: -root.reach * root.px
        width: root.width + 2 * root.reach * root.px
        height: root.height + 2 * root.reach * root.px
        antialiasing: false
        renderStrategy: Canvas.Immediate

        onFrameNoChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: root.paint(getContext("2d"), frameNo)
    }

    onKindChanged: canvas.requestPaint()
    onTrimChanged: canvas.requestPaint()
    onFaceChanged: canvas.requestPaint()
    onFrameChanged: canvas.requestPaint()

    function paint(ctx: var, tick: int): void {
        const p = px, M = reach, c = root.c;
        const W = Math.round(width / p), H = Math.round(height / p);
        const cream = Theme.palette.border, accent = Theme.palette.accent;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        if (W < 8 || H < 8)
            return;
        ctx.globalAlpha = 1;
        // Everything below in art pixels, (0, 0) the window's top left; a
        // dressed frame's outline runs `grow` outside that, at -G and W+G-1.
        const G = grow, L = -G, T = -G, R = W + G - 1, B = H + G - 1;
        const rect = (x, y, w, h, col) => {
            if (w <= 0 || h <= 0)
                return;
            ctx.fillStyle = col;
            ctx.fillRect((x + M) * p, (y + M) * p, w * p, h * p);
        };
        const dot = (x, y, col) => rect(x, y, 1, 1, col);
        const clear = (x, y, w, h) => ctx.clearRect((x + M) * p, (y + M) * p, w * p, h * p);
        const rnd = (i, k) => {
            const v = Math.sin(i * 12.9898 + k * 78.233) * 43758.5453;
            return v - Math.floor(v);
        };
        // A box `inset` in from the window's edge (negative: outside it),
        // its corners cut in `cut` steps.
        const shape = (inset, cut, col) => {
            ctx.fillStyle = col;
            for (let y = inset; y < H - inset; y++) {
                const d = Math.min(y - inset, H - 1 - inset - y);
                const off = Math.max(0, cut - d);
                ctx.fillRect((inset + off + M) * p, (y + M) * p, (W - 2 * inset - 2 * off) * p, p);
            }
        };
        // Each pixel of ring `r` (as inset), clockwise from the top left:
        // f(i, x, y, side), side 0 top, 1 right, 2 bottom, 3 left.
        const ring = (r, f) => {
            let i = 0;
            for (let x = r; x < W - r; x++) f(i++, x, r, 0);
            for (let y = r + 1; y < H - r; y++) f(i++, W - 1 - r, y, 1);
            for (let x = W - 2 - r; x >= r; x--) f(i++, x, H - 1 - r, 2);
            for (let y = H - 2 - r; y > r; y--) f(i++, r, y, 3);
        };
        // The band's rings, outer to inner: f(i, x, y, side, row), row 0..2.
        const band = f => {
            for (let k = 0; k < 3; k++)
                ring(L + 1 + k, (i, x, y, s) => f(i, x, y, s, k));
        };
        // Only what sticks out further fades with `trim`.
        const outside = draw => {
            ctx.globalAlpha = trim;
            draw();
            ctx.globalAlpha = 1;
        };
        // The window: outline, a three-pixel band lit from the top left, a
        // dark seam, the face. `cut` rounds the corners off.
        const base = (cut, mid, light, dark) => {
            shape(L, cut, outline);
            shape(L + 1, Math.max(0, cut - 1), mid);
            ring(L + 1, (i, x, y, s) => {
                if (s === 0 || s === 3)
                    dot(x, y, light);
            });
            ring(L + 3, (i, x, y, s) => {
                if (s === 1 || s === 2)
                    dot(x, y, dark);
            });
            shape(L + 4, Math.max(0, cut - 4), outline);
            shape(L + 5, Math.max(0, cut - 5), face);
        };
        const plate = (x, y, w, h, col, hi) => {
            rect(x, y, w, h, outline);
            rect(x + 1, y + 1, w - 2, h - 2, col);
            rect(x + 1, y + 1, w - 2, 1, hi);
        };
        const corners = [[L, T, 1, 1], [R, T, -1, 1], [L, B, 1, -1], [R, B, -1, -1]];

        switch (kind) {
        case "network": {
            // A radio set: steel, riveted, a tuning dial under it.
            base(1, c.steel, c.steelLight, c.steelDark);
            ring(L + 2, (i, x, y, s) => {
                if (i % 8 === 4)
                    dot(x, y, cream);
            });
            for (const [x, y, sx, sy] of corners) {
                plate(sx > 0 ? x : x - 6, sy > 0 ? y : y - 6, 7, 7, c.steelDark, c.steel);
                dot(x + sx * 3, y + sy * 3, c.steelLight);
            }
            outside(() => {
                const dx = Math.floor(W / 2) - 9;
                rect(dx, B, 19, 6, outline);
                rect(dx + 1, B, 17, 5, c.steelDark);
                rect(dx + 2, B + 1, 15, 3, "#1b1726");
                for (let k = 0; k < 15; k += 2)
                    dot(dx + 2 + k, B + 1, k % 4 === 0 ? cream : c.steel);
                rect(dx + 6 + (tick % 2), B + 1, 1, 3, accent);
            });
            break;
        }
        case "bluetooth": {
            // A rune stone: bevelled, cut into blocks, moss in the joints,
            // a keystone with the ᛒ rune glowing (it breathes).
            base(4, c.stone, c.stoneLight, c.stoneDark);
            band((i, x, y, s, k) => {
                if (i % 12 === 0)
                    dot(x, y, c.stoneDark);
                else if (rnd(i * 3 + k, 1) < 0.1)
                    dot(x, y, c.stoneDark);
                else if (k === 1 && rnd(i, 7) < 0.04)
                    dot(x, y, rnd(i, 8) < 0.5 ? "#4a6038" : "#62784a");
            });
            for (const [x, y] of [[L + 2, B - 4], [L + 3, B - 3], [L + 2, B - 3], [L + 4, B - 2], [R - 6, T + 1], [R - 7, T + 1], [R - 5, T + 2]])
                dot(x, y, rnd(x, y) < 0.5 ? "#4a6038" : "#62784a");
            const kx = Math.floor(W / 2) - 7;
            outside(() => {
                rect(kx, T - 6, 15, 11, outline);
                rect(kx + 1, T - 5, 13, 9, c.stone);
                rect(kx + 1, T - 5, 13, 1, c.stoneLight);
                rect(kx + 1, T - 5, 1, 9, c.stoneLight);
                rect(kx + 1, T + 3, 13, 1, c.stoneDark);
                rect(kx + 13, T - 5, 1, 9, c.stoneDark);
            });
            ctx.globalAlpha = trim * (tick % 8 < 4 ? 1 : 0.55);
            // ᛒ: a stem, two bows.
            const ry = T - 4;
            for (const [x, y] of [[6, 0], [6, 1], [6, 2], [6, 3], [6, 4], [6, 5], [6, 6], [7, 0], [8, 1], [7, 2], [7, 3], [8, 4], [8, 5], [7, 6]])
                dot(kx + x, ry + y, c.rune);
            ctx.globalAlpha = 1;
            break;
        }
        case "audio": {
            // A speaker cabinet: planks with their grain, brass corners, a
            // knob, feet.
            base(1, c.wood, c.woodLight, c.woodDark);
            band((i, x, y, s, k) => {
                const run = Math.floor(i / 9);
                if (k === 1 && rnd(run, 3) < 0.5 && i % 9 > 1)
                    dot(x, y, c.woodDark);
                else if (k === 2 && rnd(run, 5) < 0.3)
                    dot(x, y, c.woodLight);
            });
            for (const [x, y, sx, sy] of corners)
                plate(sx > 0 ? x : x - 4, sy > 0 ? y : y - 4, 5, 5, c.brass, accent);
            outside(() => {
                for (const x of [6, W - 12]) {
                    rect(x, B, 7, 4, outline);
                    rect(x + 1, B, 5, 3, c.woodDark);
                    rect(x + 1, B, 5, 1, c.wood);
                }
                const ky = Math.floor(H / 2) - 3;
                rect(R, ky, 4, 7, outline);
                rect(R, ky + 1, 3, 5, c.brass);
                rect(R, ky + 1, 3, 1, accent);
                dot(R + 1, ky + 3, c.brassDark);
            });
            break;
        }
        case "calendar": {
            // A wall calendar: paper, a red binding along the top with rings
            // through it, hung on a nail; a dog-eared corner.
            base(1, cream, "#e8dcbf", c.paper);
            rect(L + 1, T + 1, W + 2 * G - 2, 3, c.red);
            rect(L + 1, T + 1, W + 2 * G - 2, 1, "#c8707a");
            const cx = Math.floor(W / 2);
            outside(() => {
                for (let k = 1; k <= 7; k++) {
                    const dx = Math.round(k * 2.4);
                    dot(cx - dx, T + 1 - k, c.paper);
                    dot(cx + dx, T + 1 - k, c.paper);
                }
                rect(cx - 1, T - 8, 3, 3, outline);
                dot(cx, T - 7, c.steelLight);
                for (let x = 6; x < W - 7; x += 8) {
                    if (Math.abs(x - cx) < 4)
                        continue;
                    rect(x - 1, T - 3, 4, 1, outline);
                    rect(x - 1, T - 2, 1, 4, outline);
                    rect(x + 2, T - 2, 1, 4, outline);
                    rect(x, T - 2, 2, 1, c.steelLight);
                    rect(x - 1, T - 1, 1, 2, c.steelLight);
                    rect(x, T + 2, 2, 1, outline);
                }
            });
            // The dog-ear, bottom right.
            const e = 8;
            clear(R - e + 1, B - e + 1, e, e);
            for (let k = 0; k < e; k++) {
                rect(R - e + 1, B - e + 1 + k, e - k, 1, c.paper);
                dot(R - k, B - e + 1 + k, outline);
            }
            rect(R - e, B - e + 1, 1, e, outline);
            rect(R - e + 1, B - e + 1, e, 1, outline);
            break;
        }
        case "notifications": {
            // An envelope: airmail stripes running round it, a stamp with a
            // moon on it, postmarked.
            base(1, cream, cream, c.paper);
            band((i, x, y, s, k) => {
                const m = (i + k * 2) % 12;
                dot(x, y, m < 5 ? c.red : m === 5 || m === 11 ? cream : c.blue);
            });
            outside(() => {
                const sx = R - 15, sy = T - 4;
                rect(sx, sy, 14, 16, outline);
                for (let k = 1; k < 14; k += 2) {
                    clear(sx + k, sy, 1, 1);
                    clear(sx + k, sy + 15, 1, 1);
                }
                for (let k = 1; k < 16; k += 2) {
                    clear(sx, sy + k, 1, 1);
                    clear(sx + 13, sy + k, 1, 1);
                }
                rect(sx + 1, sy + 1, 12, 14, cream);
                rect(sx + 2, sy + 2, 10, 12, c.blue);
                rect(sx + 5, sy + 4, 4, 6, accent);
                rect(sx + 6, sy + 3, 3, 1, accent);
                rect(sx + 6, sy + 10, 3, 1, accent);
                rect(sx + 7, sy + 5, 2, 4, c.blue);
                for (let k = 0; k < 12; k++) {
                    dot(sx - 9 + k, sy + 10 + (k % 4 < 2 ? 0 : 1), Theme.palette.muted);
                    dot(sx - 9 + k, sy + 13 + (k % 4 < 2 ? 0 : 1), Theme.palette.muted);
                }
            });
            break;
        }
        case "control": {
            // The cat's own: ears, whiskers, a tail curling off the corner.
            base(1, cream, "#e8dcbf", c.paper);
            outside(() => {
                // Ears: pointed up, pink inside.
                for (const x0 of [6, W - 17]) {
                    for (let k = 0; k < 7; k++)
                        rect(x0 + 5 - k, T - 7 + k, 1 + 2 * k, 1, outline);
                    for (let k = 1; k < 7; k++)
                        rect(x0 + 6 - k, T - 7 + k, 2 * k - 1, 1, cream);
                    for (let k = 3; k < 7; k++)
                        rect(x0 + 8 - k, T - 7 + k, 2 * k - 5, 1, "#e8a0b4");
                }
                const wy = Math.floor(H * 0.42);
                for (const [dy, len] of [[-3, 5], [0, 6], [3, 5]]) {
                    rect(L - len - 1, wy + dy, len, 1, cream);
                    rect(R + 2, wy + dy, len, 1, cream);
                }
                const tail = [[-5, -1], [-4, 0], [-3, 1], [-2, 2], [-1, 3], [0, 4], [1, 5], [2, 5], [3, 4], [4, 3], [4, 2], [3, 1]];
                for (const [x, y] of tail)
                    rect(R + x - 1, B + y - 1, 3, 3, outline);
                for (const [x, y] of tail)
                    dot(R + x, B + y, "#2a2533");
            });
            break;
        }
        case "session": {
            // A hearth: bricks, a mantel over it, embers along the floor.
            base(1, c.stone, c.stoneLight, c.stoneDark);
            band((i, x, y, s, k) => {
                if (k === 1 && (s === 0 || s === 2))
                    return;
                const off = k === 2 ? 4 : 0;
                if ((i + off) % 8 === 0)
                    dot(x, y, c.stoneDark);
                else if (Math.floor((i + off) / 8) % 3 === 1)
                    dot(x, y, k === 0 ? c.stoneLight : c.stone);
            });
            ring(L + 2, (i, x, y, s) => {
                if (s === 0 || s === 2)
                    dot(x, y, c.stoneDark);
            });
            outside(() => {
                rect(L - 4, T - 4, W + 2 * G + 8, 6, outline);
                rect(L - 3, T - 3, W + 2 * G + 6, 1, c.woodLight);
                rect(L - 3, T - 2, W + 2 * G + 6, 2, c.wood);
                rect(L - 3, T, W + 2 * G + 6, 1, c.woodDark);
                for (let x = 0; x < W + 2 * G + 6; x += 9)
                    rect(L - 3 + x, T - 2, 3, 1, c.woodDark);
            });
            for (let k = 2; k < W - 2; k++) {
                const r = rnd(k, tick % 6);
                if (r < 0.55)
                    dot(k, H - 3, r < 0.18 ? accent : r < 0.36 ? c.ember : c.emberDim);
            }
            break;
        }
        case "settings": {
            // A toolbox: planks, iron braces on its corners.
            base(1, c.wood, c.woodLight, c.woodDark);
            band((i, x, y, s, k) => {
                if (k === 1 && rnd(Math.floor(i / 7), 3) < 0.45 && i % 7 > 0)
                    dot(x, y, c.woodDark);
            });
            for (const [x, y, sx, sy] of corners) {
                for (let k = 0; k < 8; k++) {
                    dot(x + sx * k, y, outline);
                    dot(x, y + sy * k, outline);
                    if (k < 7) {
                        dot(x + sx * k, y + sy, c.steelDark);
                        dot(x + sx, y + sy * k, c.steelDark);
                        dot(x + sx * k, y + 2 * sy, k < 5 ? c.steel : c.steelDark);
                        dot(x + 2 * sx, y + sy * k, k < 5 ? c.steel : c.steelDark);
                    }
                }
                dot(x + 2 * sx, y + 2 * sy, c.steelLight);
                dot(x + 5 * sx, y + 2 * sy, c.steelLight);
                dot(x + 2 * sx, y + 5 * sy, c.steelLight);
            }
            outside(() => {
                // Iron handles on the sides, like a chest's (the top is the
                // bar's), and the latch below.
                const hy = Math.floor(H / 2) - 6;
                for (const [x, sx] of [[L, -1], [R, 1]]) {
                    const x0 = sx < 0 ? x - 4 : x + 1;
                    rect(x0, hy, 4, 13, outline);
                    clear(sx < 0 ? x0 : x0 + 1, hy + 3, 3, 7);
                    rect(sx < 0 ? x0 + 1 : x0, hy + 1, 3, 1, c.steelLight);
                    rect(sx < 0 ? x0 + 1 : x0 + 2, hy + 1, 1, 11, c.steel);
                    rect(sx < 0 ? x0 + 1 : x0, hy + 11, 3, 1, c.steelDark);
                }
                const lx = Math.floor(W / 2) - 4;
                rect(lx, B - 3, 9, 7, outline);
                rect(lx + 1, B - 2, 7, 5, c.brass);
                rect(lx + 1, B - 2, 7, 1, accent);
                rect(lx + 4, B, 1, 2, outline);
            });
            break;
        }
        case "keys": {
            // A keyboard's case: slate, screws, a row of keys along its
            // foot, its cable plugged up into the bar.
            base(1, "#3a3550", "#4f4866", "#2a2638");
            for (const [x, y, sx, sy] of corners) {
                dot(x + 2 * sx, y + 2 * sy, c.steelLight);
                dot(x + 2 * sx + 1, y + 2 * sy, c.steelDark);
            }
            outside(() => {
                for (let x = 2; x < W - 6; x += 5) {
                    const lit = x % 35 === 2;
                    rect(x, B - 1, 5, 4, outline);
                    rect(x + 1, B - 1, 3, 3, lit ? accent : "#4f4866");
                    rect(x + 1, B - 1, 3, 1, lit ? "#f8dca0" : "#6b6480");
                }
                const kx = W - 18;
                rect(kx - 2, T - 4, 7, 5, outline);
                rect(kx - 1, T - 3, 5, 3, c.steelDark);
                rect(kx - 1, T - 3, 5, 1, c.steel);
                rect(kx, T - 14, 3, 10, outline);
                for (let y = T - 14; y < T - 4; y += 2)
                    dot(kx + 1, y, c.steelDark);
            });
            break;
        }
        case "clipboard": {
            // A satchel: leather, stitched round, a strap buckled over.
            base(1, c.leather, "#94603f", c.leatherDark);
            ring(L + 2, (i, x, y, s) => {
                if (i % 2 === 0)
                    dot(x, y, c.paper);
            });
            const sx = Math.floor(W / 2) - 5;
            outside(() => {
                rect(sx - 1, T - 7, 12, 16, outline);
                rect(sx, T - 6, 10, 15, c.leatherDark);
                rect(sx, T - 6, 1, 15, c.leather);
                for (let y = T - 5; y < T + 8; y += 2) {
                    dot(sx + 2, y, c.paper);
                    dot(sx + 7, y, c.paper);
                }
                rect(sx - 3, T - 1, 16, 8, outline);
                rect(sx - 2, T, 14, 6, c.brass);
                rect(sx - 2, T, 14, 1, accent);
                rect(sx, T + 2, 10, 2, c.leatherDark);
                rect(sx + 5, T + 1, 1, 4, c.brassDark);
            });
            break;
        }
        case "launcher": {
            // A spellbook: a bound spine down the left, pages' edges down
            // the right, gilt corners, a ribbon hanging out.
            base(1, c.spine, "#8a4050", "#4a1f28");
            ring(L + 2, (i, x, y, s) => {
                if (s !== 3)
                    dot(x, y, "#4a1f28");
            });
            outside(() => {
                rect(L - 4, T - 1, 6, H + 2 * G + 2, outline);
                rect(L - 3, T, 4, H + 2 * G, "#4a1f28");
                rect(L - 3, T, 1, H + 2 * G, c.spine);
                const n = Math.max(3, Math.floor(H / 30));
                for (let k = 1; k <= n; k++) {
                    const y = Math.round(k * H / (n + 1));
                    rect(L - 3, y - 1, 5, 2, c.brass);
                    rect(L - 3, y - 1, 5, 1, accent);
                }
                // The pages, cream, between the covers on the right.
                rect(R + 1, T + 2, 2, H + 2 * G - 4, outline);
                for (let y = T + 2; y < B - 1; y++)
                    dot(R + 1, y, y % 2 ? cream : c.paper);
                const rx = 18;
                rect(rx - 1, B, 5, 10, outline);
                rect(rx, B, 3, 9, c.red);
                clear(rx + 1, B + 9, 1, 1);
                dot(rx + 1, B + 8, outline);
            });
            for (const [x, y, sx, sy] of corners) {
                if (sx > 0)
                    continue;
                for (let k = 0; k < 7; k++) {
                    dot(x - k, y, c.brassDark);
                    dot(x, y + sy * k, c.brassDark);
                    if (k < 6) {
                        dot(x - k, y + sy, c.brass);
                        dot(x - 1, y + sy * k, c.brass);
                        if (k < 4) {
                            dot(x - k, y + 2 * sy, c.brass);
                            dot(x - 2, y + sy * k, c.brass);
                        }
                    }
                }
                dot(x - 1, y + sy, accent);
            }
            break;
        }
        case "tray": {
            // A scroll: parchment edges, a wooden roller across the top and
            // one across the bottom (it unrolls with the window), brass
            // knobs on their ends.
            base(1, cream, "#e8dcbf", c.paper);
            for (const y of [T - 2, B - 2]) {
                rect(L - 4, y, W + 2 * G + 8, 5, outline);
                rect(L - 3, y + 1, W + 2 * G + 6, 1, c.woodLight);
                rect(L - 3, y + 2, W + 2 * G + 6, 1, c.wood);
                rect(L - 3, y + 3, W + 2 * G + 6, 1, c.woodDark);
                for (const x of [L - 6, R + 4]) {
                    rect(x, y, 3, 5, outline);
                    rect(x + (x < 0 ? 1 : 0), y + 1, 2, 3, c.brass);
                    dot(x + (x < 0 ? 1 : 0), y + 1, accent);
                }
            }
            // The parchment's curl just under the top roller.
            rect(L + 1, T + 3, W + 2 * G - 2, 1, c.paper);
            break;
        }
        case "lock": {
            // A cabin window: a wooden frame, its sill along the top (the
            // cat's spot), iron hinges, a padlock hung off the bottom.
            base(1, c.wood, c.woodLight, c.woodDark);
            band((i, x, y, s, k) => {
                if (k === 1 && rnd(Math.floor(i / 8), 4) < 0.45 && i % 8 > 0)
                    dot(x, y, c.woodDark);
            });
            for (const y of [8, H - 11]) {
                for (const [x, sx] of [[L, 1], [R, -1]]) {
                    rect(Math.min(x, x + sx * 8), y, 9, 4, outline);
                    rect(Math.min(x + sx, x + sx * 7), y + 1, 7, 2, c.steelDark);
                    rect(Math.min(x + sx, x + sx * 7), y + 1, 7, 1, c.steel);
                    dot(x + sx * 5, y + 2, c.steelLight);
                }
            }
            outside(() => {
                rect(L - 5, T - 4, W + 2 * G + 10, 6, outline);
                rect(L - 4, T - 3, W + 2 * G + 8, 1, c.woodLight);
                rect(L - 4, T - 2, W + 2 * G + 8, 2, c.wood);
                rect(L - 4, T, W + 2 * G + 8, 1, c.woodDark);
                for (let x = 0; x < W + 2 * G + 8; x += 11)
                    rect(L - 4 + x, T - 2, 3, 1, c.woodDark);
                const lx = Math.floor(W / 2) - 7;
                rect(lx + 2, B - 2, 11, 4, outline);
                rect(lx + 3, B - 1, 9, 2, c.steelDark);
                rect(lx + 3, B + 2, 9, 6, outline);
                rect(lx + 4, B + 2, 2, 6, c.steel);
                rect(lx + 9, B + 2, 2, 6, c.steel);
                rect(lx, B + 6, 15, 12, outline);
                rect(lx + 1, B + 7, 13, 10, c.brass);
                rect(lx + 1, B + 7, 13, 1, accent);
                rect(lx + 1, B + 16, 13, 1, c.brassDark);
                rect(lx + 6, B + 9, 3, 2, outline);
                rect(lx + 7, B + 11, 1, 3, outline);
            });
            break;
        }
        default:
            shape(0, 1, outline);
            shape(1, 0, root.frame);
            shape(2, 0, face);
        }
    }
}
