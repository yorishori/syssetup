import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components as C
import qs.core
import qs.modules.session as M

// Blast doors. Opening the session menu slams two steel doors shut over the
// whole screen from the sides; their hazard-striped edges are toothed and
// interlock where they meet. The session buttons are mounted on them in a
// row across the middle (lock and shutdown on the left, reboot and sleep on
// the right), and the uptime reads out on a VFD. Arming shutdown or reboot
// brings a third door down from the top over everything; the action runs
// when it's shut (the key's fuse). Cancelled, it goes back up. Closing the
// menu opens the doors.
Item {
    id: root

    required property M.SessionPanel control

    // Whether any of it is still on screen (the window stays up until not).
    readonly property bool covering: shut > 0 || lid > 0.001

    readonly property color steel: "#3a3c42"
    readonly property color hazard: Theme.values.display?.hazard ?? Theme.palette.warn
    readonly property color vfd: Theme.palette.accent

    // The toothed edge: teeth `depth` deep, one every `period`, with sloped
    // flanks `slope` long; the hazard band behind it is `band` wide at a
    // notch, with a riveted steel strip `strip` wide behind that.
    readonly property real depth: 70
    readonly property real period: 260
    readonly property real slope: 40
    readonly property real band: 90
    readonly property real strip: 54
    // How far in from its edge a side door's plate begins.
    readonly property real edgeWidth: band + depth + strip

    // The side doors: 0 open, 1 shut. `jolt` shakes everything when they slam.
    property real shut: 0
    property real jolt: 0

    // The top door follows the armed key's fuse down, and goes back up when
    // it's cancelled.
    readonly property M.SessionKey armedKey: control.armed < 0 ? null : (control.armed < 2 ? leftKeys.itemAt(control.armed) : rightKeys.itemAt(control.armed - 2)) as M.SessionKey
    readonly property real lid: armedKey ? 1 - armedKey.fuse : rising
    property real lastLid: 0
    property real rising: 0  // where it is while going back up

    // The buttons' row, gathered toward the seam: how far from the edge the
    // nearest one sits, and the gap between the two on a door.
    readonly property real seamGap: 60
    readonly property real gap: 50

    onLidChanged: {
        if (armedKey)
            lastLid = lid;
    }
    NumberAnimation {
        id: rise

        target: root
        property: "rising"
        to: 0
        duration: 600
        easing.type: Easing.InOutCubic
    }

    Connections {
        target: root.control

        function onArmedChanged(): void {
            if (root.control.armed >= 0) {
                rise.stop();
            } else {
                rise.from = root.lastLid;
                rise.start();
            }
        }

        function onOpenChanged(): void {
            if (root.control.open) {
                part.stop();
                slam.start();
            } else {
                slam.stop();
                part.start();
            }
        }
    }

    // Heavy doors: they gather speed and slam; the impact shakes them.
    SequentialAnimation {
        id: slam

        NumberAnimation { target: root; property: "shut"; to: 1; duration: 420; easing.type: Easing.InQuad }
        SequentialAnimation {
            NumberAnimation { target: root; property: "jolt"; to: 1; duration: 40 }
            NumberAnimation { target: root; property: "jolt"; to: -0.6; duration: 60 }
            NumberAnimation { target: root; property: "jolt"; to: 0.3; duration: 60 }
            NumberAnimation { target: root; property: "jolt"; to: 0; duration: 80 }
        }
    }
    NumberAnimation {
        id: part

        target: root
        property: "shut"
        to: 0
        duration: 380
        easing.type: Easing.InOutCubic
    }

    // The hazard band along a door's toothed edge. It's laid out along the
    // edge (`length`) and across it (band and teeth, the teeth at the far
    // side), then turned to face `edge` ("right", "left" or "bottom");
    // `phase` shifts the teeth along, so two doors can mesh.
    component Band: Item {
        id: band

        property string edge: "right"
        property real length
        property real phase: 0
        readonly property bool across: edge === "bottom"
        readonly property real thickness: root.band + root.depth

        // A point `a` along the edge and `c` across it (0 = the inner side).
        function at(a: real, c: real): point {
            return edge === "right" ? Qt.point(c, a) : edge === "left" ? Qt.point(thickness - c, a) : Qt.point(a, c);
        }
        // The toothed edge, from one end to the other.
        function teeth(): var {
            const p = root.period, s = root.slope, flat = p / 2 - s;
            const tip = thickness, notch = thickness - root.depth;
            const out = [];
            for (let base = -phase - p; base < length + p; base += p)
                out.push(at(base, tip), at(base + flat, tip), at(base + flat + s, notch), at(base + 2 * flat + s, notch));
            return out;
        }
        function outline(): var {
            return [at(-2 * root.period, 0), ...teeth(), at(length + 2 * root.period, 0), at(-2 * root.period, 0)];
        }

        width: across ? length : thickness
        height: across ? thickness : length
        clip: true

        // The stripes over safety yellow, worn by the grain; the right door's
        // are mirrored, so the two make chevrons where they meet.
        Item {
            id: stripes

            anchors.fill: parent
            visible: false
            layer.enabled: true

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: band.across ? Gradient.Vertical : Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.darker(root.hazard, 1.2) }
                    GradientStop { position: 1; color: Qt.lighter(root.hazard, 1.05) }
                }
            }
            Image {
                anchors.fill: parent
                source: Qt.resolvedUrl("hazard.png")
                fillMode: Image.Tile
                transform: Scale {
                    origin.x: band.width / 2
                    xScale: band.edge === "left" ? -1 : 1
                }
            }
            Image {
                anchors.fill: parent
                source: Qt.resolvedUrl("brushed.png")
                fillMode: Image.Tile
                opacity: 0.5
            }
        }
        // The band's shape, as a mask for the stripes.
        Shape {
            id: shape

            anchors.fill: parent
            visible: false
            layer.enabled: true
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: -1
                fillColor: "white"

                PathPolyline {
                    path: band.outline()
                }
            }
        }
        MultiEffect {
            anchors.fill: parent
            source: stripes
            maskEnabled: true
            maskSource: shape
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.2
        }

        // The edge's dark lip.
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: "#0b0b0c"
                strokeWidth: 4
                fillColor: "transparent"
                joinStyle: ShapePath.MiterJoin

                PathPolyline {
                    path: band.teeth()
                }
            }
        }
    }

    // A rivet: a little steel dome.
    component Rivet: Rectangle {
        width: 12
        height: 12
        radius: 6
        border.width: 1
        border.color: Qt.alpha("black", 0.7)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(root.steel, 2.1) }
            GradientStop { position: 1; color: Qt.darker(root.steel, 1.4) }
        }
    }

    // The riveted strip behind a band: brighter steel. `vertical` when it
    // runs top to bottom.
    component Strip: Item {
        id: strip

        property bool vertical: true

        Metal {
            anchors.fill: parent
            roundness: 0
            tint: Qt.lighter(root.steel, 1.35)
        }
        Repeater {
            model: Math.max(0, Math.floor((strip.vertical ? strip.height : strip.width) / 96))

            Rivet {
                required property int index

                x: strip.vertical ? (strip.width - width) / 2 : 48 + index * 96
                y: strip.vertical ? 48 + index * 96 : (strip.height - height) / 2
            }
        }
    }

    // A session button, wired to the menu; `slot` is its action's index.
    component Button: M.SessionKey {
        id: button

        required property int modelData
        readonly property int slot: modelData
        readonly property var action: root.control.actions[slot]

        width: 220
        height: 222
        key: action.key
        label: action.label
        glyph: action.glyph
        number: slot + 1
        current: root.control.selected === slot
        armed: root.control.armed === slot
        onHoveredChanged: {
            if (hovered)
                root.control.hover(button.slot);
        }
        onClicked: root.control.activate(button.slot)
        onFused: root.control.execute(button.slot)
    }

    // The uptime on a vacuum fluorescent display: glowing segments behind
    // smoked glass and the fine grid of the tube's mesh, the host on tape.
    component Uptime: Column {
        id: uptime

        readonly property int hours: Math.floor(root.control.uptime / 3600)
        readonly property int minutes: Math.floor(root.control.uptime % 3600 / 60)

        spacing: 10

        Legend {
            text: root.control.hostname
            size: 14
        }

        Item {
            width: digits.x + digits.width + 18
            height: 60

            Well {
                id: tube

                anchors.fill: parent
                fill: Qt.tint("#050807", Qt.alpha(root.vfd, 0.05))
            }

            Item {
                anchors.fill: parent
                layer.enabled: (Theme.glow.opacity ?? 0) > 0
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: root.vfd
                    shadowOpacity: Theme.glow.opacity ?? 0
                    shadowBlur: 0.6
                    blurMax: 16
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }

                Text {
                    x: 10
                    y: 8
                    text: "UP"
                    color: root.vfd
                    font.family: Theme.font.family
                    font.pixelSize: 10
                    font.bold: true
                }

                Row {
                    id: digits

                    x: 36
                    anchors.verticalCenter: parent.verticalCenter
                    height: 34
                    spacing: 6

                    Segment7 { width: 18; height: parent.height; color: root.vfd; digit: uptime.hours >= 100 ? Math.floor(uptime.hours / 100) % 10 : -1 }
                    Segment7 { width: 18; height: parent.height; color: root.vfd; digit: uptime.hours >= 10 ? Math.floor(uptime.hours / 10) % 10 : -1 }
                    Segment7 { width: 18; height: parent.height; color: root.vfd; digit: uptime.hours % 10 }
                    Item {
                        width: 6
                        height: parent.height

                        Repeater {
                            model: [0.3, 0.7]

                            Rectangle {
                                required property real modelData

                                y: parent.height * modelData - 3
                                width: 6
                                height: 6
                                radius: 3
                                color: root.vfd
                            }
                        }
                    }
                    Segment7 { width: 18; height: parent.height; color: root.vfd; digit: Math.floor(uptime.minutes / 10) }
                    Segment7 { width: 18; height: parent.height; color: root.vfd; digit: uptime.minutes % 10 }
                }
            }

            // The mesh.
            Image {
                anchors {
                    fill: parent
                    margins: 3
                }
                source: Qt.resolvedUrl("grille.png")
                fillMode: Image.Tile
                opacity: 0.35
            }
            Gloss {
                anchors {
                    fill: parent
                    margins: 1
                }
                roundness: tube.r
            }
        }
    }

    // The room darkening behind the doors as they close.
    Rectangle {
        anchors.fill: parent
        color: Theme.palette.shadow
        opacity: 0.6 * root.shut
    }

    Item {
        id: stage

        width: root.width
        height: root.height
        y: root.jolt * 7

        // The left door, with lock and shutdown, and the uptime.
        Item {
            id: leftDoor

            x: -width * (1 - root.shut)
            width: root.width / 2 + root.depth / 2
            height: root.height

            Metal {
                width: parent.width - root.edgeWidth
                height: parent.height
                roundness: 0
                tint: root.steel
            }
            Strip {
                x: parent.width - root.edgeWidth
                width: root.strip
                height: parent.height
            }
            Band {
                x: parent.width - width
                edge: "right"
                length: parent.height
            }

            Uptime {
                x: 70
                y: 70
            }

            Repeater {
                id: leftKeys

                model: [0, 1]

                Button {
                    x: leftDoor.width - root.edgeWidth - root.seamGap - width - (1 - slot) * (width + root.gap)
                    y: (root.height - height) / 2
                }
            }
        }

        // The right door, with reboot and sleep, and how to drive it. Its
        // teeth sit half a tooth along, in the left door's notches.
        Item {
            id: rightDoor

            x: root.width - width * root.shut
            width: root.width / 2 + root.depth / 2
            height: root.height

            Metal {
                x: root.edgeWidth
                width: parent.width - root.edgeWidth
                height: parent.height
                roundness: 0
                tint: root.steel
            }
            Strip {
                x: root.band + root.depth
                width: root.strip
                height: parent.height
            }
            Band {
                edge: "left"
                length: parent.height
                phase: root.period / 2
            }

            Repeater {
                id: rightKeys

                model: [2, 3]

                Button {
                    x: root.edgeWidth + root.seamGap + (slot - 2) * (width + root.gap)
                    y: (root.height - height) / 2
                }
            }

            Row {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    rightMargin: 70
                    bottomMargin: 70
                }
                spacing: 14

                Repeater {
                    model: ["1-4 select", "↵ confirm", "esc cancel"]

                    Legend {
                        required property string modelData

                        text: modelData
                        size: 12
                    }
                }
            }
        }

        // The top door, coming down while an action is armed, toothed along
        // its leading edge.
        Item {
            id: topDoor

            y: -height * (1 - root.lid)
            width: root.width
            height: root.height + root.depth
            visible: root.lid > 0

            RectangularShadow {
                x: 0
                y: parent.height - root.depth - 20
                width: parent.width
                height: 20
                offset.y: 14
                blur: 30
                color: Qt.alpha("black", 0.8)
            }
            Metal {
                width: parent.width
                height: parent.height - root.edgeWidth
                roundness: 0
                tint: root.steel
            }
            Strip {
                y: parent.height - root.edgeWidth
                width: parent.width
                height: root.strip
                vertical: false
            }
            Band {
                y: parent.height - height
                edge: "bottom"
                length: parent.width
            }
        }
    }
}
