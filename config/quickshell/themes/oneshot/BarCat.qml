import QtQuick
import QtQuick.Window
import qs.core

// The cat, living on the bar. It wanders the ropes and signs, sits for a
// while, sometimes naps with its tail hanging over the rope or dangles from
// it by its front paws, stretches, and wanders on. Where two brackets stand
// side by side there's no rope between them but a tunnel: it walks into
// one, both light up, and it steps out of the other.
//
// When a panel opens it hurries along the ropes to the point nearest it,
// crouches, and leaps down onto the window's top edge, and lies there while
// it's open, its tail hanging over; when the panel closes it leaps back up
// to the bar. Close the panel before it lands and it falls out of the
// picture; a while later it's back, climbing up the rope's end that dangles
// from the bar, paw over paw, and pulling itself up on top.
//
// Its feet are at (`footX`, `footY`) in the strip's coordinates. It moves on
// its own slow clock (whole art pixels, a few frames a second), like the
// rest of the pixel art.
Item {
    id: root

    property int px: Theme.get("pixel.scale") ?? 3
    // Where its feet go on the bar at x: (x) => y; whether x is on a rope.
    property var groundAt: x => 0
    property var onRope: x => true
    // How far it wanders: the bar's walkable stretch, the tunnels across it
    // ([{ a, b }]: in at one end, out at the other) and the rope's end it
    // climbs ({ x, top, length }).
    property real minX: 0
    property real maxX: 0
    property var portals: []
    property var vine: null
    // The open panel's drop, if any: the cat goes and sits on it.
    property Item drop: null
    property bool hidden: false

    // What it's doing: walk, sit, nap, hang, stretch, crouch, leap, perch
    // (on a panel), fall, away (out of the picture), portal (in a tunnel),
    // climb, pullup.
    property string mode: "sit"
    property real footX: 0
    property real footY: 0
    property bool facingLeft: false

    // A walk's destination, how fast, and what after ("rest" or "leap").
    property real targetX: 0
    property bool hurrying: false
    property string afterWalk: "rest"
    // A leap's start, destination, how far along, and where it lands
    // ("panel" or "bar").
    property real startX: 0
    property real startY: 0
    property real targetY: 0
    property real leapT: 0
    property string landing: "bar"
    property real fallSpeed: 0
    // Where it'll come out of a tunnel; how far below the rope it is while
    // climbing.
    property real portalOut: 0
    property real climbY: 0
    property int tick: 0

    // How bright the tunnel's ends are (it lights up as the cat goes
    // through, then fades).
    property real portalGlow: 0

    Behavior on portalGlow {
        NumberAnimation { duration: 450 }
    }

    readonly property var colors: ({ "O": "#4f4570", "B": "#17141f", "L": "#1f1b29", "P": "#3a2a40", "E": "#ff9a2e" })
    readonly property bool moving: ["walk", "leap", "fall", "climb"].includes(mode)
    readonly property real screenHeight: Window.height > 0 ? Window.height : 1080

    // Where on the drop it lies: its frame's top edge (the drop's gap and
    // the frame's outward growth taken off), near where it jumped from.
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
    // The nearest place it can stop at to x: on the bar, not in a tunnel,
    // and not up against its ends either (it only passes through them).
    function settle(x: real): real {
        x = Math.max(minX, Math.min(maxX, x));
        const clear = 16 * px;
        for (const p of portals)
            if (x > p.a - clear && x < p.b + clear)
                return x - p.a < p.b - x ? p.a - clear : p.b + clear;
        return x;
    }
    function wander(): void {
        const span = maxX - minX;
        if (span <= 0)
            return;
        // Somewhere a good way off, not just a step.
        let to = minX + Math.random() * span;
        if (Math.abs(to - footX) < span * 0.15)
            to = footX < minX + span / 2 ? to + span * 0.3 : to - span * 0.3;
        walkTo(to, false, "rest");
    }
    function walkTo(x: real, fast: bool, next: string): void {
        targetX = settle(x);
        hurrying = fast;
        afterWalk = next;
        facingLeft = targetX < footX;
        idle.stop();
        mode = "walk";
    }
    function rest(): void {
        // Mostly sits; now and then naps on the rope or hangs off it.
        const r = Math.random();
        mode = r < 0.6 ? "sit" : r < 0.88 || !onRope(footX) ? "nap" : "hang";
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
        if (!drop || hidden || ["fall", "away", "climb", "pullup", "portal"].includes(mode))
            return;
        idle.stop();
        // From one panel straight to the next.
        if (mode === "perch") {
            leapTo(perchX(footX), perchY(), "panel");
            return;
        }
        // Along the ropes to the nearest point, then the leap.
        const from = settle(perchX(footX));
        if (Math.abs(from - footX) > 2 * px)
            walkTo(from, true, "leap");
        else
            crouchThenLeap();
    }
    function crouchThenLeap(): void {
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
            leapTo(settle(footX), groundAt(settle(footX)), "bar");
        else if (mode === "crouch" || (mode === "walk" && afterWalk === "leap"))
            rest();
        else if (mode === "leap" && landing === "panel")
            fall();
    }

    Component.onCompleted: {
        footX = settle(minX + (maxX - minX) * 0.3);
        footY = groundAt(footX);
        rest();
    }
    // The bar's laid out after it starts (or changes under it): if that
    // leaves it off the bar while it's resting, it's simply somewhere on it.
    onMaxXChanged: {
        if (["sit", "nap", "hang", "stretch"].includes(mode) && (footX < minX || footX > maxX))
            footX = settle(minX + (maxX - minX) * 0.3);
    }

    // Done sitting (napping, hanging): stretch, then off somewhere. Back
    // from a fall: up the rope's end.
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
                if (root.vine) {
                    root.footX = root.vine.x;
                    root.footY = root.vine.top;
                    root.climbY = root.vine.length - 4 * root.px;
                    root.mode = "climb";
                } else {
                    // No rope to climb: in from a side of the screen.
                    const left = Math.random() < 0.5;
                    root.footX = left ? -20 * root.px : root.width + 20 * root.px;
                    root.footY = root.groundAt(root.footX);
                    root.walkTo(root.minX + (root.maxX - root.minX) * (left ? 0.2 : 0.8), false, "rest");
                }
            } else if (root.mode === "pullup") {
                root.rest();
                if (root.drop)
                    root.goToDrop();
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
    // Through the tunnel: a moment inside, then out the other end.
    Timer {
        id: tunnel

        interval: 650
        onTriggered: {
            root.footX = root.portalOut;
            root.footY = root.groundAt(root.footX);
            root.portalGlow = 0;
            root.mode = "walk";
        }
    }

    // Its clock while moving: 12 frames a second; a step every other frame
    // walking, every frame hurrying, a pull every other frame climbing.
    Timer {
        interval: 83
        repeat: true
        running: root.moving && !root.hidden
        onTriggered: {
            root.tick++;
            if (root.mode === "walk") {
                if (!root.hurrying && root.tick % 2)
                    return;
                // Heading for a tunnel's mouth first, if it's on the way.
                let goal = root.targetX, through = null;
                for (const p of root.portals) {
                    if (root.footX <= p.a && root.targetX >= p.b)
                        [goal, through] = [p.a, p.b];
                    else if (root.footX >= p.b && root.targetX <= p.a)
                        [goal, through] = [p.b, p.a];
                }
                const step = (root.hurrying ? 8 : 2) * root.px;
                const d = goal - root.footX;
                root.facingLeft = d < 0;
                if (Math.abs(d) <= step) {
                    root.footX = goal;
                    root.footY = root.groundAt(root.footX);
                    if (through !== null) {
                        root.portalOut = through;
                        root.portalGlow = 1;
                        root.mode = "portal";
                        tunnel.restart();
                    } else if (root.afterWalk === "leap" && root.drop) {
                        root.crouchThenLeap();
                    } else {
                        root.rest();
                    }
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
            } else if (root.mode === "climb") {
                if (root.tick % 2)
                    return;
                // Paw over paw (it turns a little each pull), then over the
                // top.
                root.climbY = Math.max(0, root.climbY - 2 * root.px);
                root.facingLeft = !root.facingLeft;
                if (root.climbY <= 0) {
                    root.footY = root.groundAt(root.footX);
                    root.mode = "pullup";
                    idle.interval = 450;
                    idle.restart();
                }
            }
        }
    }

    readonly property string frame: {
        switch (mode) {
        case "walk":
            return "walk" + (1 + Math.floor(hurrying ? tick : tick / 2) % 4);
        case "sit":
            return "sit-side";
        case "hang":
        case "climb":
            return "hang";
        case "stretch":
            return "stretch";
        case "crouch":
        case "pullup":
            return "crouch";
        case "leap":
            return leapT < 0.8 ? "leap" : "crouch";
        case "fall":
            return "fall";
        default:
            return "stand";
        }
    }

    // On the bar it keeps to the rope as the bar changes under it.
    readonly property real shownX: footX
    readonly property real shownY: ["leap", "fall", "climb"].includes(mode) ? footY : groundAt(footX)

    PixelArt {
        id: sprite

        visible: !root.hidden && !["away", "nap", "perch", "portal"].includes(root.mode)
        px: root.px
        flip: root.facingLeft
        colors: root.colors
        rows: Sprites.cat[root.frame] ?? []
        x: root.snap(root.shownX - width / 2)
        // Feet on the line; hanging or climbing, it holds on by its paws.
        y: root.mode === "hang" ? root.snap(root.shownY - 2 * root.px)
            : root.mode === "climb" ? root.snap(root.footY + root.climbY - 2 * root.px)
            : root.snap(root.shownY - height)
    }

    // Napping on a rope: the loaf, its tail hanging over.
    Cat {
        visible: !root.hidden && root.mode === "nap"
        px: root.px
        pose: "nap"
        flip: root.facingLeft
        x: root.snap(root.shownX - width / 2)
        y: root.snap(root.shownY - 7 * root.px)
    }

    // Lying on a panel: the panel draws it, over its frame (CatState).
    Binding {
        target: CatState
        property: "perch"
        value: root.mode === "perch" && root.drop && !root.hidden ? root.drop.name : ""
    }
    Binding {
        target: CatState
        property: "perchX"
        value: root.perchX(root.footX)
    }
    Binding {
        target: CatState
        property: "perchFlip"
        value: root.facingLeft
    }
}
