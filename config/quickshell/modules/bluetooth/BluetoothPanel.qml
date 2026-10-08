import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components
import qs.core
import qs.services

// Bluetooth power and scan, then devices: CONNECTED (with battery), PAIRED,
// NEARBY (found by a scan). Click a device for its actions.
ColumnLayout {
    id: root

    // Address of the device whose actions are shown, "" for none.
    property string expanded: ""

    width: 320
    spacing: 10

    component Section: ColumnLayout {
        id: section

        property string title
        property var devices: []

        Layout.fillWidth: true
        spacing: 4
        visible: devices.length > 0

        SectionTitle {
            text: section.title
            code: String(section.devices.length).padStart(2, "0")
        }
        Repeater {
            model: section.devices

            DeviceRow {}
        }
    }

    component DeviceRow: ColumnLayout {
        id: item

        required property BluetoothDevice modelData
        readonly property bool open: root.expanded === modelData.address
        readonly property bool busy: Bluez.pending === modelData.address
            || modelData.pairing
            || modelData.state === BluetoothDeviceState.Connecting
            || modelData.state === BluetoothDeviceState.Disconnecting
        readonly property bool failed: !busy && Bluez.errorFor === modelData.address

        Layout.fillWidth: true
        spacing: 6

        ListRow {
            implicitHeight: 26
            leftPadding: 8
            rightPadding: 8
            marker: false
            highlighted: item.open
            onClicked: root.expanded = item.open ? "" : item.modelData.address

            StyledText {
                text: Bluez.glyph(item.modelData)
                color: item.modelData.connected ? Config.colors.accent : Config.colors.dim
                glow: item.modelData.connected
            }
            StyledText {
                Layout.fillWidth: true
                text: item.modelData.name
                color: item.modelData.connected ? Config.colors.accent : Config.colors.dim
                glow: item.modelData.connected
                elide: Text.ElideRight
            }
            Gauge {
                visible: item.modelData.connected && item.modelData.batteryAvailable
                value: item.modelData.battery
                color: item.modelData.battery <= 0.2 ? Config.colors.warn : Config.colors.accent
            }
            StyledText {
                text: item.busy ? (item.modelData.pairing ? "PAIRING…" : "LINKING…")
                    : item.failed ? "FAILED"
                    : item.modelData.connected
                        ? (item.modelData.batteryAvailable ? String(Math.round(item.modelData.battery * 100)).padStart(3, "0") : "LINK")
                    : item.modelData.paired ? "SAVED"
                    : "NEW"
                color: item.failed ? Config.colors.error : Config.colors.muted
                font.pixelSize: Config.font.size - 3
                font.bold: true
                font.letterSpacing: 1
            }
        }

        // Why the last pair/connect on this device failed, as BlueZ put it.
        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            text: "ERR " + Bluez.error
            color: Config.colors.error
            font.pixelSize: Config.font.size - 2
            wrapMode: Text.Wrap
            visible: item.failed
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 6
            visible: item.open

            Item {
                Layout.fillWidth: true
            }
            TextButton {
                text: "Connect"
                visible: item.modelData.paired && !item.modelData.connected
                enabled: !Bluez.busy
                onClicked: Bluez.connect(item.modelData)
            }
            TextButton {
                text: "Disconnect"
                visible: item.modelData.connected
                enabled: !item.busy
                onClicked: item.modelData.disconnect()
            }
            TextButton {
                text: "Pair"
                visible: !item.modelData.paired
                enabled: !Bluez.busy
                onClicked: Bluez.pair(item.modelData)
            }
            TextButton {
                text: "Forget"
                visible: item.modelData.paired
                enabled: !item.busy
                onClicked: {
                    root.expanded = "";
                    item.modelData.forget();
                }
            }
        }
    }

    // Header: power and scan
    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        SectionTitle {
            Layout.fillWidth: true
            text: "BLUETOOTH"
            code: (Bluez.adapter?.name ?? "").toUpperCase()
        }
        // Only the glyph spins; the key is disabled (no hover) while scanning.
        IconButton {
            icon: "\u{F0450}"
            visible: Bluez.enabled
            enabled: !Bluez.discovering
            iconColor: Bluez.discovering ? Config.colors.accent : Config.colors.fg
            onClicked: Bluez.scan()

            NumberAnimation on iconRotation {
                running: Bluez.discovering
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
                alwaysRunToEnd: true
            }
        }
        IconButton {
            icon: Bluez.enabled ? "\u{F00AF}" : "\u{F00B2}"
            lit: Bluez.enabled
            iconColor: Config.colors.off
            onClicked: Bluez.setEnabled(!Bluez.enabled)
        }
    }

    StyledText {
        Layout.leftMargin: 8
        text: "-- radio off --"
        color: Config.colors.muted
        visible: !Bluez.enabled
    }
    StyledText {
        Layout.leftMargin: 8
        text: "-- no devices, scan to find some --"
        color: Config.colors.muted
        visible: Bluez.enabled && Bluez.devices.length === 0 && !Bluez.discovering
    }

    Section {
        title: "CONNECTED"
        devices: Bluez.enabled ? Bluez.connected : []
    }
    Section {
        title: "PAIRED"
        devices: Bluez.enabled ? Bluez.paired : []
    }
    Section {
        title: "NEARBY"
        devices: Bluez.enabled ? Bluez.nearby : []
    }
    StyledText {
        Layout.leftMargin: 8
        text: "scanning…"
        color: Config.colors.muted
        visible: Bluez.discovering && Bluez.nearby.length === 0
    }
}
