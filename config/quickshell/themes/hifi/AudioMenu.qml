import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.components as C
import qs.core
import qs.modules.audio as M

// A DJ set in a drawer: a turntable and a mixer on one faceplate, their
// sections framed in silkscreened lines.
//
// The record on the turntable is the player, its app's icon in the middle;
// it turns slowly while it plays. The tonearm runs along the bottom of the
// record from its pivot, the headshell hooking up onto the grooves, and it
// creeps in from the record's edge toward its label as the track goes on
// (it rests halfway when the player doesn't say how far it's got). Beside the platter, the deck's
// screen shows the track (blank with no player), with the SOURCE switch
// under it and the transport keys set into the faceplate below. Switching
// players lifts the arm toward you, turns the record over to the new app and
// drops the arm back.
//
// The mixer: the output and the input as rows, each with its screen, a
// device selector, a MODE selector for the profile, a horizontal fader and a
// mute key; then a channel per app with an upright fader. The faders are
// analog: a printed scale and a square cap.
Item {
    id: root

    required property M.AudioPanel control

    // The faceplate's silkscreen.
    readonly property color silk: Theme.values.display?.silk ?? Theme.palette.dim
    readonly property real margin: 12

    implicitWidth: Math.max(deck.implicitWidth, mixer.implicitWidth) + 2 * margin
    implicitHeight: column.implicitHeight + 2 * margin

    // What's on the turntable: `shown` is its player; it follows the current
    // one, swapping records when that changes.
    property MprisPlayer shown: null
    property real armLift: 0  // 0 = on the record, 1 = up toward you
    property real flip: 0     // the record turning over, -90 to 90 degrees
    // How far the arm has swung in: 21 degrees takes the needle from the
    // record's edge, at the start of the track, to its innermost groove, just
    // outside the label, at its end. Halfway when the track's progress is
    // unknown.
    property real armSwing: -21 * (root.control.progress < 0 ? 0.5 : root.control.progress)

    Behavior on armSwing {
        NumberAnimation { duration: 900 }
    }

    readonly property string shownIcon: shown ? root.control.iconFor(shown) : ""

    Component.onCompleted: shown = control.player
    Connections {
        target: root.control

        function onPlayerChanged(): void {
            if (root.control.player === root.shown)
                return;
            if (!root.shown || !root.control.player) {
                root.shown = root.control.player;
                return;
            }
            swap.restart();
        }
    }
    // The arm up toward you, the record over to the next, the arm back down.
    SequentialAnimation {
        id: swap

        NumberAnimation { target: root; property: "armLift"; to: 1; duration: 280; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "flip"; to: 90; duration: 180; easing.type: Easing.InCubic }
        ScriptAction {
            script: {
                root.shown = root.control.player;
                root.flip = -90;
            }
        }
        NumberAnimation { target: root; property: "flip"; to: 0; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "armLift"; to: 0; duration: 420; easing.type: Easing.OutBounce }
    }

    ColumnLayout {
        id: column

        x: root.margin
        y: root.margin
        width: parent.width - 2 * root.margin
        spacing: 16

        // ── The turntable ────────────────────────────────────────────────────
        Item {
            id: deck

            readonly property real cx: 180
            readonly property real cy: 152
            readonly property point pivot: Qt.point(56, 298)
            readonly property real tube: 152
            // The side the screen and keys are set into.
            readonly property real side: 380

            Layout.fillWidth: true
            implicitWidth: 560
            implicitHeight: 344

            // The platter, its rim lit by a ring of red LEDs.
            Rectangle {
                x: deck.cx - width / 2
                y: deck.cy - height / 2
                width: 270
                height: 270
                radius: width / 2
                border.width: 1
                border.color: "black"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#3c3d42" }
                    GradientStop { position: 1; color: "#1d1e21" }
                }
            }
            Repeater {
                model: 60

                Rectangle {
                    required property int index
                    readonly property real a: index * 6 * Math.PI / 180

                    x: deck.cx + Math.cos(a) * 128 - 2
                    y: deck.cy + Math.sin(a) * 128 - 2
                    width: 4
                    height: 4
                    radius: 2
                    color: Theme.palette.error
                    opacity: 0.85
                }
            }

            // The record.
            Item {
                id: record

                x: deck.cx - width / 2
                y: deck.cy - height / 2
                width: 236
                height: 236
                visible: root.shown !== null

                transform: Rotation {
                    origin.x: record.width / 2
                    origin.y: record.height / 2
                    axis { x: 0; y: 1; z: 0 }
                    angle: root.flip
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "#0c0c0e"
                    border.width: 1
                    border.color: "black"
                }
                // The grooves.
                Repeater {
                    model: 17

                    Rectangle {
                        required property int index
                        readonly property real size: 100 + index * 8

                        x: (record.width - size) / 2
                        y: (record.height - size) / 2
                        width: size
                        height: size
                        radius: size / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.alpha("white", index % 4 === 3 ? 0.03 : 0.07)
                    }
                }
                // The app's icon, as big as the label, turning with the record
                // while it plays.
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 88
                    source: root.shownIcon

                    RotationAnimation on rotation {
                        running: root.control.open
                        paused: running && (!(root.shown?.isPlaying ?? false) || swap.running)
                        from: 0
                        to: 360
                        duration: 5000
                        loops: Animation.Infinite
                    }
                }
                // The spindle.
                Rectangle {
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: 4
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#f2f2f2" }
                        GradientStop { position: 1; color: "#8a8a8a" }
                    }
                }
                // Light lying across the vinyl; it stays put as it turns.
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    rotation: 35
                    gradient: Gradient {
                        GradientStop { position: 0.15; color: "transparent" }
                        GradientStop { position: 0.3; color: Qt.alpha("white", 0.07) }
                        GradientStop { position: 0.42; color: "transparent" }
                        GradientStop { position: 0.6; color: "transparent" }
                        GradientStop { position: 0.72; color: Qt.alpha("white", 0.05) }
                        GradientStop { position: 0.85; color: "transparent" }
                    }
                }
            }

            // The arm's base, set into the plinth.
            Rectangle {
                x: deck.pivot.x - 32
                y: deck.pivot.y - 30
                width: 60
                height: 60
                radius: 8
                border.width: 1
                border.color: "black"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#34353a" }
                    GradientStop { position: 1; color: "#141517" }
                }

                Rectangle {
                    x: 6
                    y: 1
                    width: parent.width - 12
                    height: 1
                    color: Qt.alpha("white", 0.2)
                }
            }

            // The arm's shadow: soft, and further off and fainter the higher
            // the arm is.
            // (In a box that holds it: a layer only draws what's inside its
            // item.)
            Item {
                x: deck.pivot.x + 4 + 12 * root.armLift
                y: deck.pivot.y - 120 + 5 + 18 * root.armLift
                width: deck.tube + 100
                height: 150
                opacity: 0.6 - 0.25 * root.armLift
                transform: Rotation {
                    origin.y: 120
                    angle: root.armSwing
                }
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1
                    colorizationColor: "black"
                    brightness: -1
                    blurEnabled: true
                    blur: 0.3 + 0.5 * root.armLift
                    blurMax: 24
                }

                ToneArm {
                    tube: deck.tube
                    y: 120
                }
            }

            // The counterweight behind the pivot: a ringed cylinder.
            Rectangle {
                x: deck.pivot.x - 52
                y: deck.pivot.y - 13
                width: 34
                height: 26
                radius: 5
                border.width: 1
                border.color: "black"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#55565b" }
                    GradientStop { position: 0.3; color: "#b4b5b8" }
                    GradientStop { position: 0.7; color: "#3e3f43" }
                    GradientStop { position: 1; color: "#1a1b1d" }
                }

                Repeater {
                    model: 3

                    Rectangle {
                        required property int index

                        x: 8 + index * 8
                        width: 1
                        height: parent.height
                        color: Qt.alpha("black", 0.45)
                    }
                }
            }

            // The arm itself, lifting toward you: it comes closer (larger),
            // and tips a little on its pivot.
            ToneArm {
                tube: deck.tube
                x: deck.pivot.x
                y: deck.pivot.y

                transform: [
                    Rotation {
                        axis { x: 0; y: 1; z: 0 }
                        angle: -28 * root.armLift
                        distanceToPlane: 420
                    },
                    Rotation {
                        angle: root.armSwing
                    },
                    Scale {
                        xScale: 1 + 0.08 * root.armLift
                        yScale: 1 + 0.08 * root.armLift
                    }
                ]
            }

            // The gimbal over the pivot: a bearing housing, its cap on top.
            Item {
                x: deck.pivot.x - 18
                y: deck.pivot.y - 18
                width: 36
                height: 36

                RectangularShadow {
                    anchors.fill: parent
                    radius: width / 2
                    offset.y: 3
                    blur: 6
                    color: Qt.alpha("black", 0.7)
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    border.width: 1
                    border.color: "black"
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#c9cacd" }
                        GradientStop { position: 0.5; color: "#6a6b6f" }
                        GradientStop { position: 1; color: "#26272a" }
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    radius: 10
                    border.width: 1
                    border.color: Qt.alpha("black", 0.6)
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#3a3b40" }
                        GradientStop { position: 1; color: "#8d8e92" }
                    }
                }
                Rectangle {
                    x: 12
                    y: 11
                    width: 6
                    height: 3
                    radius: 1.5
                    color: Qt.alpha("white", 0.5)
                }
            }

            // The deck's controls, a framed section beside the platter: its
            // screen (the track; blank with no player), the SOURCE switch,
            // and the transport keys set into the faceplate.
            SilkFrame {
                x: deck.side - 12
                y: 12
                width: deck.width - deck.side
                height: deck.height - 24
            }
            Readout {
                id: screen

                x: deck.side
                y: 26
                width: deck.width - deck.side - 24
                height: 72
                size: 13
                line1: root.control.player ? root.control.title || root.control.player.identity : ""
                line2: root.control.artist
                line3: root.control.player ? `${root.control.playing ? "\u25B6" : "\u2759\u2759"} ${root.control.player.identity}` : ""
            }

            Paddle {
                x: screen.x + (screen.width - width) / 2
                y: screen.y + screen.height + 22
                live: root.control.players.length > 1
                onFlicked: step => root.control.cycle(step)
            }

            Item {
                x: screen.x
                y: deck.height - height - 26
                width: screen.width
                height: 66

                Well {
                    anchors.fill: parent
                    roundness: 5
                    fill: "#0b0b0c"
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    C.IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 38
                        icon: "\u{F04AE}"
                        enabled: root.control.player !== null
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.control.previous()
                    }
                    C.IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 58
                        size: 48
                        lit: root.control.playing
                        icon: root.control.playing ? "\u{F03E4}" : "\u{F040A}"
                        enabled: root.control.player !== null
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.control.togglePlaying()
                    }
                    C.IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 38
                        icon: "\u{F04AD}"
                        enabled: root.control.player !== null
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.control.next()
                    }
                }
            }
        }

        // ── The mixer ────────────────────────────────────────────────────────
        ColumnLayout {
            id: mixer

            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            AudioBus {
                panel: root.control
                node: root.control.output
                devices: root.control.outputs
                profiles: root.control.outputProfiles
                deviceLegend: "out"
                onPick: device => root.control.setDefaultOutput(device)
            }
            AudioBus {
                panel: root.control
                node: root.control.input
                devices: root.control.inputs
                profiles: root.control.inputProfiles
                deviceLegend: "in"
                onPick: device => root.control.setDefaultInput(device)
            }

            // A channel per app, framed together, a line between each.
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                implicitWidth: apps.width + 16
                implicitHeight: apps.height
                visible: root.control.apps.length > 0

                SilkFrame {
                    anchors.fill: parent
                }
                Row {
                    id: apps

                    x: 8

                    Repeater {
                        model: root.control.apps

                        Row {
                            id: lane

                            required property int index
                            required property var modelData

                            Rectangle {
                                width: 1
                                height: channel.height - 24
                                anchors.verticalCenter: parent.verticalCenter
                                color: Qt.alpha(root.silk, 0.3)
                                visible: lane.index > 0
                            }
                            AudioChannel {
                                id: channel

                                panel: root.control
                                nodes: lane.modelData.nodes
                                name: lane.modelData.name
                            }
                        }
                    }
                }
            }
            C.Placeholder {
                Layout.alignment: Qt.AlignHCenter
                text: "-- no apps playing --"
                visible: root.control.apps.length === 0
            }
        }
    }
}
