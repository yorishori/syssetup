import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.components
import qs.core
import qs.services

// Now playing (with a player switcher when there are several), then tabs:
// OUTPUT (master level + devices), INPUT (mic level + devices), MIXER (apps).
ColumnLayout {
    id: root

    width: 320
    spacing: 10

    // Mute key + segmented level meter + level readout for one node. Changes
    // also apply to `linked` nodes (other streams of the same app).
    component LevelRow: RowLayout {
        id: row

        required property PwNode node
        property var linked: []
        property string icon: "\u{F057E}"
        property string mutedIcon: "\u{F075F}"
        readonly property bool muted: node?.audio?.muted ?? false
        readonly property real volume: node?.audio?.volume ?? 0

        Layout.fillWidth: true
        spacing: 8

        IconButton {
            size: 24
            icon: row.muted ? row.mutedIcon : row.icon
            iconColor: row.muted ? Theme.palette.off : Theme.palette.fg
            onClicked: {
                const mute = !row.muted;
                for (const n of [row.node, ...row.linked])
                    if (n?.audio)
                        n.audio.muted = mute;
            }
        }
        Meter {
            Layout.fillWidth: true
            value: row.volume
            color: row.muted ? Theme.palette.off : Theme.palette.accent
            onMoved: value => {
                for (const n of [row.node, ...row.linked])
                    Audio.setNodeVolume(n, value);
            }
        }
        StyledText {
            Layout.preferredWidth: 30
            horizontalAlignment: Text.AlignRight
            text: String(Math.round(row.volume * 100)).padStart(3, "0")
            color: row.muted ? Theme.palette.off : Theme.palette.dim
            font.bold: true
        }
    }

    // Selectable device (or profile): the current one has a lit lamp.
    component DeviceItem: ListRow {
        id: device

        required property var modelData
        required property bool selected
        property string label: Audio.nodeName(modelData)

        signal picked

        implicitHeight: 26
        leftPadding: 8
        marker: false
        onClicked: picked()

        Lamp {
            on: device.selected
        }
        StyledText {
            Layout.fillWidth: true
            text: device.label
            color: device.selected ? Theme.palette.accent : Theme.palette.dim
            glow: device.selected
            elide: Text.ElideRight
        }
    }

    // Profile of the selected device (Bluetooth codec, card mode), folded into
    // one line until clicked. On Bluetooth, high bitrate codecs (LDAC, aptX HD)
    // drop out sooner than SBC/AAC; HSP/HFP brings the mic at low quality.
    component ProfilePicker: ColumnLayout {
        id: picker

        required property var profiles
        property bool open: false

        Layout.fillWidth: true
        spacing: 6
        visible: profiles.list.length > 1

        ListRow {
            implicitHeight: 26
            leftPadding: 8
            marker: false
            onClicked: picker.open = !picker.open

            StyledText {
                text: "profile"
                caps: true
                color: Theme.palette.muted
                font.pixelSize: Theme.font.size - 2
                font.bold: true
                tracking: 1.5
            }
            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: picker.profiles.switching ? "switching..." : picker.profiles.current?.label ?? "--"
                color: Theme.palette.dim
                elide: Text.ElideRight
            }
            StyledText {
                text: picker.open ? "\u{F0143}" : "\u{F0140}"
                color: Theme.palette.muted
            }
        }
        Repeater {
            model: picker.open ? picker.profiles.list : []
            DeviceItem {
                leftPadding: 16
                label: modelData.label
                selected: modelData.current
                onPicked: {
                    picker.profiles.set(modelData.index);
                    picker.open = false;
                }
            }
        }
    }

    // ── Now playing ──────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: Media.player !== null

        SectionTitle {
            text: "Now playing"
            code: Media.players.length > 1 ? "" : Media.player?.identity ?? ""
        }

        // Player switcher: one icon per player, a lamp under the current one,
        // lit (accent) when that player is playing.
        Repeater {
            model: Media.players.length > 1 ? Media.players : []

            Item {
                id: switchItem

                required property MprisPlayer modelData
                readonly property bool current: modelData === Media.player
                readonly property string icon: Media.iconFor(modelData)

                implicitWidth: 22
                implicitHeight: 22

                IconImage {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1
                    implicitSize: 14
                    source: switchItem.icon
                    visible: switchItem.icon !== ""
                    opacity: switchItem.current ? 1 : 0.45
                }
                StyledText {
                    anchors.centerIn: parent
                    text: switchItem.modelData.identity.slice(0, 2)
                    caps: true
                    visible: switchItem.icon === ""
                    color: switchItem.current ? Theme.palette.fg : Theme.palette.muted
                    font.pixelSize: Theme.font.size - 3
                    font.bold: true
                }
                Marker {
                    anchors {
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: 12
                    height: 2
                    color: switchItem.modelData.isPlaying ? Theme.palette.accent : Theme.palette.dim
                    visible: switchItem.current || switchItem.modelData.isPlaying
                    opacity: switchItem.current ? 1 : 0.5
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.select(switchItem.modelData)
                }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        visible: Media.player !== null

        // Cover art; the app's icon when there's none.
        Picture {
            implicitWidth: 56
            implicitHeight: 56
            visible: Media.art !== "" || Media.icon !== ""
            source: Media.art
            icon: Media.icon
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: Media.title || Media.player?.identity || ""
                font.bold: true
                elide: Text.ElideRight
            }
            StyledText {
                Layout.fillWidth: true
                text: Media.artist
                color: Theme.palette.muted
                elide: Text.ElideRight
                visible: text !== ""
            }
        }
    }
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 10
        visible: Media.player !== null

        IconButton {
            icon: "\u{F04AE}"
            onClicked: Media.previous()
        }
        IconButton {
            size: 34
            lit: true
            icon: Media.playing ? "\u{F03E4}" : "\u{F040A}"
            onClicked: Media.togglePlaying()
        }
        IconButton {
            icon: "\u{F04AD}"
            onClicked: Media.next()
        }
    }

    // ── Tabs ─────────────────────────────────────────────────────────────────
    Tabs {
        id: tabs

        Layout.topMargin: Media.player !== null ? 4 : 0
        tabs: ["Output", "Input", "Mixer"]
    }

    // Output
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: tabs.current === 0

        LevelRow { node: Audio.output }
        Repeater {
            model: Audio.outputs
            DeviceItem {
                selected: modelData === Audio.output
                onPicked: Audio.setDefaultOutput(modelData)
            }
        }

        ProfilePicker { profiles: Audio.outputProfiles }
    }

    // Input
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: tabs.current === 1

        LevelRow {
            node: Audio.input
            icon: "\u{F036C}"
            mutedIcon: "\u{F036D}"
        }
        Repeater {
            model: Audio.inputs
            DeviceItem {
                selected: modelData === Audio.input
                onPicked: Audio.setDefaultInput(modelData)
            }
        }
        ProfilePicker { profiles: Audio.inputProfiles }
    }

    // Mixer: one line per app: icon, name, level.
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: tabs.current === 2

        Placeholder {
            text: "-- no streams --"
            visible: Audio.apps.length === 0
        }
        Repeater {
            model: Audio.apps

            RowLayout {
                id: app

                required property var modelData

                Layout.fillWidth: true
                spacing: 8

                IconImage {
                    implicitSize: 14
                    source: Audio.nodeIcon(app.modelData.nodes[0])
                    visible: source.toString() !== ""
                }
                StyledText {
                    Layout.preferredWidth: 64
                    text: app.modelData.name.toLowerCase()
                    color: Theme.palette.dim
                    font.pixelSize: Theme.font.size - 1
                    elide: Text.ElideRight
                }
                LevelRow {
                    node: app.modelData.nodes[0]
                    linked: app.modelData.nodes.slice(1)
                }
            }
        }
    }
}
