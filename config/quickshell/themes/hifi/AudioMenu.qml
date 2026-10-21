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
// The record on the turntable is the player: its app's icon is the record's
// label, and it turns slowly while it plays. The tonearm lies across it with
// the track typed on label tape along it. Switching players lifts the arm and
// swings it off, flips the record over to the new app, and brings the arm
// back down with the new label. Beside it, the transport keys, and the
// source keys to step through the players (dead with only one).
//
// The mixer has a channel for the output (MASTER), the input (MIC) and each
// app: a display, an analog fader with a printed scale and a square cap, and
// a mute key with its LED. MASTER and MIC pick their device with a
// click-stop selector (click or scroll), and their profile with a MODE
// selector when there's a choice; the display shows both.
Item {
    id: root

    required property M.AudioPanel control

    readonly property color labelColor: "#c8683f"

    implicitWidth: 600
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

    // A small two-line display at the top of a channel.
    component Display: Item {
        id: display

        property string line1
        property string line2

        width: 84
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

    // One channel of the mixer: its display, what sits above its fader
    // (`head`), the fader with its scale, the mute key and LED, its name.
    component Channel: Item {
        id: channel

        required property M.AudioPanel panel
        property var nodes: []
        property string name
        property string line1
        property string line2
        default property alias head: headSlot.data
        readonly property PwNode node: nodes[0] ?? null
        readonly property bool muted: node?.audio?.muted ?? false
        readonly property real volume: node?.audio?.volume ?? 0

        width: 100
        height: 360

        Well {
            anchors.fill: parent
            roundness: 4
            fill: Qt.darker(Theme.palette.bg, 1.25)
        }
        Column {
            anchors {
                top: parent.top
                topMargin: 10
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 10

            Display {
                anchors.horizontalCenter: parent.horizontalCenter
                line1: channel.line1
                line2: channel.line2
            }
            Item {
                id: headSlot

                anchors.horizontalCenter: parent.horizontalCenter
                width: childrenRect.width
                height: 62
            }

            // The fader, with its scale printed beside it.
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 64
                height: 150

                Repeater {
                    model: 11

                    Item {
                        required property int index
                        readonly property bool major: index % 2 === 0

                        x: 0
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

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Led {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 8
                    on: channel.muted
                    color: Theme.palette.error
                }
                C.IconButton {
                    size: 28
                    icon: channel.muted ? "\u{F075F}" : "\u{F057E}"
                    iconColor: channel.muted ? Theme.palette.error : Theme.palette.fg
                    onClicked: channel.panel.setMuted(channel.nodes, !channel.muted)
                }
            }
        }
        Legend {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 8
            }
            text: channel.name.slice(0, 10)
        }
    }

    // The record, the arm and what's playing on them. `shown` is the player
    // on the turntable; it follows the current one, swapping records when it
    // changes.
    property MprisPlayer shown: null
    readonly property real parked: 35  // the arm's angle on its rest
    property real armAngle: parked    // 0 = on the record
    property real armLift: 0     // 0 = down, 1 = lifted
    property real flip: 0        // the record turning over, -90 to 90 degrees

    readonly property string shownIcon: shown ? root.control.iconFor(shown) : ""
    readonly property string shownLabel: {
        if (!shown)
            return "";
        const parts = [shown.trackTitle || shown.identity, shown.trackArtist].filter(s => s);
        return parts.join(" · ");
    }

    Component.onCompleted: {
        shown = control.player;
        armAngle = shown ? 0 : parked;
    }
    Connections {
        target: root.control

        function onPlayerChanged(): void {
            if (root.control.player === root.shown)
                return;
            if (!root.shown) {
                root.shown = root.control.player;
                settle.start();
            } else {
                settle.stop();
                swap.start();
            }
        }
    }
    // Arm up and off, the record over to the next.
    SequentialAnimation {
        id: swap

        NumberAnimation { target: root; property: "armLift"; to: 1; duration: 120; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "armAngle"; to: root.parked; duration: 320; easing.type: Easing.InOutCubic }
        NumberAnimation { target: root; property: "flip"; to: 90; duration: 220; easing.type: Easing.InCubic }
        ScriptAction {
            script: {
                root.shown = root.control.player;
                root.flip = -90;
                settle.start();
            }
        }
    }
    // The record down, the arm back on and dropped.
    SequentialAnimation {
        id: settle

        NumberAnimation { target: root; property: "flip"; to: 0; duration: 260; easing.type: Easing.OutCubic }
        ScriptAction {
            script: {
                if (!root.shown)
                    settle.stop();
            }
        }
        NumberAnimation { target: root; property: "armLift"; to: 1; duration: 80 }
        NumberAnimation { target: root; property: "armAngle"; to: 0; duration: 360; easing.type: Easing.InOutCubic }
        NumberAnimation { target: root; property: "armLift"; to: 0; duration: 160; easing.type: Easing.InQuad }
    }

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 14

        // ── The deck ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Item {
                id: deck

                readonly property real cx: 140
                readonly property real cy: 135
                readonly property point pivot: Qt.point(cx + 72 + 190, cy)

                implicitWidth: 440
                implicitHeight: 270

                // The turntable's plinth.
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

                // The platter: a heavy rim with strobe dots, under the record.
                Rectangle {
                    x: deck.cx - width / 2
                    y: deck.cy - height / 2
                    width: 248
                    height: 248
                    radius: width / 2
                    border.width: 1
                    border.color: "black"
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#5a5c62" }
                        GradientStop { position: 1; color: "#2a2b2f" }
                    }
                }
                Repeater {
                    model: 72

                    Rectangle {
                        required property int index
                        readonly property real a: index * 5 * Math.PI / 180

                        x: deck.cx + Math.cos(a) * 119 - 1.5
                        y: deck.cy + Math.sin(a) * 119 - 1.5
                        width: 3
                        height: 3
                        radius: 1.5
                        color: Qt.alpha("#e9e6dc", 0.55)
                    }
                }
                Rectangle {
                    x: deck.cx - width / 2
                    y: deck.cy - height / 2
                    width: 230
                    height: 230
                    radius: width / 2
                    color: "#18191b"
                }

                // The record.
                Item {
                    id: record

                    x: deck.cx - width / 2
                    y: deck.cy - height / 2
                    width: 224
                    height: 224
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
                        model: 16

                        Rectangle {
                            required property int index
                            readonly property real size: 96 + index * 8

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
                    // The label, turning with the record while it plays.
                    Item {
                        anchors.centerIn: parent
                        width: 84
                        height: 84

                        RotationAnimation on rotation {
                            running: root.control.open
                            paused: running && (!(root.shown?.isPlaying ?? false) || swap.running || settle.running)
                            from: 0
                            to: 360
                            duration: 5000
                            loops: Animation.Infinite
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            gradient: Gradient {
                                GradientStop { position: 0; color: Qt.lighter(root.labelColor, 1.1) }
                                GradientStop { position: 1; color: Qt.darker(root.labelColor, 1.15) }
                            }
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 70
                            height: 70
                            radius: 35
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.alpha("black", 0.2)
                        }
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 44
                            source: root.shownIcon
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

                // The arm's rest.
                Rectangle {
                    readonly property real a: root.parked * Math.PI / 180

                    x: deck.pivot.x - Math.cos(a) * 150 - width / 2
                    y: deck.pivot.y - Math.sin(a) * 150 - height / 2
                    width: 14
                    height: 18
                    radius: 3
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.lighter(Theme.palette.border, 1.4) }
                        GradientStop { position: 1; color: Qt.darker(Theme.palette.border, 1.6) }
                    }
                }

                // The tonearm, from its pivot to the needle, lying across the
                // record, the track on tape along it.
                Item {
                    id: arm

                    x: deck.pivot.x
                    y: deck.pivot.y
                    rotation: root.armAngle
                    scale: 1 + 0.05 * root.armLift

                    // Its shadow on the record, further off when lifted.
                    Rectangle {
                        x: -190
                        y: -3 + 6 + 8 * root.armLift
                        width: 200
                        height: 7
                        radius: 3.5
                        color: Qt.alpha("black", 0.45)
                    }
                    // The tube.
                    Rectangle {
                        x: -178
                        y: -3.5
                        width: 178
                        height: 7
                        radius: 3.5
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#f4f4f2" }
                            GradientStop { position: 0.5; color: "#a9aaac" }
                            GradientStop { position: 1; color: "#5d5e62" }
                        }
                    }
                    // The headshell and cartridge, the needle under it.
                    Rectangle {
                        x: -198
                        y: -8
                        width: 26
                        height: 16
                        radius: 2
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#3a3b40" }
                            GradientStop { position: 1; color: "#18191b" }
                        }
                        border.width: 1
                        border.color: "black"

                        Rectangle {
                            x: 4
                            y: 4
                            width: 8
                            height: 8
                            radius: 1
                            color: root.labelColor
                        }
                    }
                    // The label.
                    Legend {
                        readonly property int fits: Math.floor((136 - size) / pitch)

                        x: -168
                        y: -height / 2
                        size: 9
                        text: root.shownLabel.length > fits ? root.shownLabel.slice(0, fits - 1) + "…" : root.shownLabel
                        visible: root.shownLabel !== ""
                    }
                    // The pivot and the counterweight.
                    Rectangle {
                        x: -4
                        y: -12
                        width: 34
                        height: 24
                        radius: 4
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#cfd0d2" }
                            GradientStop { position: 1; color: "#55565a" }
                        }
                        border.width: 1
                        border.color: "black"
                    }
                    Rectangle {
                        x: -16
                        y: -16
                        width: 32
                        height: 32
                        radius: 16
                        border.width: 1
                        border.color: "black"
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#8d8e92" }
                            GradientStop { position: 1; color: "#2c2d31" }
                        }
                    }
                }
            }

            // The transport and the source keys.
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 10

                Legend {
                    text: "deck"
                }
                Row {
                    spacing: 6

                    C.IconButton {
                        size: 42
                        icon: "\u{F04AE}"
                        enabled: root.control.player !== null
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.control.previous()
                    }
                    C.IconButton {
                        size: 42
                        lit: root.control.playing
                        icon: root.control.playing ? "\u{F03E4}" : "\u{F040A}"
                        enabled: root.control.player !== null
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.control.togglePlaying()
                    }
                    C.IconButton {
                        size: 42
                        icon: "\u{F04AD}"
                        enabled: root.control.player !== null
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.control.next()
                    }
                }
                Legend {
                    Layout.topMargin: 8
                    text: "source"
                }
                Row {
                    spacing: 6

                    C.IconButton {
                        size: 34
                        icon: "\u{F0141}"
                        enabled: root.control.players.length > 1
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.control.cycle(-1)
                    }
                    C.IconButton {
                        size: 34
                        icon: "\u{F0142}"
                        enabled: root.control.players.length > 1
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.control.cycle(1)
                    }
                }
            }
        }

        // ── The mixer ────────────────────────────────────────────────────────
        Flow {
            Layout.fillWidth: true
            spacing: 8

            // The output and the input: a device selector, and a MODE
            // selector when the device has profiles to choose from.
            Channel {
                id: master

                readonly property var profiles: root.control.outputProfiles

                panel: root.control
                nodes: [root.control.output]
                name: "master"
                line1: root.control.nodeName(root.control.output)
                line2: profiles.switching ? "switching..." : profiles.current?.label ?? ""

                Row {
                    Selector {
                        legend: "out"
                        count: root.control.outputs.length
                        index: root.control.outputs.indexOf(root.control.output)
                        onStepped: step => root.control.setDefaultOutput(root.control.outputs[(index + step + count) % count])
                    }
                    Selector {
                        legend: "mode"
                        count: master.profiles.list.length
                        index: master.profiles.list.findIndex(p => p.current)
                        visible: count > 1
                        onStepped: step => master.profiles.set(master.profiles.list[(index + step + count) % count].index)
                    }
                }
            }
            Channel {
                id: mic

                readonly property var profiles: root.control.inputProfiles

                panel: root.control
                nodes: [root.control.input]
                name: "mic"
                line1: root.control.nodeName(root.control.input)
                line2: profiles.switching ? "switching..." : profiles.current?.label ?? ""

                Row {
                    Selector {
                        legend: "in"
                        count: root.control.inputs.length
                        index: root.control.inputs.indexOf(root.control.input)
                        onStepped: step => root.control.setDefaultInput(root.control.inputs[(index + step + count) % count])
                    }
                    Selector {
                        legend: "mode"
                        count: mic.profiles.list.length
                        index: mic.profiles.list.findIndex(p => p.current)
                        visible: count > 1
                        onStepped: step => mic.profiles.set(mic.profiles.list[(index + step + count) % count].index)
                    }
                }
            }
            Repeater {
                model: root.control.apps

                Channel {
                    required property int index
                    required property var modelData

                    panel: root.control
                    nodes: modelData.nodes
                    name: modelData.name
                    line1: modelData.name
                    line2: modelData.nodes.length > 1 ? `${modelData.nodes.length} streams` : ""

                    Sticker {
                        width: 34
                        height: 34
                        y: 14
                        source: root.control.nodeIcon(modelData.nodes[0])
                        seed: index + 3
                    }
                }
            }
        }
    }
}
