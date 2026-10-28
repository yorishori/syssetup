import QtQuick
import QtQuick.Window
import qs.core

// The cat, living on the bar. It wanders the ropes and signs, sits for a
// while, sometimes naps with its tail hanging over the rope or dangles from
// it by its front paws, stretches, and wanders on. When a panel opens it
// crouches and leaps onto the window's top edge and lies there while it's
// open, its tail hanging over; when the panel closes it leaps back up to
// the bar. Close the panel before it lands and it falls out of the
// picture; a while later it walks back in from the side of the screen.
//
// Its feet are at (`footX`, `footY`) in the strip's coordinates. It moves on
// its own slow clock (whole art pixels, a few frames a second), like the
// rest of the pixel art.
Item {
    id: root

    property int px: Theme.get("pixel.scale") ?? 3
    // Where its feet go on the bar at x: (x) => y.
    property var groundAt: x => 0
    // How far it wanders: the bar's walkable stretch.
    property real minX: 0
    property real maxX: 0
    // The open panel's drop, if any: the cat goes and sits on it.
    property Item drop: null
    property bool hidden: false

    // What it's doing: walk, sit, nap, hang, stretch, crouch, leap, perch
    // (on a panel), fall, away (out of the picture).
    property string mode: "sit"
    property real footX: 0
    property real footY: 0
    property bool facingLeft: false

    // A walk's or a leap's destination; a leap's start and how far along.
    property real targetX: 0
    property real targetY: 0
    property real startX: 0
    property real startY: 0
    property real leapT: 0
    // Where a leap lands: "panel" or "bar".
    property string landing: "bar"
    property real fallSpeed: 0
    property int tick: 0

    readonly property var colors: ({ "O": "#4f4570", "B": "#17141f", "L": "#1f1b29", "P": "#3a2a40", "E": "#ff9a2e" })
    readonly property bool moving: ["walk", "leap", "fall"].includes(mode)
    readonly property real screenHeight: Window.height > 0 ? Window.height : 1080

    // Where on the drop it sits: its frame's top edge (the drop's gap and the
    // frame's outward growth taken off), near where it jumped from.
    function perchY(): real {
        return drop ? drop.y + (drop.view?.gap ?? 0) - 3 * px : 0;
    }
    function perchX(from: real): real {
        if (!drop)
            return from;
        const margin = 12 * px;
        return Math.max(drop.x + margin, Math.min(drop.x + drop.width - margin, from));
    }
    function snap(v: real): real {
        return Math.round(v / px) * px;
    }
    function wander(): void {
        const span = maxX - minX;
        if (span <= 0)
            return;
        // Somewhere a good way off, not just a step.
        let to = minX + Math.random() * span;
        if (Math.abs(to - footX) < span * 0.15)
            to = footX < minX + span / 2 ? to + span * 0.3 : to - span * 0.3;
        walkTo(Math.max(minX, Math.min(maxX, to)));
    }
    function walkTo(x: real): void {
        targetX = x;
        facingLeft = x < footX;
        mode = "walk";
    }
    function rest(): void {
        // Mostly sits; now and then naps on the rope or hangs off it.
        const r = Math.random();
        mode = r < 0.6 ? "sit" : r < 0.88 ? "nap" : "hang";
        idle.interval = mode === "nap" ? 40000 + Math.random() * 60000 : mode === "hang" ? 4000 : 8000 + Math.random() * 14000;
        idle.restart();
    }
    function leapTo(x: real, y: real, where: string): void {
        startX = footX;
        startY = footY;
        targetX = x;
        targetY = y;
        landing = where;
        facingLeft = x < footX;
        leapT = 0;
        mode = "leap";
    }
    function goToDrop(): void {
        if (!drop || hidden || ["fall", "away"].includes(mode))
            return;
        idle.stop();
        // A crouch first, then the leap (the panel's settling meanwhile).
        mode = "crouch";
        crouch.restart();
    }
    function fall(): void {
        fallSpeed = 0;
        mode = "fall";
    }

    onDropChanged: {
        if (drop)
            Qt.callLater(goToDrop);
        else if (mode === "perch")
            leapTo(Math.max(minX, Math.min(maxX, footX)), groundAt(footX), "bar");
        else if (mode === "crouch")
            rest();
        else if (mode === "leap" && landing === "panel")
            fall();
    }

    Component.onCompleted: {
        footX = minX + (maxX - minX) * 0.3;
        footY = groundAt(footX);
        rest();
    }

    // Done sitting (napping, hanging): stretch, then off somewhere.
    Timer {
        id: idle

        onTriggered: {
            if (root.mode === "hang" || root.mode === "nap") {
                root.mode = "stretch";
                idle.interval = 1500;
                idle.restart();
            } else if (root.mode === "stretch" || root.mode === "sit") {
                root.wander();
            } else if (root.mode === "away") {
                // Back in from a side of the screen.
                const left = Math.random() < 0.5;
                root.footX = left ? -20 * root.px : root.width + 20 * root.px;
                root.footY = root.groundAt(root.footX);
                root.walkTo(root.minX + (root.maxX - root.minX) * (left ? 0.2 : 0.8));
            }
        }
    }
    Timer {
        id: crouch

        interval: 260
        onTriggered: {
            if (root.drop && root.mode === "crouch")
                root.leapTo(root.perchX(root.footX), root.perchY(), "panel");
        }
    }

    // Its clock while moving: 12 frames a second for leaps and falls, every
    // other frame a step while walking.
    Timer {
        interval: 83
        repeat: true
        running: root.moving && !root.hidden
        onTriggered: {
            root.tick++;
            if (root.mode === "walk") {
                if (root.tick % 2)
                    return;
                const step = 2 * root.px;
                const d = root.targetX - root.footX;
                if (Math.abs(d) <= step) {
                    root.footX = root.targetX;
                    root.footY = root.groundAt(root.footX);
                    root.rest();
                    return;
                }
                root.footX += Math.sign(d) * step;
                root.footY = root.groundAt(root.footX);
            } else if (root.mode === "leap") {
                // Over an arc, a bit over half a second; longer and higher
                // the further it goes (up to about a second).
                const dist = Math.hypot(root.targetX - root.startX, root.targetY - root.startY);
                root.leapT = Math.min(1, root.leapT + 0.15 * Math.max(0.5, Math.min(1, 400 / Math.max(1, dist))));
                const t = root.leapT;
                const lift = 10 * root.px + Math.abs(root.targetY - root.startY) * 0.2 + dist * 0.06;
                root.footX = root.startX + (root.targetX - root.startX) * t;
                root.footY = root.startY + (root.targetY - root.startY) * t - lift * 4 * t * (1 - t);
                if (t >= 1) {
                    if (root.landing === "panel") {
                        if (root.drop)
                            root.mode = "perch";
                        else
                            root.fall();
                    } else {
                        root.rest();
                    }
                }
            } else if (root.mode === "fall") {
                root.fallSpeed += 2.2 * root.px;
                root.footY += root.fallSpeed;
                root.footX += (root.facingLeft ? -1 : 1) * root.px;
                if (root.footY > root.screenHeight + 40 * root.px) {
                    root.mode = "away";
                    idle.interval = 6000 + Math.random() * 9000;
                    idle.restart();
                }
            }
        }
    }

    readonly property string frame: {
        switch (mode) {
        case "walk":
            return "walk" + (1 + Math.floor(tick / 2) % 4);
        case "sit":
        case "perch":
            return "sit-side";
        case "hang":
            return "hang";
        case "stretch":
            return "stretch";
        case "crouch":
            return "crouch";
        case "leap":
            return leapT < 0.8 ? "leap" : "crouch";
        case "fall":
            return "fall";
        default:
            return "stand";
        }
    }

    // Sitting on a panel follows its edge (it may grow or move); on the bar
    // it keeps to the rope as the bar changes under it.
    readonly property real shownX: mode === "perch" && drop ? perchX(footX) : footX
    readonly property real shownY: mode === "perch" && drop ? perchY()
        : ["leap", "fall"].includes(mode) ? footY : groundAt(footX)

    PixelArt {
        id: sprite

        visible: !root.hidden && !["away", "nap", "perch"].includes(root.mode)
        px: root.px
        flip: root.facingLeft
        colors: root.colors
        rows: Sprites.cat[root.frame] ?? []
        x: root.snap(root.shownX - width / 2)
        // Feet on the line; hanging, it's below the rope by its paws.
        y: root.mode === "hang" ? root.snap(root.shownY - 2 * root.px) : root.snap(root.shownY - height)
    }

    // Napping on a rope, or lying on a panel's edge: the loaf, its tail
    // hanging over.
    Cat {
        visible: !root.hidden && (root.mode === "nap" || root.mode === "perch")
        px: root.px
        pose: root.mode === "nap" ? "nap" : "loaf"
        flip: root.facingLeft
        x: root.snap(root.shownX - width / 2)
        y: root.snap(root.shownY - 7 * root.px)
    }
}
