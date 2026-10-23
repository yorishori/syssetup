import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core
import qs.modules.network as M

// Wired links, then Wi-Fi: power and scan keys, the networks; click one for
// its actions.
ColumnLayout {
    id: root

    required property M.NetworkPanel control

    implicitWidth: 320
    spacing: 10

    // Path of the network whose actions are shown, "" for none.
    property string expanded: ""


    // Wired
    C.SectionTitle {
        text: "Wired"
        code: "networkd"
        visible: root.control.wired.length > 0
    }
    Repeater {
        model: root.control.wired

        RowLayout {
            required property var modelData

            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 10

            C.Lamp {
                on: modelData.connected
            }
            C.StyledText {
                Layout.fillWidth: true
                text: modelData.name
                color: modelData.connected ? Theme.palette.accent : Theme.palette.dim
                glow: modelData.connected
            }
            C.StyledText {
                text: modelData.connected ? "link" : "no cable"
                caps: true
                color: Theme.palette.muted
                font.pixelSize: Theme.font.size - 3
                tracking: 1
            }
        }
    }

    // Wi-Fi header
    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        C.SectionTitle {
            Layout.fillWidth: true
            text: "Wi-Fi"
            code: "iwd"
        }
        // Only the glyph spins; the key is disabled (no hover) while scanning.
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
        text: !root.control.wifiEnabled ? "-- radio off --" : root.control.scanning ? "scanning…" : "-- no networks --"
        color: Theme.palette.muted
        visible: root.control.networks.length === 0
    }

    // Networks
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

                C.SignalBars {
                    Layout.alignment: Qt.AlignVCenter
                    strength: item.modelData.strength
                    color: item.modelData.connected ? Theme.palette.accent : Theme.palette.dim
                }
                C.StyledText {
                    Layout.fillWidth: true
                    text: item.modelData.name
                    color: item.modelData.connected ? Theme.palette.accent : Theme.palette.dim
                    glow: item.modelData.connected
                    elide: Text.ElideRight
                }
                C.StyledText {
                    text: root.control.pending === item.modelData.name ? "linking…"
                        : item.modelData.connected ? "link"
                        : item.modelData.known ? "saved"
                        : item.modelData.secure ? "\u{F033E}" : "open"
                    caps: true
                    color: Theme.palette.muted
                    font.pixelSize: Theme.font.size - 3
                    tracking: 1
                }
            }

            // Actions for this network
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 6
                visible: item.open

                C.TextField {
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
