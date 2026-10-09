import QtQuick
import QtQuick.Effects
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
            iconColor: row.muted ? Config.colors.off : Config.colors.fg
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
            color: row.muted ? Config.colors.off : Config.colors.accent
            onMoved: value => {
                for (const n of [row.node, ...row.linked])
                    Audio.setNodeVolume(n, value);
            }
        }
        StyledText {
            Layout.preferredWidth: 30
            horizontalAlignment: Text.AlignRight
            text: String(Math.round(row.volume * 100)).padStart(3, "0")
            color: row.muted ? Config.colors.off : Config.colors.dim
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
            color: device.selected ? Config.colors.accent : Config.colors.dim
            glow: device.selected
            elide: Text.ElideRight
        }
    }

    // ── Now playing ──────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: Media.player !== null

        SectionTitle {
            text: "NOW PLAYING"
            code: Media.players.length > 1 ? "" : Media.player?.identity.toUpperCase() ?? ""
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
                    text: switchItem.modelData.identity.slice(0, 2).toUpperCase()
                    visible: switchItem.icon === ""
                    color: switchItem.current ? Config.colors.fg : Config.colors.muted
                    font.pixelSize: Config.font.size - 3
                    font.bold: true
                }
                Rectangle {
                    anchors {
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: 12
                    height: 2
                    color: switchItem.modelData.isPlaying ? Config.colors.accent : Config.colors.dim
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

        // Cover art in a cut-corner frame; the app's icon when there's none.
        Item {
            implicitWidth: 56
            implicitHeight: 56
            visible: Media.art !== "" || Media.icon !== ""

            Image {
                id: art

                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 112
                sourceSize.height: 112
                asynchronous: true
                visible: false
            }
            Chamfer {
                id: artMask

                anchors.fill: parent
                cut: 8
                fill: "white"
                visible: false
                layer.enabled: true
            }
            MultiEffect {
                anchors.fill: parent
                source: art
                maskEnabled: true
                maskSource: artMask
                visible: art.status === Image.Ready
            }
            Chamfer {
                anchors.fill: parent
                cut: 8
                fill: "transparent"
                stroke: Config.colors.border
                visible: art.status === Image.Ready
            }
            IconImage {
                anchors.centerIn: parent
                implicitSize: 34
                source: Media.icon
                visible: art.status !== Image.Ready && Media.icon !== ""
            }
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
                color: Config.colors.muted
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
        tabs: ["OUTPUT", "INPUT", "MIXER"]
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

        // Bluetooth output: codec/profile. Higher bitrate codecs (LDAC, aptX HD)
        // drop out sooner; SBC/AAC hold a link better. HSP/HFP adds the mic.
        SectionTitle {
            Layout.topMargin: 4
            text: "PROFILE"
            code: Audio.switching ? "SWITCHING" : "BT"
            visible: Audio.profiles.length > 0
        }
        Repeater {
            model: Audio.profiles
            DeviceItem {
                label: modelData.label
                selected: modelData.current
                onPicked: Audio.setProfile(modelData.index)
            }
        }
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
                    color: Config.colors.dim
                    font.pixelSize: Config.font.size - 1
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
