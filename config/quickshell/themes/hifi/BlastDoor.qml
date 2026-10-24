import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.core

// A steel blast door, as on the session screen: its plate, a riveted strip
// of brighter steel, and the hazard-striped band whose toothed edge faces
// `edge` ("right", "left" or "bottom"); `phase` shifts the teeth along, so
// two doors can mesh. What's mounted on it goes in as children, placed in
// the door's own coordinates.
Item {
    id: door

    property string edge: "right"
    property real phase: 0
    default property alias content: mount.data

    readonly property color steel: "#3a3c42"
    readonly property color hazard: Theme.values.display?.hazard ?? Theme.palette.warn
    // The toothed edge: teeth `depth` deep, one every `period`, with sloped
    // flanks `slope` long; the hazard band behind it is `band` wide at a
    // notch, with a riveted steel strip `strip` wide behind that.
    readonly property real depth: 70
    readonly property real period: 260
    readonly property real slope: 40
    readonly property real band: 90
    readonly property real strip: 54
    // How far in from its edge the plate begins.
    readonly property real edgeWidth: band + depth + strip
    readonly property bool across: edge === "bottom"

    Metal {
        x: door.edge === "left" ? door.edgeWidth : 0
        width: door.across ? parent.width : parent.width - door.edgeWidth
        height: door.across ? parent.height - door.edgeWidth : parent.height
        roundness: 0
        tint: door.steel
    }
    Strip {
        x: door.edge === "right" ? parent.width - door.edgeWidth : door.edge === "left" ? door.band + door.depth : 0
        y: door.across ? parent.height - door.edgeWidth : 0
        width: door.across ? parent.width : door.strip
        height: door.across ? door.strip : parent.height
        vertical: !door.across
    }
    Band {
        x: door.edge === "right" ? parent.width - width : 0
        y: door.across ? parent.height - height : 0
        edge: door.edge
        length: door.across ? parent.width : parent.height
        phase: door.phase
    }
    Item {
        id: mount

        anchors.fill: parent
    }

    component Band: Item {
        id: band

        property string edge: "right"
        property real length
        property real phase: 0
        readonly property bool across: edge === "bottom"
        readonly property real thickness: door.band + door.depth

        // A point `a` along the edge and `c` across it (0 = the inner side).
        function at(a: real, c: real): point {
            return edge === "right" ? Qt.point(c, a) : edge === "left" ? Qt.point(thickness - c, a) : Qt.point(a, c);
        }
        // The toothed edge, from one end to the other.
        function teeth(): var {
            const p = door.period, s = door.slope, flat = p / 2 - s;
            const tip = thickness, notch = thickness - door.depth;
            const out = [];
            for (let base = -phase - p; base < length + p; base += p)
                out.push(at(base, tip), at(base + flat, tip), at(base + flat + s, notch), at(base + 2 * flat + s, notch));
            return out;
        }
        function outline(): var {
            return [at(-2 * door.period, 0), ...teeth(), at(length + 2 * door.period, 0), at(-2 * door.period, 0)];
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
                    GradientStop { position: 0; color: Qt.darker(door.hazard, 1.2) }
                    GradientStop { position: 1; color: Qt.lighter(door.hazard, 1.05) }
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
            GradientStop { position: 0; color: Qt.lighter(door.steel, 2.1) }
            GradientStop { position: 1; color: Qt.darker(door.steel, 1.4) }
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
            tint: Qt.lighter(door.steel, 1.35)
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
}
