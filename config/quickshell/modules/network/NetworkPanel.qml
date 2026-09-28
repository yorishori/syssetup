import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services

// Wired status, Wi-Fi power and scan, visible networks. Click a network to
// show its actions: connect (asking for a passphrase if it's new),
// disconnect, forget.
ColumnLayout {
    id: root

    // Path of the network whose actions are shown, "" for none.
    property string expanded: ""

    width: 320
    spacing: 10

    // Wired
    SectionTitle {
        text: "WIRED"
        code: "NETWORKD"
        visible: Network.wired.length > 0
    }
    Repeater {
        model: Network.wired

        RowLayout {
            required property var modelData

            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 10

            Lamp {
                on: modelData.connected
            }
            StyledText {
                Layout.fillWidth: true
                text: modelData.name
                color: modelData.connected ? Config.colors.accent : Config.colors.dim
                glow: modelData.connected
            }
            StyledText {
                text: modelData.connected ? "LINK" : "NO CABLE"
                color: Config.colors.muted
                font.pixelSize: Config.font.size - 3
                font.letterSpacing: 1
            }
        }
    }

    // Wi-Fi header
    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        SectionTitle {
            Layout.fillWidth: true
            text: "WI-FI"
            code: "IWD"
        }
        // Only the glyph spins; the key is disabled (no hover) while scanning.
        IconButton {
            icon: "\u{F0450}"
            visible: Network.wifiEnabled
            enabled: !Network.scanning
            iconColor: Network.scanning ? Config.colors.accent : Config.colors.fg
            onClicked: Network.scan()

            NumberAnimation on iconRotation {
                running: Network.scanning
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
                alwaysRunToEnd: true
            }
        }
        IconButton {
            icon: Network.wifiEnabled ? "\u{F05A9}" : "\u{F05AA}"
            lit: Network.wifiEnabled
            iconColor: Config.colors.off
            onClicked: Network.setWifiEnabled(!Network.wifiEnabled)
        }
    }

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        text: "ERR " + Network.error
        color: Config.colors.error
        wrapMode: Text.Wrap
        visible: Network.error !== ""
    }

    StyledText {
        Layout.leftMargin: 8
        text: !Network.wifiEnabled ? "-- radio off --" : Network.scanning ? "scanning…" : "-- no networks --"
        color: Config.colors.muted
        visible: Network.networks.length === 0
    }

    // Networks
    Repeater {
        // Strongest 8; the rest are rarely what you want.
        model: Network.wifiEnabled ? Network.networks.slice(0, 8) : []

        ColumnLayout {
            id: item

            required property var modelData
            readonly property bool open: root.expanded === modelData.path
            readonly property bool needsPassphrase: modelData.secure && !modelData.known

            Layout.fillWidth: true
            spacing: 6

            ListRow {
                implicitHeight: 26
                leftPadding: 8
                rightPadding: 8
                marker: false
                highlighted: item.open
                onClicked: {
                    root.expanded = item.open ? "" : item.modelData.path;
                    if (root.expanded && item.needsPassphrase)
                        passphrase.focusInput();
                }

                SignalBars {
                    Layout.alignment: Qt.AlignVCenter
                    strength: item.modelData.strength
                    color: item.modelData.connected ? Config.colors.accent : Config.colors.dim
                }
                StyledText {
                    Layout.fillWidth: true
                    text: item.modelData.name
                    color: item.modelData.connected ? Config.colors.accent : Config.colors.dim
                    glow: item.modelData.connected
                    elide: Text.ElideRight
                }
                StyledText {
                    text: Network.pending === item.modelData.name ? "LINKING…"
                        : item.modelData.connected ? "LINK"
                        : item.modelData.known ? "SAVED"
                        : item.modelData.secure ? "\u{F033E}" : "OPEN"
                    color: Config.colors.muted
                    font.pixelSize: Config.font.size - 3
                    font.letterSpacing: 1
                }
            }

            // Actions for this network
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 6
                visible: item.open

                TextField {
                    id: passphrase

                    Layout.fillWidth: true
                    placeholder: "passphrase"
                    echoMode: TextInput.Password
                    visible: item.needsPassphrase && !item.modelData.connected
                    onAccepted: connectButton.clicked()
                }
                Item {
                    Layout.fillWidth: true
                    visible: !passphrase.visible
                }
                TextButton {
                    id: connectButton

                    text: "Connect"
                    visible: !item.modelData.connected
                    enabled: !Network.busy && (!item.needsPassphrase || passphrase.text.length >= 8)
                    onClicked: {
                        Network.connect(item.modelData, passphrase.text);
                        passphrase.text = "";
                    }
                }
                TextButton {
                    text: "Disconnect"
                    visible: item.modelData.connected
                    enabled: !Network.busy
                    onClicked: Network.disconnect()
                }
                TextButton {
                    text: "Forget"
                    visible: item.modelData.known
                    enabled: !Network.busy
                    onClicked: Network.forget(item.modelData)
                }
            }
        }
    }
}
