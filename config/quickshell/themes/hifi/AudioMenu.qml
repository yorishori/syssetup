import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.components as C
import qs.core
import qs.modules.audio as M

// A cassette deck and a mixer. What's playing is a tape in the deck's
// window: the track on its label, its spools winding from one side to the
// other as the track goes on, the hubs turning while it plays. Piano keys
// below it drive it (the play key latches down while playing), with source
// keys to pick the player when there are several. Under that, the selector
// for OUTPUT, INPUT and MIXER: a master fader with its devices, or a row of
// channel strips, one per app, each with a stickered name, an upright fader,
// a readout and a mute key.
Item {
    id: root

    required property M.AudioPanel control

    implicitWidth: 460
    implicitHeight: column.implicitHeight

    // A level readout on a small glass display.
    component Readout: Item {
        id: readout

        property real value
        property bool muted

        implicitWidth: 40
        implicitHeight: 22

        Well {
            anchors.fill: parent
            roundness: 3
        }
        C.StyledText {
            anchors.centerIn: parent
            text: readout.muted ? "off" : String(Math.round(readout.value * 100)).padStart(3, "0")
            caps: true
            color: readout.muted ? Theme.palette.off : Theme.palette.accent
            glow: !readout.muted
            font.pixelSize: Theme.font.size - 2
            font.bold: true
        }
    }

    // A mute key, a fader and its readout for one node; changes also apply to
    // `linked` nodes (other streams of the same app).
    component LevelRow: RowLayout {
        id: row

        required property M.AudioPanel panel
        required property PwNode node
        property var linked: []
        property string icon: "\u{F057E}"
        property string mutedIcon: "\u{F075F}"
        readonly property bool muted: node?.audio?.muted ?? false
        readonly property real volume: node?.audio?.volume ?? 0

        Layout.fillWidth: true
        spacing: 12

        C.IconButton {
            size: 28
            icon: row.muted ? row.mutedIcon : row.icon
            iconColor: row.muted ? Theme.palette.off : Theme.palette.fg
            lit: row.muted
            onClicked: row.panel.setMuted([row.node, ...row.linked], !row.muted)
        }
        C.Meter {
            Layout.fillWidth: true
            implicitHeight: 12
            value: row.volume
            color: row.muted ? Theme.palette.off : Theme.palette.accent
            onMoved: value => row.panel.setLevel([row.node, ...row.linked], value)
        }
        Readout {
            value: row.volume
            muted: row.muted
        }
    }

    // A selectable device (or profile): the current one has its LED lit.
    component DeviceItem: C.ListRow {
        id: device

        required property M.AudioPanel panel
        required property var modelData
        required property bool selected
        property string label: panel.nodeName(modelData)

        signal picked

        implicitHeight: 28
        leftPadding: 10
        marker: false
        onClicked: picked()

        C.Lamp {
            on: device.selected
        }
        C.StyledText {
            Layout.fillWidth: true
            text: device.label
            color: device.selected ? Theme.palette.fg : Theme.palette.dim
            elide: Text.ElideRight
        }
    }

    // The selected device's profile (Bluetooth codec, card mode), folded into
    // one row until clicked.
    component ProfilePicker: ColumnLayout {
        id: picker

        required property M.AudioPanel panel
        required property var profiles
        property bool open: false

        Layout.fillWidth: true
        spacing: 4
        visible: profiles.list.length > 1

        C.ListRow {
            implicitHeight: 28
            leftPadding: 10
            marker: false
            onClicked: picker.open = !picker.open

            Legend {
                text: "profile"
            }
            C.StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: picker.profiles.switching ? "switching..." : picker.profiles.current?.label ?? "--"
                color: Theme.palette.dim
                elide: Text.ElideRight
            }
            C.StyledText {
                text: picker.open ? "\u{F0143}" : "\u{F0140}"
                color: Theme.palette.muted
            }
        }
        Repeater {
            model: picker.open ? picker.profiles.list : []

            DeviceItem {
                panel: picker.panel
                leftPadding: 20
                label: modelData.label
                selected: modelData.current
                onPicked: {
                    picker.profiles.set(modelData.index);
                    picker.open = false;
                }
            }
        }
    }

    // One reel: the tape wound on it (`wound`, 0-1) and its hub, turning while
    // it plays.
    component Reel: Item {
        id: reel

        property real wound: 0.5
        property bool turning: false

        width: 72
        height: 72

        // The tape.
        Rectangle {
            property real size: 26 + 44 * reel.wound

            anchors.centerIn: parent
            width: size
            height: size
            radius: size / 2
            gradient: Gradient {
                GradientStop { position: 0; color: "#4a372b" }
                GradientStop { position: 1; color: "#2a1d16" }
            }

            Behavior on size {
                NumberAnimation { duration: 900 }
            }
        }
        // The hub.
        Item {
            anchors.centerIn: parent
            width: 24
            height: 24

            RotationAnimation on rotation {
                running: reel.turning
                from: 0
                to: 360
                duration: 2400
                loops: Animation.Infinite
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                border.width: 1
                border.color: "#8d877a"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#f2eee4" }
                    GradientStop { position: 1; color: "#b9b3a6" }
                }
            }
            Rectangle {
                anchors.centerIn: parent
                width: 12
                height: 12
                radius: 6
                color: "#1b1b1d"
            }
            // The teeth that grip the spindle.
            Repeater {
                model: 6

                Rectangle {
                    required property int index

                    x: 12 - 1.5
                    y: 6
                    width: 3
                    height: 3
                    color: "#f2eee4"
                    transform: Rotation {
                        origin.x: 1.5
                        origin.y: 6
                        angle: index * 60
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 12

        // ── The deck ─────────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            implicitHeight: 160
            visible: root.control.player !== null

            Well {
                id: bay

                anchors.fill: parent
                roundness: 6
                fill: "#0c0c0e"
            }

            // The cassette.
            Item {
                id: cassette

                readonly property real progress: root.control.progress

                anchors.centerIn: parent
                width: 380
                height: 140

                RectangularShadow {
                    anchors.fill: parent
                    radius: 8
                    offset.y: 3
                    blur: 8
                    color: Qt.alpha("black", 0.7)
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    border.width: 1
                    border.color: "black"
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#34353a" }
                        GradientStop { position: 1; color: "#1c1d20" }
                    }
                }
                Repeater {
                    model: [[8, 8], [364, 8], [8, 124], [364, 124]]

                    Screw {
                        required property var modelData

                        x: modelData[0]
                        y: modelData[1]
                        size: 8
                    }
                }

                // The label: the track, typed on it, with its cover.
                Rectangle {
                    id: label

                    x: 24
                    y: 10
                    width: parent.width - 48
                    height: 56
                    radius: 3
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#ece5d2" }
                        GradientStop { position: 1; color: "#d8d0bb" }
                    }

                    // The colored band across it.
                    Rectangle {
                        y: parent.height - 12
                        width: parent.width
                        height: 6
                        color: Qt.alpha(Theme.palette.warn, 0.75)
                    }
                    C.Picture {
                        id: cover

                        x: 6
                        y: 6
                        width: 38
                        height: 38
                        visible: root.control.art !== "" || root.control.icon !== ""
                        source: root.control.art
                        icon: root.control.icon
                    }
                    Column {
                        x: cover.visible ? cover.x + cover.width + 10 : 10
                        y: 7
                        width: parent.width - x - 10
                        spacing: 1

                        Text {
                            width: parent.width
                            text: root.control.title || root.control.player?.identity || ""
                            color: "#1d2340"
                            elide: Text.ElideRight
                            font.family: Theme.font.family
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            text: root.control.artist
                            color: "#4a4d5c"
                            elide: Text.ElideRight
                            font.family: Theme.font.family
                            font.pixelSize: 12
                            visible: text !== ""
                        }
                    }
                }

                // The window onto the reels.
                Item {
                    id: window

                    x: 80
                    y: 72
                    width: parent.width - 160
                    height: 56

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: "#0b0a09"
                        border.width: 1
                        border.color: "black"
                    }
                    Item {
                        anchors.fill: parent
                        clip: true

                        Reel {
                            x: 40 - width / 2
                            y: parent.height / 2 - height / 2
                            wound: cassette.progress < 0 ? 0.5 : 1 - cassette.progress
                            turning: root.control.playing
                        }
                        Reel {
                            x: parent.width - 40 - width / 2
                            y: parent.height / 2 - height / 2
                            wound: cassette.progress < 0 ? 0.5 : cassette.progress
                            turning: root.control.playing
                        }
                    }
                    Gloss {
                        anchors.fill: parent
                        roundness: 6
                    }
                }
            }

            Gloss {
                anchors {
                    fill: parent
                    margins: 1
                }
                roundness: bay.r
            }
        }

        // Transport, and the source keys.
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: root.control.player !== null

            C.IconButton {
                implicitWidth: 70
                size: 36
                icon: "\u{F04AE}"
                onClicked: root.control.previous()
            }
            C.IconButton {
                implicitWidth: 70
                size: 36
                lit: root.control.playing
                icon: root.control.playing ? "\u{F03E4}" : "\u{F040A}"
                onClicked: root.control.togglePlaying()
            }
            C.IconButton {
                implicitWidth: 70
                size: 36
                icon: "\u{F04AD}"
                onClicked: root.control.next()
            }
            Item {
                Layout.fillWidth: true
            }
            Repeater {
                model: root.control.players.length > 1 ? root.control.players : []

                C.TextButton {
                    required property MprisPlayer modelData

                    text: modelData.identity.slice(0, 7)
                    lit: modelData === root.control.player
                    onClicked: root.control.select(modelData)
                }
            }
        }

        C.Tabs {
            id: tabs

            Layout.topMargin: root.control.player !== null ? 4 : 0
            tabs: ["Output", "Input", "Mixer"]
        }

        // Output
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: tabs.current === 0

            LevelRow {
                panel: root.control
                node: root.control.output
            }
            Repeater {
                model: root.control.outputs

                DeviceItem {
                    panel: root.control
                    selected: modelData === root.control.output
                    onPicked: root.control.setDefaultOutput(modelData)
                }
            }
            ProfilePicker {
                panel: root.control
                profiles: root.control.outputProfiles
            }
        }

        // Input
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: tabs.current === 1

            LevelRow {
                panel: root.control
                node: root.control.input
                icon: "\u{F036C}"
                mutedIcon: "\u{F036D}"
            }
            Repeater {
                model: root.control.inputs

                DeviceItem {
                    panel: root.control
                    selected: modelData === root.control.input
                    onPicked: root.control.setDefaultInput(modelData)
                }
            }
            ProfilePicker {
                panel: root.control
                profiles: root.control.inputProfiles
            }
        }

        // Mixer: a channel strip per app.
        Flow {
            Layout.fillWidth: true
            spacing: 8
            visible: tabs.current === 2

            C.Placeholder {
                text: "-- no streams --"
                visible: root.control.apps.length === 0
            }
            Repeater {
                model: root.control.apps

                Item {
                    id: strip

                    required property int index
                    required property var modelData
                    readonly property PwNode node: modelData.nodes[0]
                    readonly property var nodes: modelData.nodes
                    readonly property bool muted: node?.audio?.muted ?? false
                    readonly property real volume: node?.audio?.volume ?? 0

                    width: 72
                    height: 250

                    Well {
                        anchors.fill: parent
                        roundness: 4
                        fill: Qt.darker(Theme.palette.bg, 1.3)
                    }
                    Column {
                        anchors {
                            fill: parent
                            topMargin: 10
                            bottomMargin: 10
                        }
                        spacing: 10

                        Sticker {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 26
                            height: 26
                            source: root.control.nodeIcon(strip.node)
                            seed: strip.index + 3
                        }
                        C.Meter {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 14
                            height: 110
                            vertical: true
                            value: strip.volume
                            color: strip.muted ? Theme.palette.off : Theme.palette.accent
                            onMoved: value => root.control.setLevel(strip.nodes, value)
                        }
                        Readout {
                            anchors.horizontalCenter: parent.horizontalCenter
                            value: strip.volume
                            muted: strip.muted
                        }
                        C.IconButton {
                            anchors.horizontalCenter: parent.horizontalCenter
                            size: 26
                            icon: strip.muted ? "\u{F075F}" : "\u{F057E}"
                            iconColor: strip.muted ? Theme.palette.off : Theme.palette.fg
                            lit: strip.muted
                            onClicked: root.control.setMuted(strip.nodes, !strip.muted)
                        }
                    }
                    Legend {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                            bottomMargin: -7
                        }
                        text: strip.modelData.name.slice(0, 8)
                    }
                }
            }
        }
    }
}
