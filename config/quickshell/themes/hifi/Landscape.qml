import QtQuick
import QtQuick.Shapes

// A flat, travel-poster landscape, made up for a month: the same picture
// every time for the same month, a different one for each. The season sets
// the scene and its colors:
//
//   winter   snowy peaks, birches in the snow
//   spring   green hills dotted with blossom
//   summer   headlands over the sea, a sailboat, glitter on the water
//   autumn   rust and ochre hills, round trees, fog in the valleys
//
// Its moon is the real one: its phase on `moonDay`. It's drawn last, over
// everything, so nothing in the picture ever hides it.
Item {
    id: root

    property int year: 2026
    property int month: 0  // 0-11
    property date moonDay: new Date()

    readonly property string season: [11, 0, 1].includes(month) ? "winter"
        : [2, 3, 4].includes(month) ? "spring"
        : [5, 6, 7].includes(month) ? "summer" : "autumn"
    readonly property var colors: ({
        winter: { sky: ["#9fbbd1", "#e6edf0"], layers: ["#93a9bd", "#647e97", "#3d526a"], ground: "#e9eef1", moon: "#fbfaf4" },
        spring: { sky: ["#8fc8dc", "#f4efd4"], layers: ["#a3c98a", "#6ea562", "#3f7a4a"], ground: "#5b8f4f", moon: "#fffbe8" },
        summer: { sky: ["#f2a65e", "#fde3b0"], layers: ["#c77857", "#9a5440", "#e0bd86"], ground: "#e7c891", moon: "#fff6dc" },
        autumn: { sky: ["#e2b98a", "#f6e5c6"], layers: ["#c48a45", "#9c4e2b", "#5e3b2b"], ground: "#4f3326", moon: "#fff3d6" }
    })[season]

    // How far through its cycle the moon is on `moonDay`: 0 new, 0.5 full.
    readonly property real moonPhase: {
        const synodic = 29.530588853;
        const days = (moonDay.getTime() - Date.UTC(2000, 0, 6, 18, 14)) / 86400000;
        return ((days / synodic) % 1 + 1) % 1;
    }
    // The scene, made up from the month.
    readonly property var scene: make(year * 12 + month, width, height, season)

    clip: true

    // A small seeded generator, so a month always gets the same picture.
    function random(seed: int): var {
        let a = seed * 2654435761 >>> 0;
        return () => {
            a = (a + 0x6D2B79F5) >>> 0;
            let t = a;
            t = Math.imul(t ^ (t >>> 15), t | 1);
            t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
            return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
        };
    }

    function make(seed: int, w: real, h: real, kind: string): var {
        if (w <= 0 || h <= 0)
            return { layers: [], caps: [], dots: [], trunks: [], fog: [], birds: [], sea: null, boat: null, moon: { x: 0, y: 0, r: 0 } };
        const r = random(seed + 1);
        const steps = 64;
        // A ridge line across the picture at `base` (0-1 down), `rough`
        // jagged (mountains) or smooth (hills), `lift` how far it rises.
        const ridge = (base, lift, rough) => {
            const waves = Array.from({ length: 4 }, (_, i) => ({ f: (i + 1) * (0.8 + r() * 1.4), p: r() * 6.3, a: lift / (i + 1.2) }));
            const pts = [];
            for (let i = 0; i <= steps; i++) {
                const x = i / steps;
                let y = base;
                for (const v of waves)
                    y -= v.a * (0.5 + 0.5 * Math.sin(x * v.f * 6.283 + v.p));
                if (rough)
                    y -= lift * 0.35 * Math.abs(Math.sin(x * 23 + r() * 0.6)) * r();
                pts.push(Qt.point(x * w, y * h));
            }
            return pts;
        };
        const fill = pts => pts.concat([Qt.point(w, h), Qt.point(0, h)]);

        const scene = { layers: [], caps: [], dots: [], trunks: [], fog: [], birds: [], sea: null, boat: null };
        const far = ridge(0.52, 0.26, kind === "winter");
        const mid = ridge(0.66, 0.2, kind === "winter");
        const near = ridge(0.84, 0.12, false);

        if (kind === "summer") {
            // Headlands either side of a bay, standing in the sea, dunes in
            // front.
            const sea = 0.6 * h;
            const left = 0.3 + r() * 0.15, right = 0.62 + r() * 0.15;
            const cape = (pts, from, to) => {
                const land = pts.filter(p => p.x >= from * w && p.x <= to * w);
                const slope = 18;
                return (from === 0 ? [Qt.point(0, sea)] : [Qt.point(from * w - slope, sea)])
                    .concat(land, to === 1 ? [Qt.point(w, sea)] : [Qt.point(to * w + slope, sea)]);
            };
            scene.sea = { y: sea };
            scene.layers.push({ color: colors.layers[0], pts: cape(ridge(0.6, 0.18, false), 0, left) });
            scene.layers.push({ color: colors.layers[1], pts: cape(ridge(0.6, 0.12, false), right, 1) });
            scene.layers.push({ color: colors.layers[2], pts: fill(near) });
            scene.boat = { x: (0.35 + r() * 0.3) * w, y: 0.6 * h + 0.07 * h };
        } else {
            scene.layers.push({ color: colors.layers[0], pts: fill(far) });
            scene.layers.push({ color: colors.layers[1], pts: fill(mid) });
            scene.layers.push({ color: kind === "winter" ? colors.ground : colors.layers[2], pts: fill(near) });
        }
        if (kind === "winter") {
            // Snow on whatever rises above the snowline; birches in front.
            const snow = Math.min(...far.map(p => p.y)) + 0.07 * h;
            scene.caps.push(far.map(p => Qt.point(p.x, Math.min(p.y, snow))).concat([Qt.point(w, snow), Qt.point(0, snow)]));
            for (let i = 0; i < 7; i++) {
                const x = (0.05 + r() * 0.9) * w;
                const ground = near[Math.round(x / w * steps)].y;
                scene.trunks.push({ x: x, y: ground - (0.18 + r() * 0.16) * h, h: (0.18 + r() * 0.16) * h + 6, marks: Array.from({ length: 5 }, () => r()) });
            }
        }
        if (kind === "spring") {
            for (let i = 0; i < 46; i++) {
                const x = r() * w;
                const top = near[Math.round(x / w * steps)].y;
                scene.dots.push({ x: x, y: top + 6 + r() * (h - top - 8), r: 1.5 + r() * 2.2, color: r() < 0.65 ? "#f3a9c4" : "#fdf6f0" });
            }
        }
        if (kind === "autumn") {
            for (let i = 0; i < 16; i++) {
                const x = r() * w;
                const top = mid[Math.round(x / w * steps)].y;
                const size = 7 + r() * 9;
                scene.dots.push({ x: x, y: top - size * 0.6, r: size, color: ["#c9662d", "#d9a13f", "#8f3b22"][Math.floor(r() * 3)] });
            }
            for (let i = 0; i < 2; i++)
                scene.fog.push({ y: (0.6 + i * 0.12 + r() * 0.04) * h, h: 12 + r() * 8 });
        }
        for (let i = 0; i < 4; i++)
            scene.birds.push({ x: (0.15 + r() * 0.7) * w, y: (0.1 + r() * 0.22) * h, s: 3 + r() * 4 });
        // The moon, always in open sky, clear of the highest ridge.
        const moonR = 13 + r() * 5;
        const moonX = (0.12 + r() * 0.76) * w;
        const skyline = (kind === "summer" ? [] : far).concat(scene.layers.reduce((all, l) => all.concat(l.pts), []))
            .filter(p => Math.abs(p.x - moonX) < moonR + 6).reduce((top, p) => Math.min(top, p.y), h);
        scene.moon = { x: moonX, y: Math.max(moonR + 6, Math.min((0.12 + r() * 0.1) * h, skyline - moonR - 8)), r: moonR };
        return scene;
    }

    // The sky.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: root.colors.sky[0] }
            GradientStop { position: 0.75; color: root.colors.sky[1] }
        }
    }

    // The birds.
    Repeater {
        model: root.scene.birds

        Shape {
            required property var modelData

            x: modelData.x
            y: modelData.y
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: Qt.alpha("#2b2420", 0.7)
                strokeWidth: 1.4
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: -modelData.s
                startY: -modelData.s * 0.4

                PathQuad { x: 0; y: 0; controlX: -modelData.s * 0.4; controlY: -modelData.s * 0.6 }
                PathQuad { x: modelData.s; y: -modelData.s * 0.4; controlX: modelData.s * 0.4; controlY: -modelData.s * 0.6 }
            }
        }
    }

    // The sea, glittering, under the headlands.
    Item {
        visible: root.scene.sea !== null
        y: root.scene.sea?.y ?? 0
        width: root.width
        height: root.height - y

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "#2f7fa3" }
                GradientStop { position: 1; color: "#1d5874" }
            }
        }
        Repeater {
            model: 9

            Rectangle {
                required property int index

                x: root.width * (0.2 + 0.07 * index + 0.03 * Math.sin(index * 3.1))
                y: 4 + index * 5
                width: 18 - index
                height: 1.5
                color: Qt.alpha("#ffe9b8", 0.7)
            }
        }
    }

    // The land, far to near.
    Repeater {
        model: root.scene.layers

        Shape {
            required property var modelData

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: "transparent"
                fillColor: modelData.color

                PathPolyline { path: modelData.pts }
            }
        }
    }
    Repeater {
        model: root.scene.caps

        Shape {
            required property var modelData

            anchors.fill: parent

            ShapePath {
                strokeColor: "transparent"
                fillColor: "#f4f7f9"

                PathPolyline { path: modelData }
            }
        }
    }

    // The sailboat.
    Shape {
        visible: root.scene.boat !== null
        x: root.scene.boat?.x ?? 0
        y: root.scene.boat?.y ?? 0

        ShapePath {
            strokeColor: "transparent"
            fillColor: "#fbf6ea"
            startX: 0
            startY: -2

            PathLine { x: 0; y: -26 }
            PathLine { x: 14; y: -2 }
        }
        ShapePath {
            strokeColor: "transparent"
            fillColor: "#e9dcc4"
            startX: -2
            startY: -4

            PathLine { x: -2; y: -20 }
            PathLine { x: -11; y: -4 }
        }
        ShapePath {
            strokeColor: "transparent"
            fillColor: "#5a2f22"
            startX: -13
            startY: -1

            PathLine { x: 17; y: -1 }
            PathLine { x: 12; y: 4 }
            PathLine { x: -9; y: 4 }
        }
    }

    // Birches in the snow.
    Repeater {
        model: root.scene.trunks

        Item {
            id: trunk

            required property var modelData

            x: modelData.x
            y: modelData.y
            width: 4
            height: modelData.h

            Rectangle {
                anchors.fill: parent
                color: "#f6f4ee"
            }
            Repeater {
                model: trunk.modelData.marks

                Rectangle {
                    required property int index
                    required property real modelData

                    x: modelData < 0.5 ? 0 : 1.5
                    y: trunk.height * (0.1 + 0.16 * index + 0.08 * modelData)
                    width: 2.5
                    height: 1.5
                    color: "#2e2a26"
                }
            }
        }
    }

    // Blossom, and the trees' crowns.
    Repeater {
        model: root.scene.dots

        Rectangle {
            required property var modelData

            x: modelData.x - modelData.r
            y: modelData.y - modelData.r
            width: 2 * modelData.r
            height: width
            radius: width / 2
            color: modelData.color
        }
    }

    // Fog lying in the valleys.
    Repeater {
        model: root.scene.fog

        Rectangle {
            required property var modelData

            y: modelData.y
            width: root.width
            height: modelData.h
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha("white", 0) }
                GradientStop { position: 0.5; color: Qt.alpha("white", 0.14) }
                GradientStop { position: 1; color: Qt.alpha("white", 0) }
            }
        }
    }

    // The moon, last, over everything: only its lit part, between its edge
    // on the lit side (the right while it waxes) and the terminator, a
    // half-ellipse that bulges toward the light while it's a crescent and
    // away from it once it's past half.
    Shape {
        id: moon

        readonly property real r: root.scene.moon.r
        readonly property bool waxing: root.moonPhase < 0.5
        readonly property real bend: Math.cos(2 * Math.PI * root.moonPhase)  // 1 new, -1 full
        readonly property bool crescent: bend > 0

        x: root.scene.moon.x
        y: root.scene.moon.y
        visible: r > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillColor: root.colors.moon
            startX: 0
            startY: -moon.r

            // The edge, round the lit side.
            PathArc {
                x: 0
                y: moon.r
                radiusX: moon.r
                radiusY: moon.r
                direction: moon.waxing ? PathArc.Clockwise : PathArc.Counterclockwise
            }
            // The terminator, back up.
            PathArc {
                x: 0
                y: -moon.r
                radiusX: Math.max(0.01, moon.r * Math.abs(moon.bend))
                radiusY: moon.r
                direction: moon.waxing === moon.crescent ? PathArc.Counterclockwise : PathArc.Clockwise
            }
        }
    }
}
