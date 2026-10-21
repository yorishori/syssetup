import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components as C
import qs.core
import qs.modules.bluetooth as M

// Power and scan keys, then the devices in sections, CONNECTED (with
// battery), PAIRED, NEARBY; click one for its actions.
ColumnLayout {
    id: root

    required property M.BluetoothPanel control

    implicitWidth: 320
    spacing: 10

    // Address of the device whose actions are shown, "" for none.
    property string expanded: ""


    component Section: ColumnLayout {
        id: section

        property string title
        property var devices: []

        Layout.fillWidth: true
        spacing: 4
        visible: devices.length > 0

        C.SectionTitle {
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
        readonly property bool busy: root.control.busyWith(modelData)
        readonly property bool failed: root.control.failed(modelData)

        Layout.fillWidth: true
        spacing: 6

        C.ListRow {
            implicitHeight: 26
            leftPadding: 8
            rightPadding: 8
            marker: false
            highlighted: item.open
            onClicked: root.expanded = item.open ? "" : item.modelData.address

            C.StyledText {
                text: root.control.glyph(item.modelData)
                color: item.modelData.connected ? Theme.palette.accent : Theme.palette.dim
                glow: item.modelData.connected
            }
            C.StyledText {
                Layout.fillWidth: true
                text: item.modelData.name
                color: item.modelData.connected ? Theme.palette.accent : Theme.palette.dim
                glow: item.modelData.connected
                elide: Text.ElideRight
            }
            C.Gauge {
                visible: item.modelData.connected && item.modelData.batteryAvailable
                value: item.modelData.battery
                color: item.modelData.battery <= 0.2 ? Theme.palette.warn : Theme.palette.accent
            }
            C.StyledText {
                text: item.busy ? (item.modelData.pairing ? "pairing…" : "linking…")
                    : item.failed ? "failed"
                    : item.modelData.connected
                        ? (item.modelData.batteryAvailable ? String(Math.round(item.modelData.battery * 100)).padStart(3, "0") : "link")
                    : item.modelData.paired ? "saved"
                    : "new"
                caps: true
                color: item.failed ? Theme.palette.error : Theme.palette.muted
                font.pixelSize: Theme.font.size - 3
                font.bold: true
                tracking: 1
            }
        }

        // Why the last pair/connect on this device failed, as BlueZ put it.
        C.StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            text: Theme.caps("err") + " " + root.control.error
            color: Theme.palette.error
            font.pixelSize: Theme.font.size - 2
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
            C.TextButton {
                text: "Connect"
                visible: item.modelData.paired && !item.modelData.connected
                enabled: !root.control.busy
                onClicked: root.control.connect(item.modelData)
            }
            C.TextButton {
                text: "Disconnect"
                visible: item.modelData.connected
                enabled: !item.busy
                onClicked: root.control.disconnect(item.modelData)
            }
            C.TextButton {
                text: "Pair"
                visible: !item.modelData.paired
                enabled: !root.control.busy
                onClicked: root.control.pair(item.modelData)
            }
            C.TextButton {
                text: "Forget"
                visible: item.modelData.paired
                enabled: !item.busy
                onClicked: {
                    root.expanded = "";
                    root.control.forget(item.modelData);
                }
            }
        }
    }

    // Header: power and scan
    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        C.SectionTitle {
            Layout.fillWidth: true
            text: "Bluetooth"
            code: root.control.adapterName
        }
        // Only the glyph spins; the key is disabled (no hover) while scanning.
        C.IconButton {
            icon: "\u{F0450}"
            visible: root.control.powered
            enabled: !root.control.discovering
            iconColor: root.control.discovering ? Theme.palette.accent : Theme.palette.fg
            onClicked: root.control.scan()

            NumberAnimation on iconRotation {
                running: root.control.discovering
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
                alwaysRunToEnd: true
            }
        }
        C.IconButton {
            icon: root.control.powered ? "\u{F00AF}" : "\u{F00B2}"
            lit: root.control.powered
            iconColor: Theme.palette.off
            onClicked: root.control.setEnabled(!root.control.powered)
        }
    }

    C.StyledText {
        Layout.leftMargin: 8
        text: "-- radio off --"
        color: Theme.palette.muted
        visible: !root.control.powered
    }
    C.StyledText {
        Layout.leftMargin: 8
        text: "-- no devices, scan to find some --"
        color: Theme.palette.muted
        visible: root.control.powered && root.control.devices.length === 0 && !root.control.discovering
    }

    Section {
        title: "Connected"
        devices: root.control.connected
    }
    Section {
        title: "Paired"
        devices: root.control.paired
    }
    Section {
        title: "Nearby"
        devices: root.control.nearby
    }
    C.StyledText {
        Layout.leftMargin: 8
        text: "scanning…"
        color: Theme.palette.muted
        visible: root.control.discovering && root.control.nearby.length === 0
    }
}
