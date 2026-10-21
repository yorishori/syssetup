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
// record from its pivot, the headshell hooking up onto the grooves, the
// track on label tape along its tube. Switching players lifts the arm up
// off the record toward you until the label is edge-on, turns the record
// over to the new app, and drops the arm back with the new label. The
// turntable carries its own keys: START·STOP, back and forward, and a
// spring-return SOURCE switch to step through the players (dead with only
// one).
//
// The mixer has a channel for the output (MASTER), the input (MIC) and each
// app. Every channel ends the same way, so they line up: its name on tape,
// an analog fader (printed scale, square cap) and a mute key with its LED.
// MASTER and MIC carry a display above, with their device and profile, and
// click-stop selectors for both.
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

    // One channel of the mixer. Whatever it carries above (`head`), then the
    // same as every other: its name, the fader with its scale, the mute key
    // and its LED.
    component Channel: Item {
        id: channel

        required property M.AudioPanel panel
        property var nodes: []
        property string name
        default property alias head: headSlot.data
        readonly property PwNode node: nodes[0] ?? null
        readonly property bool muted: node?.audio?.muted ?? false
        readonly property real volume: node?.audio?.volume ?? 0

        implicitWidth: Math.max(76, headSlot.width + 16)
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

            Item {
                id: headSlot

                anchors.horizontalCenter: parent.horizontalCenter
                width: childrenRect.width
                height: childrenRect.height
                visible: children.length > 0
            }
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
    }

    // What's on the turntable: `shown` is its player; it follows the current
    // one, swapping records when that changes.
    property MprisPlayer shown: null
    property real armLift: 0  // 0 = on the record, 1 = up toward you
    property real flip: 0     // the record turning over, -90 to 90 degrees

    readonly property string shownIcon: shown ? root.control.iconFor(shown) : ""
    readonly property string shownLabel: {
        if (!shown)
            return "";
        const parts = [shown.trackTitle || shown.identity, shown.trackArtist].filter(s => s);
        return parts.join(" · ");
    }

    Component.onCompleted: shown = control.player
    Connections {
        target: root.control

        function onPlayerChanged(): void {
            if (root.control.player === root.shown)
                return;
            if (!root.shown) {
                root.shown = root.control.player;
                return;
            }
            swap.restart();
        }
    }
    // The arm up toward you, the record over to the next, the arm back down.
    SequentialAnimation {
        id: swap

        NumberAnimation { target: root; property: "armLift"; to: 1; duration: 320; easing.type: Easing.InOutCubic }
        NumberAnimation { target: root; property: "flip"; to: 90; duration: 180; easing.type: Easing.InCubic }
        ScriptAction {
            script: {
                root.shown = root.control.player;
                root.flip = -90;
            }
        }
        NumberAnimation { target: root; property: "flip"; to: 0; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "armLift"; to: 0; duration: 380; easing.type: Easing.OutBounce }
    }

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 14

        // ── The turntable ────────────────────────────────────────────────────
        Item {
            id: deck

            readonly property real cx: 180
            readonly property real cy: 150
            // The arm: its pivot, how far its tube runs, where the needle lands.
            readonly property point pivot: Qt.point(52, 296)
            readonly property real tube: 156

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

            // The arm's base: a block under the pivot, the counterweight
            // behind it.
            Rectangle {
                x: deck.pivot.x - 30
                y: deck.pivot.y - 28
                width: 56
                height: 56
                radius: 6
                border.width: 1
                border.color: "black"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#2c2d31" }
                    GradientStop { position: 1; color: "#151618" }
                }
            }
            Rectangle {
                x: deck.pivot.x - 46
                y: deck.pivot.y - 13
                width: 26
                height: 26
                radius: 5
                border.width: 1
                border.color: "black"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#4a4b50" }
                    GradientStop { position: 1; color: "#1e1f22" }
                }
            }

            // The arm's shadow on the platter, gone as it lifts.
            Rectangle {
                x: deck.pivot.x
                y: deck.pivot.y + 3
                width: deck.tube
                height: 7
                radius: 3.5
                color: Qt.alpha("black", 0.5)
                opacity: 1 - root.armLift
            }

            // The tonearm: the tube from the pivot, the headshell hooking up
            // onto the record, the track on tape along the tube. It lifts on
            // its pivot toward you.
            Item {
                id: arm

                x: deck.pivot.x
                y: deck.pivot.y

                // Up to edge-on, so the label is out of sight while the
                // record changes; a short distance to the eye makes it come
                // at you.
                transform: Rotation {
                    axis { x: 0; y: 1; z: 0 }
                    angle: -90 * root.armLift
                    distanceToPlane: 420
                }

                Rectangle {
                    y: -3.5
                    width: deck.tube
                    height: 7
                    radius: 3.5
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#f4f4f2" }
                        GradientStop { position: 0.5; color: "#a9aaac" }
                        GradientStop { position: 1; color: "#5d5e62" }
                    }
                }
                // The headshell, angled up onto the grooves.
                Item {
                    x: deck.tube - 4
                    rotation: -52

                    Rectangle {
                        y: -3.5
                        width: 48
                        height: 7
                        radius: 3.5
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#f4f4f2" }
                            GradientStop { position: 1; color: "#5d5e62" }
                        }
                    }
                    Rectangle {
                        x: 42
                        y: -9
                        width: 26
                        height: 18
                        radius: 3
                        border.width: 1
                        border.color: "black"
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#3a3b40" }
                            GradientStop { position: 1; color: "#18191b" }
                        }

                        Rectangle {
                            x: 15
                            y: 5
                            width: 8
                            height: 8
                            radius: 1
                            color: Theme.palette.error
                        }
                    }
                    // The finger lift.
                    Rectangle {
                        x: 64
                        y: -14
                        width: 4
                        height: 14
                        radius: 2
                        color: "#b9babd"
                    }
                }
                // The label.
                Legend {
                    readonly property int fits: Math.floor((deck.tube - 34 - size) / pitch)

                    x: 22
                    y: -height / 2
                    text: root.shownLabel.length > fits ? root.shownLabel.slice(0, fits - 1) + "…" : root.shownLabel
                    visible: root.shownLabel !== ""
                }
                // The bearing over the pivot.
                Rectangle {
                    x: -16
                    y: -16
                    width: 32
                    height: 32
                    radius: 16
                    border.width: 1
                    border.color: "black"
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#9d9ea2" }
                        GradientStop { position: 1; color: "#2c2d31" }
                    }
                }
            }

            // The turntable's own keys and the source switch.
            Item {
                x: 386
                width: parent.width - x - 24
                height: parent.height

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 28
                    spacing: 8

                    Legend {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "source"
                    }
                    Paddle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        live: root.control.players.length > 1
                        onFlicked: step => root.control.cycle(step)
                    }
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 10
                    spacing: 8

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10

                        C.IconButton {
                            size: 36
                            icon: "\u{F04AE}"
                            enabled: root.control.player !== null
                            opacity: enabled ? 1 : 0.4
                            onClicked: root.control.previous()
                        }
                        C.IconButton {
                            size: 36
                            icon: "\u{F04AD}"
                            enabled: root.control.player !== null
                            opacity: enabled ? 1 : 0.4
                            onClicked: root.control.next()
                        }
                    }
                    Legend {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "track"
                    }
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 24
                    spacing: 8

                    C.IconButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: 76
                        size: 50
                        lit: root.control.playing
                        icon: root.control.playing ? "\u{F03E4}" : "\u{F040A}"
                        enabled: root.control.player !== null
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.control.togglePlaying()
                    }
                    Legend {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "start · stop"
                    }
                }
            }
        }

        // ── The mixer ────────────────────────────────────────────────────────
        RowLayout {
            id: mixer

            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            // The output and the input: a device selector, and a MODE
            // selector when the device has profiles to choose from.
            Channel {
                id: master

                readonly property var profiles: root.control.outputProfiles

                Layout.alignment: Qt.AlignBottom
                panel: root.control
                nodes: [root.control.output]
                name: "master"

                Column {
                    spacing: 8

                    Display {
                        anchors.horizontalCenter: parent.horizontalCenter
                        line1: root.control.nodeName(root.control.output)
                        line2: master.profiles.switching ? "switching..." : master.profiles.current?.label ?? ""
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter

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
            }
            Channel {
                id: mic

                readonly property var profiles: root.control.inputProfiles

                Layout.alignment: Qt.AlignBottom
                panel: root.control
                nodes: [root.control.input]
                name: "mic"

                Column {
                    spacing: 8

                    Display {
                        anchors.horizontalCenter: parent.horizontalCenter
                        line1: root.control.nodeName(root.control.input)
                        line2: mic.profiles.switching ? "switching..." : mic.profiles.current?.label ?? ""
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter

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
            }

            // The apps: just their name above the fader.
            Repeater {
                model: root.control.apps

                Channel {
                    required property var modelData

                    Layout.alignment: Qt.AlignBottom
                    panel: root.control
                    nodes: modelData.nodes
                    name: modelData.name
                }
            }

            C.Placeholder {
                Layout.alignment: Qt.AlignVCenter
                text: "-- no apps playing --"
                visible: root.control.apps.length === 0
            }
        }
    }
}
