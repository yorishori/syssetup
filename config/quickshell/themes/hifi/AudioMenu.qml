import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.components as C
import qs.core
import qs.modules.audio as M

// A DJ set in a drawer: a turntable and a mixer.
//
// The record on the turntable is the player, its app's icon in the middle;
// it turns slowly while it plays. The tonearm runs along the bottom of the
// record from its pivot, the headshell hooking up onto the grooves. Beside
// the platter, the turntable's blue screen shows the player, the track and
// how far it's got (dark when there's no player), with the SOURCE switch
// under it and the transport keys set into the plinth below. Switching
// players lifts the arm toward you, turns the record over to the new app and
// drops the arm back.
//
// The mixer: MASTER (output) and MIC (input) as rows, each with its screen,
// a device selector, a MODE selector for the profile, a horizontal fader and
// a mute key; then a channel per app with an upright fader. The faders are
// analog: a printed scale and a square cap.
Item {
    id: root

    required property M.AudioPanel control

    implicitWidth: Math.max(deck.implicitWidth, mixer.implicitWidth)
    implicitHeight: column.implicitHeight

    // A click-stop rotary selector: `count` positions printed round it, the
    // pointer on `index`. Click for the next, right click for the previous,
    // or scroll. Dead with one position or none.
    component Selector: Item {
        id: selector

        property int count: 0
        property int index: 0
        property string legend
        readonly property bool live: count > 1
        property real angle: count > 1 ? -135 + 270 * index / (count - 1) : 0

        signal stepped(int step)

        width: 52
        height: 62

        Behavior on angle {
            SpringAnimation { spring: 6; damping: 0.45; epsilon: 0.2 }
        }

        // The positions.
        Repeater {
            model: Math.max(selector.count, 1)

            Rectangle {
                required property int index
                readonly property real a: (selector.count > 1 ? -135 + 270 * index / (selector.count - 1) : 0) * Math.PI / 180

                x: selector.width / 2 + Math.sin(a) * 22 - 1.5
                y: 24 - Math.cos(a) * 22 - 1.5
                width: 3
                height: 3
                radius: 1.5
                color: Qt.alpha(Theme.palette.fg, index === selector.index ? 0.8 : 0.3)
            }
        }
        // The knob.
        Item {
            x: (selector.width - 30) / 2
            y: 9
            width: 30
            height: 30
            opacity: selector.live ? 1 : 0.5

            RectangularShadow {
                anchors.fill: parent
                radius: width / 2
                offset.y: 2
                blur: 4
                color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
            }
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                border.width: 1
                border.color: Theme.palette.shadow
                gradient: Gradient {
                    GradientStop { position: 0; color: knobArea.containsMouse && selector.live ? Qt.lighter(Theme.palette.surface, 1.6) : Qt.lighter(Theme.palette.surface, 1.3) }
                    GradientStop { position: 1; color: Qt.darker(Theme.palette.surface, 1.7) }
                }
            }
            // The pointer, a line across the knob's face.
            Item {
                anchors.fill: parent
                rotation: selector.angle

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 3
                    width: 3
                    height: 11
                    radius: 1.5
                    color: Theme.palette.fg
                }
            }
        }
        Legend {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: selector.legend
            size: 8
        }

        MouseArea {
            id: knobArea

            anchors.fill: parent
            enabled: selector.live
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => selector.stepped(mouse.button === Qt.RightButton ? -1 : 1)
            onWheel: wheel => selector.stepped(wheel.angleDelta.y > 0 ? 1 : -1)
        }
    }

    // A small two-line display.
    component Display: Item {
        id: display

        property string line1
        property string line2

        width: 96
        height: 34

        Well {
            id: glass

            anchors.fill: parent
            roundness: 3
            fill: Qt.tint("#050807", Qt.alpha(Theme.palette.accent, 0.04))
        }
        Column {
            anchors {
                fill: parent
                margins: 5
            }
            spacing: 1

            C.StyledText {
                width: parent.width
                text: display.line1
                caps: true
                elide: Text.ElideRight
                color: Theme.palette.accent
                glow: true
                font.pixelSize: 10
                font.bold: true
            }
            C.StyledText {
                width: parent.width
                text: display.line2
                caps: true
                elide: Text.ElideRight
                color: Qt.alpha(Theme.palette.accent, 0.7)
                font.pixelSize: 9
            }
        }
        Gloss {
            anchors {
                fill: parent
                margins: 1
            }
            roundness: glass.r
        }
    }

    // The mute key and its LED.
    component Mute: Row {
        id: mute

        required property M.AudioPanel panel
        property var nodes: []
        readonly property bool muted: nodes[0]?.audio?.muted ?? false

        spacing: 8

        Led {
            anchors.verticalCenter: parent.verticalCenter
            size: 8
            on: mute.muted
            color: Theme.palette.error
        }
        C.IconButton {
            size: 28
            icon: mute.muted ? "\u{F075F}" : "\u{F057E}"
            iconColor: mute.muted ? Theme.palette.error : Theme.palette.fg
            onClicked: mute.panel.setMuted(mute.nodes, !mute.muted)
        }
    }

    // MASTER or MIC: its name, then its screen, a device selector, the
    // profile's MODE selector, a horizontal fader with its scale printed
    // above it, and the mute key.
    component Bus: Column {
        id: bus

        required property M.AudioPanel panel
        required property PwNode node
        required property var devices
        required property var profiles
        property string name
        property string deviceLegend

        signal pick(var device)

        readonly property real volume: node?.audio?.volume ?? 0

        spacing: 6

        Legend {
            text: bus.name
        }
        Item {
            width: row.width + 24
            height: row.height + 16

            Well {
                anchors.fill: parent
                roundness: 4
                fill: Qt.darker(Theme.palette.bg, 1.25)
            }
            Row {
                id: row

                x: 12
                y: 8
                spacing: 12

                Display {
                    anchors.verticalCenter: parent.verticalCenter
                    line1: bus.panel.nodeName(bus.node)
                    line2: bus.profiles.switching ? "switching..." : bus.profiles.current?.label ?? ""
                }
                Selector {
                    legend: bus.deviceLegend
                    count: bus.devices.length
                    index: bus.devices.indexOf(bus.node)
                    onStepped: step => bus.pick(bus.devices[(index + step + count) % count])
                }
                Selector {
                    legend: "mode"
                    count: bus.profiles.list.length
                    index: bus.profiles.list.findIndex(p => p.current)
                    onStepped: step => bus.profiles.set(bus.profiles.list[(index + step + count) % count].index)
                }
                // The fader, its scale printed above.
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 196
                    height: 44

                    Repeater {
                        model: 11

                        Item {
                            required property int index
                            readonly property bool major: index % 2 === 0

                            x: 6 + index * (184 / 10) - width / 2
                            width: 14
                            height: 22

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: parent.index
                                visible: parent.major
                                color: Qt.alpha(Theme.palette.fg, 0.55)
                                font.family: Theme.font.family
                                font.pixelSize: 8
                            }
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                width: 1
                                height: parent.major ? 7 : 4
                                color: Qt.alpha(Theme.palette.fg, parent.major ? 0.5 : 0.3)
                            }
                        }
                    }
                    C.Meter {
                        x: 6
                        y: 28
                        width: 184
                        height: 12
                        value: bus.volume
                        color: "transparent"
                        onMoved: value => bus.panel.setLevel([bus.node], value)
                    }
                }
                Mute {
                    anchors.verticalCenter: parent.verticalCenter
                    panel: bus.panel
                    nodes: [bus.node]
                }
            }
        }
    }

    // An app's channel: its name, an upright fader with its scale, the mute.
    component Channel: Item {
        id: channel

        required property M.AudioPanel panel
        property var nodes: []
        property string name
        readonly property real volume: nodes[0]?.audio?.volume ?? 0

        implicitWidth: 80
        implicitHeight: strip.implicitHeight + 24

        Well {
            anchors.fill: parent
            roundness: 4
            fill: Qt.darker(Theme.palette.bg, 1.25)
        }
        Column {
            id: strip

            anchors.horizontalCenter: parent.horizontalCenter
            y: 12
            spacing: 12

            Legend {
                anchors.horizontalCenter: parent.horizontalCenter
                text: channel.name.slice(0, 9)
            }

            // The fader, with its scale printed beside it.
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 60
                height: 150

                Repeater {
                    model: 11

                    Item {
                        required property int index
                        readonly property bool major: index % 2 === 0

                        y: 6 + (10 - index) * (138 / 10) - height / 2
                        width: 22
                        height: 10

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.index
                            visible: parent.major
                            color: Qt.alpha(Theme.palette.fg, 0.55)
                            font.family: Theme.font.family
                            font.pixelSize: 8
                        }
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.major ? 7 : 4
                            height: 1
                            color: Qt.alpha(Theme.palette.fg, parent.major ? 0.5 : 0.3)
                        }
                    }
                }
                C.Meter {
                    x: 32
                    y: 6
                    width: 14
                    height: 138
                    vertical: true
                    value: channel.volume
                    color: "transparent"
                    onMoved: value => channel.panel.setLevel(channel.nodes, value)
                }
            }

            Mute {
                anchors.horizontalCenter: parent.horizontalCenter
                panel: channel.panel
                nodes: channel.nodes
            }
        }
    }

    // The tonearm, seen from above: the tube from the pivot, the headshell
    // on its neck hooking up onto the record, the cartridge and the finger
    // lift on it. Solid parts, lit from above.
    component ArmShape: Item {
        // The tube: a polished cylinder, its highlight along the top.
        Rectangle {
            y: -4
            width: deck.tube
            height: 8
            radius: 4
            gradient: Gradient {
                GradientStop { position: 0; color: "#6d6e72" }
                GradientStop { position: 0.25; color: "#f6f6f4" }
                GradientStop { position: 0.4; color: "#d9dadc" }
                GradientStop { position: 0.75; color: "#7c7d81" }
                GradientStop { position: 1; color: "#3b3c40" }
            }
        }
        Item {
            x: deck.tube - 4
            rotation: -52

            // The neck.
            Rectangle {
                y: -3.5
                width: 48
                height: 7
                radius: 3.5
                gradient: Gradient {
                    GradientStop { position: 0; color: "#6d6e72" }
                    GradientStop { position: 0.3; color: "#f6f6f4" }
                    GradientStop { position: 0.75; color: "#7c7d81" }
                    GradientStop { position: 1; color: "#3b3c40" }
                }
            }
            // The headshell, bevelled, the cartridge under it.
            Rectangle {
                x: 40
                y: -11
                width: 32
                height: 22
                radius: 3
                border.width: 1
                border.color: "black"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#5a5b61" }
                    GradientStop { position: 0.15; color: "#3a3b40" }
                    GradientStop { position: 1; color: "#141517" }
                }

                Rectangle {
                    x: 2
                    y: 1
                    width: parent.width - 4
                    height: 1
                    color: Qt.alpha("white", 0.3)
                }
                Rectangle {
                    x: 9
                    y: 5
                    width: 16
                    height: 12
                    radius: 2
                    border.width: 1
                    border.color: Qt.darker(Theme.palette.error, 2.5)
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.lighter(Theme.palette.error, 1.15) }
                        GradientStop { position: 1; color: Qt.darker(Theme.palette.error, 1.6) }
                    }
                }
            }
            // The finger lift.
            Rectangle {
                x: 70
                y: -18
                width: 5
                height: 16
                radius: 2.5
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#f2f2f0" }
                    GradientStop { position: 1; color: "#6d6e72" }
                }
            }
        }
    }

    // What's on the turntable: `shown` is its player; it follows the current
    // one, swapping records when that changes.
    property MprisPlayer shown: null
    property real armLift: 0  // 0 = on the record, 1 = up toward you
    property real flip: 0     // the record turning over, -90 to 90 degrees

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

        width: parent.width
        spacing: 14

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

            // The plinth.
            Rectangle {
                anchors.fill: parent
                radius: 6
                border.width: 1
                border.color: "black"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#232428" }
                    GradientStop { position: 1; color: "#141517" }
                }
            }

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
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1
                    colorizationColor: "black"
                    brightness: -1
                    blurEnabled: true
                    blur: 0.3 + 0.5 * root.armLift
                    blurMax: 24
                }

                ArmShape {
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
            ArmShape {
                x: deck.pivot.x
                y: deck.pivot.y

                transform: [
                    Rotation {
                        axis { x: 0; y: 1; z: 0 }
                        angle: -28 * root.armLift
                        distanceToPlane: 420
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

            // The blue screen: the player, the track and how far it's got.
            // Dark glass with nothing on it when there's no player.
            Item {
                id: screen

                readonly property bool on: root.control.player !== null
                readonly property color ink: "#e6efff"

                x: deck.side
                y: 26
                width: deck.width - deck.side - 24
                height: 92

                Well {
                    id: bezel

                    anchors.fill: parent
                    roundness: 4
                    fill: screen.on ? "#1f4fbf" : "#0b1020"
                }
                // The backlight, brighter in the middle.
                Rectangle {
                    anchors {
                        fill: parent
                        margins: 2
                    }
                    radius: 3
                    visible: screen.on
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#2a63db" }
                        GradientStop { position: 0.5; color: "#3570e6" }
                        GradientStop { position: 1; color: "#1d4bb3" }
                    }
                }
                Column {
                    anchors {
                        fill: parent
                        margins: 9
                    }
                    spacing: 3
                    visible: screen.on

                    Row {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: root.control.playing ? "▶" : "❙❙"
                            color: screen.ink
                            font.family: Theme.font.family
                            font.pixelSize: 9
                        }
                        Text {
                            width: parent.width - x
                            text: (root.control.player?.identity ?? "").toUpperCase()
                            elide: Text.ElideRight
                            color: Qt.alpha(screen.ink, 0.75)
                            font.family: Theme.font.family
                            font.pixelSize: 9
                            font.letterSpacing: 1
                        }
                    }
                    Text {
                        width: parent.width
                        text: root.control.title || root.control.player?.identity || ""
                        elide: Text.ElideRight
                        color: screen.ink
                        font.family: Theme.font.family
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Text {
                        width: parent.width
                        text: root.control.artist
                        elide: Text.ElideRight
                        color: Qt.alpha(screen.ink, 0.8)
                        font.family: Theme.font.family
                        font.pixelSize: 11
                    }
                    // How far the track has got.
                    Item {
                        width: parent.width
                        height: 10
                        visible: root.control.progress >= 0

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 4
                            color: Qt.alpha(screen.ink, 0.25)
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * Math.max(0, root.control.progress)
                            height: 4
                            color: screen.ink
                        }
                    }
                }
                // The LCD's pixel grid.
                Image {
                    anchors {
                        fill: parent
                        margins: 2
                    }
                    source: Qt.resolvedUrl("grille.png")
                    fillMode: Image.Tile
                    opacity: screen.on ? 0.12 : 0
                }
                Gloss {
                    anchors {
                        fill: parent
                        margins: 1
                    }
                    roundness: bezel.r
                }
            }

            // The SOURCE switch, under the screen.
            Paddle {
                x: screen.x + (screen.width - width) / 2
                y: screen.y + screen.height + 16
                live: root.control.players.length > 1
                onFlicked: step => root.control.cycle(step)
            }

            // The transport keys, set into a recess in the plinth.
            Item {
                x: screen.x
                y: deck.height - height - 24
                width: screen.width
                height: 66

                Well {
                    anchors.fill: parent
                    roundness: 5
                    fill: "#0e0f11"
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

            Bus {
                panel: root.control
                node: root.control.output
                devices: root.control.outputs
                profiles: root.control.outputProfiles
                name: "master"
                deviceLegend: "out"
                onPick: device => root.control.setDefaultOutput(device)
            }
            Bus {
                panel: root.control
                node: root.control.input
                devices: root.control.inputs
                profiles: root.control.inputProfiles
                name: "mic"
                deviceLegend: "in"
                onPick: device => root.control.setDefaultInput(device)
            }

            // A channel per app.
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                spacing: 8

                Repeater {
                    model: root.control.apps

                    Channel {
                        required property var modelData

                        panel: root.control
                        nodes: modelData.nodes
                        name: modelData.name
                    }
                }
                C.Placeholder {
                    text: "-- no apps playing --"
                    visible: root.control.apps.length === 0
                }
            }
        }
    }
}
