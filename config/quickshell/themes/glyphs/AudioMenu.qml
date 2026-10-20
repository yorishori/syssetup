import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.components as C
import qs.core
import qs.modules.audio as M

// Now playing (with a player switcher when there are several), then tabs:
// OUTPUT (master level + devices), INPUT (mic level + devices), MIXER (apps).
Item {
    id: root

    required property M.AudioPanel control

    implicitWidth: 320
    implicitHeight: column.implicitHeight

    // Mute key + segmented level meter + level readout for one node. Changes
    // also apply to `linked` nodes (other streams of the same app).
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
            text: String(Math.round(row.volume * 100)).padStart(3, "0")
            color: row.muted ? Theme.palette.off : Theme.palette.dim
            font.bold: true
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

        implicitHeight: 26
        leftPadding: 8
        marker: false
        onClicked: picked()

        C.Lamp {
            on: device.selected
        }
        C.StyledText {
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

        // ── Now playing ──────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: root.control.player !== null

            C.SectionTitle {
                text: "Now playing"
                code: root.control.players.length > 1 ? "" : root.control.player?.identity ?? ""
            }

            // Player switcher: one icon per player, a lamp under the current
            // one, lit (accent) when that player is playing.
            Repeater {
                model: root.control.players.length > 1 ? root.control.players : []

                Item {
                    id: switchItem

                    required property MprisPlayer modelData
                    readonly property bool current: modelData === root.control.player
                    readonly property string icon: root.control.iconFor(modelData)

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
                    C.StyledText {
                        anchors.centerIn: parent
                        text: switchItem.modelData.identity.slice(0, 2)
                        caps: true
                        visible: switchItem.icon === ""
                        color: switchItem.current ? Theme.palette.fg : Theme.palette.muted
                        font.pixelSize: Theme.font.size - 3
                        font.bold: true
                    }
                    C.Marker {
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
                        onClicked: root.control.select(switchItem.modelData)
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: root.control.player !== null

            // Cover art; the app's icon when there's none.
            C.Picture {
                implicitWidth: 56
                implicitHeight: 56
                visible: root.control.art !== "" || root.control.icon !== ""
                source: root.control.art
                icon: root.control.icon
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                C.StyledText {
                    Layout.fillWidth: true
                    text: root.control.title || root.control.player?.identity || ""
                    font.bold: true
                    elide: Text.ElideRight
                }
                C.StyledText {
                    Layout.fillWidth: true
                    text: root.control.artist
                    color: Theme.palette.muted
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            visible: root.control.player !== null

            C.IconButton {
                icon: "\u{F04AE}"
                onClicked: root.control.previous()
            }
            C.IconButton {
                size: 34
                lit: true
                icon: root.control.playing ? "\u{F03E4}" : "\u{F040A}"
                onClicked: root.control.togglePlaying()
            }
            C.IconButton {
                icon: "\u{F04AD}"
                onClicked: root.control.next()
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

                    Layout.fillWidth: true
                    spacing: 8

                    IconImage {
                        implicitSize: 14
                        source: root.control.nodeIcon(app.modelData.nodes[0])
                        visible: source.toString() !== ""
                    }
                    C.StyledText {
                        Layout.preferredWidth: 64
                        text: app.modelData.name.toLowerCase()
                        color: Theme.palette.dim
                        font.pixelSize: Theme.font.size - 1
                        elide: Text.ElideRight
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
