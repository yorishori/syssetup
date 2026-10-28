import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core
import qs.modules.bluetooth as M

// The Bluetooth rune on top (a radar pulse runs out from it while
// scanning) beside how many devices are with you, and the power and scan
// keys. Connected devices are cards: their own little sprite, the whole
// name, battery as hearts. Paired and nearby ones are roomy rows. Click
// one for its actions.
Item {
    id: root

    required property M.BluetoothPanel control

    // Address of the device whose actions are shown, "" for none.
    property string expanded: ""

    implicitWidth: 420
    implicitHeight: column.implicitHeight

    function rgba(c: color, a: real): string {
        return `rgba(${Math.round(c.r * 255)},${Math.round(c.g * 255)},${Math.round(c.b * 255)},${a})`;
    }

    Ticker { id: clock }

    // Battery as five hearts, full, half or empty.
    component Hearts: Row {
        property real value: 0

        spacing: 2

        Repeater {
            model: 5

            PixelArt {
                required property int index
                readonly property real fill: Math.max(0, Math.min(1, parent.value * 5 - index))

                px: 2
                colors: ({ "x": parent.value <= 0.2 ? Theme.palette.warn : "#e8a0b4", "o": root.rgba(Theme.palette.muted, 1) })
                rows: fill >= 0.75 ? [".xx.xx.", "xxxxxxx", "xxxxxxx", ".xxxxx.", "..xxx..", "...x..."]
                    : fill >= 0.25 ? [".xo.oo.", "xxxo..o", "xxxo..o", ".xxo.o.", "..xoo..", "...o..."]
                    : [".oo.oo.", "o..o..o", "o.....o", ".o...o.", "..o.o..", "...o..."]
            }
        }
    }

    component Actions: RowLayout {
        id: actions

        required property var device
        readonly property bool busy: root.control.busyWith(device)

        Layout.fillWidth: true
        Layout.leftMargin: 18
        Layout.rightMargin: 8
        spacing: 6
        visible: root.expanded === device.address

        Item {
            Layout.fillWidth: true
        }
        C.TextButton {
            text: "Connect"
            visible: actions.device.paired && !actions.device.connected
            enabled: !root.control.busy
            onClicked: root.control.connect(actions.device)
        }
        C.TextButton {
            text: "Disconnect"
            visible: actions.device.connected
            enabled: !actions.busy
            onClicked: root.control.disconnect(actions.device)
        }
        C.TextButton {
            text: "Pair"
            visible: !actions.device.paired
            enabled: !root.control.busy
            onClicked: root.control.pair(actions.device)
        }
        C.TextButton {
            text: "Forget"
            visible: actions.device.paired
            enabled: !actions.busy
            onClicked: {
                root.expanded = "";
                root.control.forget(actions.device);
            }
        }
    }

    component Failure: C.StyledText {
        required property var device

        Layout.fillWidth: true
        Layout.leftMargin: 18
        Layout.rightMargin: 8
        text: Theme.caps("err") + " " + root.control.error
        color: Theme.palette.error
        font.pixelSize: Theme.font.size - 2
        wrapMode: Text.Wrap
        visible: root.control.failed(device)
    }

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 10

        // ── The rune and who's with you ───────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 64
            color: Theme.palette.bgAlt

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 8
                spacing: 14

                Item {
                    implicitWidth: 44
                    implicitHeight: 44

                    // The radar: square rings running out, while scanning.
                    Repeater {
                        model: 3

                        Rectangle {
                            required property int index
                            readonly property int r: ((clock.frame + index * 3) % 9) * 3

                            anchors.centerIn: parent
                            width: 18 + 2 * r
                            height: 18 + 2 * r
                            color: "transparent"
                            border.width: 3
                            border.color: Theme.palette.accent
                            opacity: 0.6 - r / 45
                            visible: root.control.discovering
                        }
                    }
                    Glyph {
                        anchors.centerIn: parent
                        px: 4
                        text: root.control.powered ? (root.control.connected.length ? "\u{F00B1}" : "\u{F00AF}") : "\u{F00B2}"
                        color: !root.control.powered ? Theme.palette.off : root.control.connected.length ? Theme.palette.accent : Theme.palette.dim
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    C.StyledText {
                        Layout.fillWidth: true
                        text: !root.control.powered ? "Bluetooth is off"
                            : root.control.connected.length === 1 ? "1 device with you"
                            : root.control.connected.length ? `${root.control.connected.length} devices with you`
                            : "Nobody's here yet"
                        color: root.control.powered && root.control.connected.length ? Theme.palette.accent : Theme.palette.dim
                        font.pixelSize: Theme.font.size + 4
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    C.StyledText {
                        text: root.control.discovering ? "looking around…" : root.control.powered ? `adapter · ${root.control.adapterName}` : "turn it on to pair"
                        caps: true
                        color: Theme.palette.dim
                        font.family: Theme.get("font.labels") ?? Theme.font.family
                        font.pixelSize: Theme.font.size - 4
                    }
                }
                C.IconButton {
                    icon: "\u{F0450}"
                    visible: root.control.powered
                    enabled: !root.control.discovering
                    iconColor: root.control.discovering ? Theme.palette.accent : Theme.palette.fg
                    onClicked: root.control.scan()
                }
                C.IconButton {
                    icon: root.control.powered ? "\u{F00AF}" : "\u{F00B2}"
                    lit: root.control.powered
                    iconColor: Theme.palette.off
                    onClicked: root.control.setEnabled(!root.control.powered)
                }
            }
        }

        // ── Connected: cards ──────────────────────────────────────────────
        Repeater {
            model: root.control.connected

            ColumnLayout {
                id: card

                required property var modelData

                Layout.fillWidth: true
                spacing: 6

                C.ListRow {
                    implicitHeight: 54
                    leftPadding: 18
                    rightPadding: 12
                    spacing: 14
                    current: root.expanded === card.modelData.address
                    onClicked: root.expanded = current ? "" : card.modelData.address

                    Rectangle {
                        implicitWidth: 40
                        implicitHeight: 40
                        color: Theme.palette.bgAlt
                        border.width: 3
                        border.color: Theme.palette.accent

                        Glyph {
                            anchors.centerIn: parent
                            px: 3
                            text: root.control.glyph(card.modelData)
                            color: Theme.palette.accent
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        C.StyledText {
                            Layout.fillWidth: true
                            text: card.modelData.name
                            color: Theme.palette.fg
                            elide: Text.ElideRight
                        }
                        RowLayout {
                            spacing: 8

                            Hearts {
                                visible: card.modelData.batteryAvailable
                                value: card.modelData.battery
                            }
                            C.StyledText {
                                text: root.control.busyWith(card.modelData) ? "leaving…"
                                    : card.modelData.batteryAvailable ? `${Math.round(card.modelData.battery * 100)}%` : "connected"
                                caps: true
                                color: card.modelData.batteryAvailable && card.modelData.battery <= 0.2 ? Theme.palette.warn : Theme.palette.dim
                                font.family: Theme.get("font.labels") ?? Theme.font.family
                                font.pixelSize: Theme.font.size - 4
                            }
                        }
                    }
                }
                Failure {
                    device: card.modelData
                }
                Actions {
                    device: card.modelData
                }
            }
        }

        // ── Paired, nearby: rows ──────────────────────────────────────────
        Repeater {
            model: [
                { title: "Paired", devices: root.control.paired },
                { title: "Nearby", devices: root.control.nearby }
            ]

            ColumnLayout {
                id: section

                required property var modelData

                Layout.fillWidth: true
                spacing: 4
                visible: modelData.devices.length > 0

                C.SectionTitle {
                    Layout.topMargin: 2
                    text: section.modelData.title
                    code: String(section.modelData.devices.length).padStart(2, "0")
                }
                Repeater {
                    model: section.modelData.devices

                    ColumnLayout {
                        id: item

                        required property var modelData
                        readonly property bool busy: root.control.busyWith(modelData)

                        Layout.fillWidth: true
                        spacing: 6

                        C.ListRow {
                            implicitHeight: 34
                            leftPadding: 18
                            rightPadding: 10
                            spacing: 12
                            current: root.expanded === item.modelData.address
                            onClicked: root.expanded = current ? "" : item.modelData.address

                            Glyph {
                                text: root.control.glyph(item.modelData)
                                color: Theme.palette.dim
                            }
                            C.StyledText {
                                Layout.fillWidth: true
                                text: item.modelData.name
                                color: Theme.palette.fg
                                elide: Text.ElideRight
                            }
                            C.StyledText {
                                text: item.busy ? (item.modelData.pairing ? "pairing…" : "joining…")
                                    : root.control.failed(item.modelData) ? "failed"
                                    : item.modelData.paired ? "saved" : "new"
                                caps: true
                                color: root.control.failed(item.modelData) ? Theme.palette.error : Theme.palette.muted
                                font.family: Theme.get("font.labels") ?? Theme.font.family
                                font.pixelSize: Theme.font.size - 4
                            }
                        }
                        Failure {
                            device: item.modelData
                        }
                        Actions {
                            device: item.modelData
                        }
                    }
                }
            }
        }

        C.StyledText {
            Layout.leftMargin: 8
            text: !root.control.powered ? "-- the radio is off --" : "-- nothing around --"
            color: Theme.palette.muted
            visible: !root.control.powered || root.control.devices.length === 0
        }
    }
}
