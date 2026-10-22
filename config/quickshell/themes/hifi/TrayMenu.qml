import QtQuick
import QtQuick.Shapes
import qs.core
import qs.modules.tray as M

// The plug's cable, pulled down out of the panel, with its tag: a cable tag
// wrapped round it, its white flap written up with what the app offers.
// The cable is the color of the app's icon. It swings a little as it comes
// down, and goes back up into the panel when done.
//
// On the flap: the app's name, then a line per entry; tick boxes for the
// ones that toggle (ticked in pen), circles for the ones to pick one of
// (filled in), rules between groups, faint print for what can't be used, ›
// for more. The line under the hand (or the keys) gets a highlighter stroke.
// More flips the tag over: its back has the rest, with ← BACK at the top.
Item {
    id: root

    required property M.TrayPanel control

    readonly property real flapWidth: 250
    readonly property real line: 24
    // The jack, behind the middle of the panel (the drop's padding above us).
    readonly property real jack: -(Theme.barHeight / 2 + 14)
    readonly property real cableLength: 36
    readonly property color ink: "#25262b"
    readonly property color penBlue: "#2346a8"
    // The cable's color: the icon's, once it's been looked at; until then (or
    // if it can't be), one made up from the app's name.
    property var colors: ({})
    readonly property color cable: colors[control.icon] ?? fallbackColor(control.title)

    // Down out of the panel (0-1), and the swing it comes down with.
    property real out: 0
    property real swing: 0
    // The tag flipping over to another menu: 180 its back, 0 its front.
    property real flip: 0
    property int depth: 0

    implicitWidth: flapWidth + 40
    implicitHeight: cableLength + 22 + flap.height + 20

    function fallbackColor(name: string): color {
        let h = 0;
        for (const c of name ?? "")
            h = (h * 31 + c.charCodeAt(0)) >>> 0;
        return Qt.hsla((h % 360) / 360, 0.45, 0.5, 1);
    }

    Connections {
        target: root.control

        function onOpenChanged(): void {
            if (root.control.open) {
                takeIn.stop();
                pullOut.restart();
            } else {
                pullOut.stop();
                takeIn.restart();
            }
        }
        function onStackChanged(): void {
            if (root.control.stack.length !== root.depth) {
                root.depth = root.control.stack.length;
                turnOver.restart();
            }
        }
    }
    // Pulled down, swinging to a stop.
    ParallelAnimation {
        id: pullOut

        NumberAnimation { target: root; property: "out"; from: 0; to: 1; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
        NumberAnimation { target: root; property: "swing"; from: 7; to: 0; duration: 1200; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.35 }
    }
    // Back up into the panel.
    NumberAnimation {
        id: takeIn

        target: root
        property: "out"
        to: 0
        duration: 220
        easing.type: Easing.InCubic
    }
    NumberAnimation {
        id: turnOver

        target: root
        property: "flip"
        from: 180
        to: 0
        duration: 300
        easing.type: Easing.OutCubic
    }

    // Looks at the icon and takes its strongest color for the cable: the
    // average of its pixels, weighted toward the saturated, opaque ones.
    Canvas {
        id: sampler

        property string source: root.control.icon

        width: 24
        height: 24
        visible: false
        onSourceChanged: if (source && !(source in root.colors)) loadImage(source)
        onImageLoaded: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            if (!isImageLoaded(source))
                return;
            ctx.clearRect(0, 0, width, height);
            ctx.drawImage(source, 0, 0, width, height);
            const px = ctx.getImageData(0, 0, width, height).data;
            let r = 0, g = 0, b = 0, w = 0;
            for (let i = 0; i < px.length; i += 4) {
                const max = Math.max(px[i], px[i + 1], px[i + 2]), min = Math.min(px[i], px[i + 1], px[i + 2]);
                const weight = (px[i + 3] / 255) * (0.15 + (max - min) / 255);
                r += px[i] * weight;
                g += px[i + 1] * weight;
                b += px[i + 2] * weight;
                w += weight;
            }
            if (w > 0) {
                const next = Object.assign({}, root.colors);
                next[source] = Qt.rgba(r / w / 255, g / w / 255, b / w / 255, 1);
                root.colors = next;
            }
        }
    }

    Item {
        id: hanging

        x: 20
        width: root.flapWidth
        height: root.height
        // Pulled out of the panel: up behind it until it's out.
        transform: [
            Translate {
                y: -(1 - root.out) * (root.cableLength + 22 + flap.height + 40)
            },
            Rotation {
                origin.x: root.flapWidth / 2
                origin.y: root.jack
                angle: root.swing
            }
        ]

        // The cable, out of the jack behind the panel down to the tag.
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: Qt.darker(root.cable, 1.8)
                strokeWidth: 8
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: root.flapWidth / 2
                startY: root.jack

                PathLine { x: root.flapWidth / 2; y: root.cableLength + 22 }
            }
            ShapePath {
                strokeColor: root.cable
                strokeWidth: 6
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: root.flapWidth / 2
                startY: root.jack

                PathLine { x: root.flapWidth / 2; y: root.cableLength + 22 }
            }
            ShapePath {
                strokeColor: Qt.alpha(Qt.lighter(root.cable, 1.7), 0.6)
                strokeWidth: 1.5
                fillColor: "transparent"
                startX: root.flapWidth / 2 - 1.5
                startY: root.jack

                PathLine { x: root.flapWidth / 2 - 1.5; y: root.cableLength + 22 }
            }
        }

        // The tag: wrapped round the cable, the flap hanging from it.
        Rectangle {
            id: wrap

            x: root.flapWidth / 2 - width / 2
            y: root.cableLength
            width: 26
            height: 24
            radius: 4
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#d9d6cc" }
                GradientStop { position: 0.5; color: "#fbfaf6" }
                GradientStop { position: 1; color: "#cbc8be" }
            }
            border.width: 1
            border.color: "#a9a69c"
        }
        Item {
            id: flap

            y: root.cableLength + 22
            width: root.flapWidth
            height: Math.min(page.implicitHeight + 20, 520)
            transform: Rotation {
                origin.x: flap.width / 2
                axis { x: 0; y: 1; z: 0 }
                angle: root.flip
            }

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: root.flip > 90 ? "#efeee8" : "#fbfaf6"
                border.width: 1
                border.color: "#c3c0b6"
            }
            // Its edge in the cable's color, where it's printed for it.
            Rectangle {
                x: 1
                y: 1
                width: parent.width - 2
                height: 5
                topLeftRadius: 5
                topRightRadius: 5
                color: root.cable
                opacity: root.flip > 90 ? 0.4 : 1
            }

            Flickable {
                anchors {
                    fill: parent
                    margins: 10
                    topMargin: 12
                }
                contentHeight: page.implicitHeight
                clip: true
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                visible: root.flip < 90

                Column {
                    id: page

                    width: parent.width

                    Text {
                        width: parent.width
                        text: root.control.title.toUpperCase()
                        elide: Text.ElideRight
                        color: root.ink
                        font.family: Theme.font.family
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2
                        bottomPadding: 4
                    }
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Qt.alpha(root.ink, 0.5)
                    }
                    Item {
                        width: 1
                        height: 4
                    }

                    // Back, inside a submenu.
                    Item {
                        width: parent.width
                        height: root.line
                        visible: root.control.stack.length > 0

                        Text {
                            x: 4
                            anchors.verticalCenter: parent.verticalCenter
                            text: "← BACK"
                            color: root.penBlue
                            font.family: Theme.font.family
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.5
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.control.back()
                        }
                    }
                    Text {
                        x: 4
                        height: root.line
                        verticalAlignment: Text.AlignVCenter
                        text: "loading..."
                        color: Qt.alpha(root.ink, 0.5)
                        font.family: Theme.font.family
                        font.pixelSize: 11
                        font.italic: true
                        visible: root.control.entries.length === 0
                    }

                    Repeater {
                        model: root.control.entryModel

                        Item {
                            id: entry

                            required property var modelData
                            required property int index
                            readonly property bool here: root.control.highlighted === index
                            readonly property int kind: modelData.buttonType  // 0 none, 1 check, 2 radio
                            readonly property bool on: modelData.checkState === Qt.Checked

                            width: page.width
                            height: modelData.isSeparator ? 9 : root.line

                            // A rule between groups.
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 1
                                color: Qt.alpha(root.ink, 0.3)
                                visible: entry.modelData.isSeparator
                            }

                            Item {
                                anchors.fill: parent
                                visible: !entry.modelData.isSeparator
                                opacity: entry.modelData.enabled ? 1 : 0.35

                                // The highlighter stroke under the hand.
                                Rectangle {
                                    x: -2
                                    y: 4
                                    width: parent.width + 4
                                    height: parent.height - 8
                                    radius: 3
                                    rotation: -0.6
                                    color: Qt.alpha("#ffe14a", 0.55)
                                    visible: entry.here
                                }
                                // A tick box, or a circle to fill in.
                                Rectangle {
                                    x: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 11
                                    height: 11
                                    radius: entry.kind === 2 ? 5.5 : 1
                                    color: "transparent"
                                    border.width: 1
                                    border.color: Qt.alpha(root.ink, 0.7)
                                    visible: entry.kind !== 0

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 5
                                        height: 5
                                        radius: 2.5
                                        color: root.penBlue
                                        visible: entry.kind === 2 && entry.on
                                    }
                                }
                                // The tick, in pen.
                                Shape {
                                    x: 4
                                    y: (parent.height - 11) / 2
                                    width: 14
                                    height: 12
                                    visible: entry.kind === 1 && entry.on
                                    preferredRendererType: Shape.CurveRenderer

                                    ShapePath {
                                        strokeColor: root.penBlue
                                        strokeWidth: 2
                                        fillColor: "transparent"
                                        capStyle: ShapePath.RoundCap
                                        joinStyle: ShapePath.RoundJoin
                                        startX: 2
                                        startY: 6

                                        PathLine { x: 5; y: 10 }
                                        PathLine { x: 13; y: -1 }
                                    }
                                }
                                Text {
                                    x: entry.kind !== 0 ? 24 : 4
                                    width: parent.width - x - 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.control.label(entry.modelData)
                                    elide: Text.ElideRight
                                    color: root.ink
                                    font.family: Theme.font.family
                                    font.pixelSize: 12
                                }
                                Text {
                                    anchors {
                                        right: parent.right
                                        rightMargin: 2
                                        verticalCenter: parent.verticalCenter
                                    }
                                    text: "›"
                                    color: Qt.alpha(root.ink, 0.6)
                                    font.family: Theme.font.family
                                    font.pixelSize: 16
                                    font.bold: true
                                    visible: entry.modelData.hasChildren
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: entry.modelData.enabled
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.control.highlighted = entry.index
                                    onClicked: root.control.activate(entry.modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
