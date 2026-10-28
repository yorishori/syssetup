import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core
import qs.modules.network as M

// A radio mast on top, sending rings while you're connected, beside the
// network you're on and how strong it is; the Wi-Fi and scan keys. Then a
// wired link if there is one, and the networks nearby as roomy rows: block
// signal bars, the whole name, what it is (yours, saved, locked, open).
// Click one for its actions.
Item {
    id: root

    required property M.NetworkPanel control

    readonly property var current: control.networks.find(n => n.connected) ?? null
    readonly property var wiredUp: control.wired.find(w => w.connected) ?? null
    // Path of the network whose actions are shown, "" for none.
    property string expanded: ""

    implicitWidth: 420
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 10

        // ── The mast and where you are ────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 64
            color: Theme.palette.bgAlt

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 12

                Antenna {
                    Layout.alignment: Qt.AlignVCenter
                    sending: root.current !== null || root.wiredUp !== null
                    connecting: root.control.pending !== ""
                    off: !root.control.wifiEnabled && root.wiredUp === null
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    C.StyledText {
                        Layout.fillWidth: true
                        text: root.control.pending || root.current?.name || root.wiredUp?.name
                            || (root.control.wifiEnabled ? "Not connected" : "Wi-Fi is off")
                        color: root.current || root.wiredUp ? Theme.palette.accent : Theme.palette.dim
                        font.pixelSize: Theme.font.size + 4
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    C.StyledText {
                        text: root.control.pending ? "connecting…"
                            : root.current ? `connected · signal ${root.current.strength}%`
                            : root.wiredUp ? "wired · connected"
                            : root.control.wifiEnabled ? "pick a network below" : "turn it on to look around"
                        caps: true
                        color: Theme.palette.dim
                        font.family: Theme.get("font.labels") ?? Theme.font.family
                        font.pixelSize: Theme.font.size - 4
                    }
                }
                C.IconButton {
                    icon: "\u{F0450}"
                    visible: root.control.wifiEnabled
                    enabled: !root.control.scanning
                    iconColor: root.control.scanning ? Theme.palette.accent : Theme.palette.fg
                    onClicked: root.control.scan()

                    NumberAnimation on iconRotation {
                        running: root.control.scanning
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                        alwaysRunToEnd: true
                    }
                }
                C.IconButton {
                    icon: root.control.wifiEnabled ? "\u{F05A9}" : "\u{F05AA}"
                    lit: root.control.wifiEnabled
                    iconColor: Theme.palette.off
                    onClicked: root.control.setWifiEnabled(!root.control.wifiEnabled)
                }
            }
        }

        // ── Wired ─────────────────────────────────────────────────────────────
        Repeater {
            model: root.control.wired

            RowLayout {
                required property var modelData

                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 10

                Glyph {
                    text: "\u{F0200}"
                    color: modelData.connected ? Theme.palette.accent : Theme.palette.dim
                }
                C.StyledText {
                    Layout.fillWidth: true
                    text: modelData.name
                    color: modelData.connected ? Theme.palette.fg : Theme.palette.dim
                    elide: Text.ElideRight
                }
                C.StyledText {
                    text: modelData.connected ? "plugged in" : "no cable"
                    caps: true
                    color: Theme.palette.muted
                    font.family: Theme.get("font.labels") ?? Theme.font.family
                    font.pixelSize: Theme.font.size - 4
                }
            }
        }

        C.SectionTitle {
            Layout.topMargin: 2
            text: "Nearby"
            code: root.control.wifiEnabled ? String(root.control.networks.length).padStart(2, "0") : ""
        }

        C.StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            text: Theme.caps("err") + " " + root.control.error
            color: Theme.palette.error
            wrapMode: Text.Wrap
            visible: root.control.error !== ""
        }
        C.StyledText {
            Layout.leftMargin: 8
            text: !root.control.wifiEnabled ? "-- the radio is off --" : root.control.scanning ? "listening…" : "-- nothing nearby --"
            color: Theme.palette.muted
            visible: !root.control.wifiEnabled || root.control.networks.length === 0
        }

        // ── Networks ──────────────────────────────────────────────────────────
        Repeater {
            // Strongest 8; the rest are rarely what you want.
            model: root.control.wifiEnabled ? root.control.networks.slice(0, 8) : []

            ColumnLayout {
                id: item

                required property var modelData
                readonly property bool open: root.expanded === modelData.path
                readonly property bool needsPassphrase: modelData.secure && !modelData.known

                Layout.fillWidth: true
                spacing: 6

                C.ListRow {
                    implicitHeight: 34
                    leftPadding: 18
                    rightPadding: 10
                    spacing: 12
                    marker: true
                    current: item.open
                    onClicked: {
                        root.expanded = item.open ? "" : item.modelData.path;
                        if (root.expanded && item.needsPassphrase)
                            passphrase.focusInput();
                    }

                    C.SignalBars {
                        Layout.alignment: Qt.AlignVCenter
                        strength: item.modelData.strength
                        color: item.modelData.connected ? Theme.palette.accent : Theme.palette.dim
                    }
                    C.StyledText {
                        Layout.fillWidth: true
                        text: item.modelData.name
                        color: item.modelData.connected ? Theme.palette.accent : Theme.palette.fg
                        elide: Text.ElideRight
                    }
                    Glyph {
                        text: root.control.pending === item.modelData.name ? "joining…"
                            : item.modelData.connected ? "\u{F0341} yours"
                            : item.modelData.known ? "saved"
                            : item.modelData.secure ? "\u{F033E}" : "open"
                        color: item.modelData.connected ? Theme.palette.accent : Theme.palette.muted
                        pixelSize: Theme.font.size - 2
                    }
                }

                // Actions for this network
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 18
                    Layout.rightMargin: 8
                    spacing: 6
                    visible: item.open

                    C.TextField {
                        id: passphrase

                        Layout.fillWidth: true
                        prompt: "key"
                        placeholder: "passphrase"
                        echoMode: TextInput.Password
                        visible: item.needsPassphrase && !item.modelData.connected
                        onAccepted: connectButton.clicked()
                    }
                    Item {
                        Layout.fillWidth: true
                        visible: !passphrase.visible
                    }
                    C.TextButton {
                        id: connectButton

                        text: "Connect"
                        visible: !item.modelData.connected
                        enabled: !root.control.busy && (!item.needsPassphrase || passphrase.text.length >= 8)
                        onClicked: {
                            root.control.connect(item.modelData, passphrase.text);
                            passphrase.text = "";
                        }
                    }
                    C.TextButton {
                        text: "Disconnect"
                        visible: item.modelData.connected
                        enabled: !root.control.busy
                        onClicked: root.control.disconnect()
                    }
                    C.TextButton {
                        text: "Forget"
                        visible: item.modelData.known
                        enabled: !root.control.busy
                        onClicked: root.control.forget(item.modelData)
                    }
                }
            }
        }
    }
}
