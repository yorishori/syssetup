import QtQuick
import Quickshell.Bluetooth
import qs.components as C
import qs.core
import qs.modules.bluetooth as M

// A pairing console in a drawer, the network receiver's twin: the devices on
// its display in groups (CONNECTED, PAIRED, NEARBY), the one picked with the
// pointer; the TUNING knob steps through them (or scroll, or click one),
// the BATTERY meter reads the one picked. A rocker powers the radio; the
// SCAN switch stays in while it looks for devices. Under the display,
// CONNECT, DISCONNECT, PAIR and FORGET, there whether they apply or not.
Item {
    id: root

    required property M.BluetoothPanel control

    readonly property real margin: 12
    // The display's rows: a heading, then its devices, per group.
    readonly property var groups: [["connected", control.connected], ["paired", control.paired], ["nearby", control.nearby]]
        .filter(g => g[1].length > 0)
    readonly property var entries: groups.reduce((all, g) => all.concat([{ heading: g[0] }], g[1].map(d => ({ device: d }))), [])
    // The device picked, kept by its address as the lists change.
    property string pickedAddress: ""
    readonly property int current: {
        const i = entries.findIndex(e => e.device?.address === pickedAddress);
        return i >= 0 ? i : entries.findIndex(e => e.device);
    }
    readonly property BluetoothDevice device: current >= 0 ? entries[current].device : null
    readonly property bool deviceBusy: control.busyWith(device)

    implicitWidth: unit.implicitWidth + 2 * margin
    implicitHeight: unit.implicitHeight + 2 * margin

    function pick(index: int): void {
        if (entries[index]?.device)
            pickedAddress = entries[index].device.address;
    }

    Connections {
        target: root.control

        function onOpenChanged(): void {
            root.pickedAddress = "";
        }
    }

    Framed {
        id: unit

        x: root.margin
        y: root.margin
        name: "bluetooth"

        Row {
            spacing: 16

            Column {
                spacing: 10

                ListDisplay {
                    id: screen

                    lit: root.control.powered
                    width: 380
                    height: 266
                    title: !root.control.powered ? "radio off"
                        : root.entries.length === 0 ? (root.control.discovering ? "scanning" : "no devices")
                        : root.control.adapterName || "bluetooth"
                    rows: root.entries.map(e => e.heading ? { heading: true, text: e.heading } : {
                        text: e.device.name,
                        glyph: root.control.glyph(e.device),
                        tail: root.control.busyWith(e.device) ? (e.device.pairing ? "pairing" : "linking")
                            : root.control.failed(e.device) ? "failed"
                            : e.device.connected ? (e.device.batteryAvailable ? `${Math.round(e.device.battery * 100)}%` : "link")
                            : e.device.paired ? "saved" : "new",
                        lit: e.device.connected
                    })
                    current: root.current
                    status: root.control.failed(root.device) ? `err ${root.control.error}`
                        : root.control.discovering ? "scanning" : ""
                    alarm: root.control.failed(root.device)
                    onPicked: index => root.pick(index)
                }
                Row {
                    spacing: 8

                    C.TextButton {
                        text: "connect"
                        enabled: (root.device?.paired ?? false) && !root.device.connected && !root.control.busy
                        onClicked: root.control.connect(root.device)
                    }
                    C.TextButton {
                        text: "disconnect"
                        enabled: (root.device?.connected ?? false) && !root.deviceBusy
                        onClicked: root.control.disconnect(root.device)
                    }
                    C.TextButton {
                        text: "pair"
                        enabled: root.device !== null && !root.device.paired && !root.control.busy
                        onClicked: root.control.pair(root.device)
                    }
                    C.TextButton {
                        text: "forget"
                        enabled: (root.device?.paired ?? false) && !root.deviceBusy
                        onClicked: {
                            const d = root.device;
                            root.pickedAddress = "";
                            root.control.forget(d);
                        }
                    }
                }
            }

            // The meter, the knob, the switches.
            Column {
                spacing: 14

                PanelMeter {
                    readonly property bool reads: root.device?.batteryAvailable ?? false

                    lit: root.control.powered
                    name: "BATT"
                    detail: root.device?.name ?? ""
                    value: reads ? root.device.battery : 0
                    reading: reads ? `${Math.round(root.device.battery * 100)}%` : ""
                    hot: reads && root.device.battery <= 0.2
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 22

                    Column {
                        spacing: 6

                        TuningKnob {
                            position: Math.max(0, root.current)
                            anchors.horizontalCenter: parent.horizontalCenter
                            live: root.entries.filter(e => e.device).length > 1
                            onStepped: step => root.pick(screen.next(root.current, step))
                        }
                        Silk {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "tuning"
                        }
                    }
                    Column {
                        spacing: 12

                        Row {
                            spacing: 8

                            Item {
                                width: power.implicitWidth
                                height: power.implicitHeight

                                Rocker {
                                    id: power

                                    on: root.control.powered
                                    hovered: powerArea.containsMouse
                                    lit: root.control.powered
                                }
                                MouseArea {
                                    id: powerArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.control.setEnabled(!root.control.powered)
                                }
                            }
                            Silk {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "power"
                            }
                        }
                        Row {
                            spacing: 8

                            PushSwitch {
                                icon: "\u{F0450}"
                                latched: root.control.discovering
                                opacity: root.control.powered ? 1 : 0.45
                                enabled: root.control.powered
                                onPushed: root.control.scan()
                            }
                            Silk {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "scan"
                            }
                        }
                    }
                }
            }
        }
    }
}
