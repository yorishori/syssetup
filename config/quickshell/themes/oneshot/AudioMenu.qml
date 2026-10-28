import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components as C
import qs.core
import qs.modules.audio as M

// A record player beside what's playing: the record spins (a glint goes
// round it) and the arm rests on it while music plays; the track, its
// progress, the keys, and a player switcher when there are several. Then
// tabs: OUTPUT (master level + devices), INPUT (mic level + devices), MIXER
// (apps, each with its icon, little equalizer bars dancing while it plays,
// and its level).
Item {
    id: root

    required property M.AudioPanel control

    Ticker { id: clock }

    implicitWidth: 420
    implicitHeight: column.implicitHeight

    // Mute key + segmented level meter + level readout for one node. Changes
    // also apply to `linked` nodes (other streams of the same app).
    component LevelRow: RowLayout {
        id: row

        required property M.AudioPanel panel
        required property var node
        property var linked: []
        property string icon: "\u{F057E}"
        property string mutedIcon: "\u{F075F}"
        readonly property bool muted: node?.audio?.muted ?? false
        readonly property real volume: node?.audio?.volume ?? 0

        Layout.fillWidth: true
        spacing: 8

        C.IconButton {
            size: 24
            icon: row.muted ? row.mutedIcon : row.icon
            iconColor: row.muted ? Theme.palette.off : Theme.palette.fg
            onClicked: row.panel.setMuted([row.node, ...row.linked], !row.muted)
        }
        C.Meter {
            Layout.fillWidth: true
            value: row.volume
            color: row.muted ? Theme.palette.off : Theme.palette.accent
            onMoved: value => row.panel.setLevel([row.node, ...row.linked], value)
        }
        C.StyledText {
            Layout.preferredWidth: 30
            horizontalAlignment: Text.AlignRight
            text: String(Math.round(row.volume * 100))
            color: row.muted ? Theme.palette.off : Theme.palette.dim
        }
    }

    // Selectable device (or profile): the current one has a lit lamp.
    component DeviceItem: C.ListRow {
        id: device

        required property M.AudioPanel panel
        required property var modelData
        required property bool selected
        property string label: panel.nodeName(modelData)

        signal picked

        implicitHeight: 32
        leftPadding: 18
        marker: device.selected
        current: device.selected
        onClicked: picked()

        C.Lamp {
            on: device.selected
        }
        C.StyledText {
            Layout.fillWidth: true
            text: device.label
            color: device.selected ? Theme.palette.accent : Theme.palette.fg
            elide: Text.ElideRight
        }
    }

    // Profile of the selected device (Bluetooth codec, card mode), folded into
    // one line until clicked. On Bluetooth, high bitrate codecs (LDAC, aptX HD)
    // drop out sooner than SBC/AAC; HSP/HFP brings the mic at low quality.
    component ProfilePicker: ColumnLayout {
        id: picker

        required property M.AudioPanel panel
        required property var profiles
        property bool open: false

        Layout.fillWidth: true
        spacing: 6
        visible: profiles.list.length > 1

        C.ListRow {
            implicitHeight: 26
            leftPadding: 8
            marker: false
            onClicked: picker.open = !picker.open

            C.StyledText {
                text: "profile"
                caps: true
                color: Theme.palette.muted
                font.pixelSize: Theme.font.size - 2
                font.bold: true
                tracking: 1.5
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

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 10

        // ── The record player and what's on ───────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 104
            color: Theme.palette.bgAlt
            visible: root.control.player !== null

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 14

                RecordPlayer {
                    playing: root.control.playing
                    art: root.control.art
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        C.StyledText {
                            Layout.fillWidth: true
                            text: root.control.title || root.control.player?.identity || ""
                            color: Theme.palette.accent
                            font.pixelSize: Theme.font.size + 3
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        // Player switcher: two letters per player, lit when playing.
                        Repeater {
                            model: root.control.players.length > 1 ? root.control.players : []

                            C.Tag {
                                required property var modelData

                                text: modelData.identity.slice(0, 2)
                                fill: modelData === root.control.player ? Theme.palette.surface : "transparent"
                                textColor: modelData.isPlaying ? Theme.palette.accent : Theme.palette.dim

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.control.select(parent.modelData)
                                }
                            }
                        }
                    }
                    C.StyledText {
                        Layout.fillWidth: true
                        text: root.control.artist
                        color: Theme.palette.dim
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                    C.Meter {
                        Layout.fillWidth: true
                        Layout.topMargin: 3
                        implicitHeight: 6
                        interactive: false
                        segments: 32
                        value: root.control.progress
                        color: Theme.palette.dim
                    }
                    RowLayout {
                        spacing: 6

                        C.IconButton {
                            icon: "\u{F04AE}"
                            onClicked: root.control.previous()
                        }
                        C.IconButton {
                            size: 30
                            lit: true
                            icon: root.control.playing ? "\u{F03E4}" : "\u{F040A}"
                            onClicked: root.control.togglePlaying()
                        }
                        C.IconButton {
                            icon: "\u{F04AD}"
                            onClicked: root.control.next()
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        C.StyledText {
                            text: root.control.player?.identity ?? ""
                            caps: true
                            color: Theme.palette.muted
                            font.family: Theme.get("font.labels") ?? Theme.font.family
                            font.pixelSize: Theme.font.size - 4
                        }
                    }
                }
            }
        }

        // ── Tabs ─────────────────────────────────────────────────────────────
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

        // Mixer: one line per app: icon, name, level.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: tabs.current === 2

            C.Placeholder {
                text: "-- no streams --"
                visible: root.control.apps.length === 0
            }
            Repeater {
                model: root.control.apps

                RowLayout {
                    id: app

                    required property var modelData
                    readonly property bool muted: app.modelData.nodes[0]?.audio?.muted ?? false

                    Layout.fillWidth: true
                    spacing: 8

                    Image {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        sourceSize: Qt.size(9, 9)
                        smooth: false
                        source: root.control.nodeIcon(app.modelData.nodes[0])
                        visible: source.toString() !== ""
                    }
                    C.StyledText {
                        Layout.preferredWidth: 76
                        text: app.modelData.name
                        color: Theme.palette.fg
                        elide: Text.ElideRight
                    }
                    // Little equalizer bars, dancing while there's sound.
                    Row {
                        spacing: 2

                        Repeater {
                            model: 3

                            Rectangle {
                                required property int index
                                readonly property int level: root.control.playing && !app.muted
                                    ? [2, 4, 3, 5, 1, 4, 2, 5, 3][(clock.frame * (index + 2) + index * 3) % 9] : 1

                                anchors.bottom: parent.bottom
                                width: 3
                                height: level * 3
                                color: app.muted ? Theme.palette.off : Theme.palette.accent
                            }
                        }
                    }
                    LevelRow {
                        panel: root.control
                        node: app.modelData.nodes[0]
                        linked: app.modelData.nodes.slice(1)
                    }
                }
            }
        }
    }
}
