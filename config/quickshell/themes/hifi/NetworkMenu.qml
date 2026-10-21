import QtQuick
import QtQuick.Effects
import qs.components as C
import qs.core
import qs.modules.network as M

// A communications receiver in a drawer, the Bluetooth console's twin.
//
// WIRED: an Ethernet jack per link, a cable plugged into the ones that are
// up (their green LED lit), and their state on a small display.
//
// WI-FI: the stations on the display, strongest first, with their lock and
// how strong they come in; the one picked has the pointer. The TUNING knob
// steps through them (or scroll, or click one), the SIGNAL meter reads the
// one picked. A rocker powers the radio; the SCAN switch stays in while it
// scans. Under the display, the passphrase field (it takes typing for a new
// secured station) and CONNECT, DISCONNECT and FORGET, all there whether
// they apply or not.
Item {
    id: root

    required property M.NetworkPanel control

    readonly property real margin: 12
    readonly property var nets: control.wifiEnabled ? control.networks : []
    // The station picked, kept by its path as the list reorders.
    property string pickedPath: ""
    readonly property int current: {
        const i = nets.findIndex(n => n.path === pickedPath);
        return i >= 0 ? i : nets.findIndex(n => n.connected) >= 0 ? nets.findIndex(n => n.connected) : nets.length > 0 ? 0 : -1;
    }
    readonly property var station: current >= 0 ? nets[current] : null
    readonly property bool asking: control.needsPassphrase(station) && !(station?.connected ?? false)

    implicitWidth: column.implicitWidth + 2 * margin
    implicitHeight: column.implicitHeight + 2 * margin

    function pick(index: int): void {
        if (index < 0 || index >= nets.length)
            return;
        pickedPath = nets[index].path;
        passphrase.text = "";
        if (asking)
            passphrase.focusInput();
    }
    function join(): void {
        if (!station || control.busy || (asking && passphrase.text.length < 8))
            return;
        control.connect(station, passphrase.text);
        passphrase.text = "";
    }

    Connections {
        target: root.control

        function onOpenChanged(): void {
            root.pickedPath = "";
            passphrase.text = "";
        }
    }

    // An Ethernet jack: its shield, the latch slot, its two LEDs. Plugged,
    // a cable's in it.
    component Jack: Item {
        id: jack

        property bool plugged: false

        width: 44
        height: 52

        Rectangle {
            y: 6
            width: parent.width
            height: 34
            radius: 2
            border.width: 1
            border.color: "black"
            gradient: Gradient {
                GradientStop { position: 0; color: "#c9cbd0" }
                GradientStop { position: 1; color: "#7c7f85" }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 30
                height: 22
                color: "#060606"

                // The contacts, and the slot for the latch.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 3
                    spacing: 1.5

                    Repeater {
                        model: 8

                        Rectangle {
                            width: 2
                            height: 5
                            color: "#b8913a"
                        }
                    }
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height - 6
                    width: 12
                    height: 6
                    color: "#1b1b1d"
                }
            }
        }
        // The cable's plug, clear plastic, and the cable going down.
        Item {
            visible: jack.plugged

            Rectangle {
                x: 9
                y: 12
                width: 26
                height: 24
                radius: 2
                color: Qt.alpha("#d7e3ea", 0.55)
                border.width: 1
                border.color: Qt.alpha("white", 0.6)
            }
            Rectangle {
                x: 14
                y: 30
                width: 16
                height: 22
                radius: 3
                color: "#2f63b3"
                border.width: 1
                border.color: Qt.alpha("black", 0.6)
            }
        }
        Led {
            x: 2
            y: 0
            size: 6
            on: jack.plugged
            color: Theme.palette.ok
        }
        Led {
            x: jack.width - width - 2
            y: 0
            size: 6
            on: false
            color: Theme.palette.warn
        }
    }

    Column {
        id: column

        x: root.margin
        y: root.margin
        spacing: 12

        // ── Wired ────────────────────────────────────────────────────────────
        Framed {
            width: wifi.width
            name: "wired"
            visible: root.control.wired.length > 0

            Row {
                spacing: 14

                Repeater {
                    model: root.control.wired

                    Jack {
                        required property var modelData

                        plugged: modelData.connected
                    }
                }
                Readout {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 260
                    height: 40
                    size: 12
                    // A line per link (the second line holds the rest).
                    readonly property var links: root.control.wired.map(l => `${l.name} ${l.connected ? "link" : "no cable"}`)

                    line1: links[0] ?? ""
                    line2: links.slice(1).join(" · ")
                }
            }
        }

        // ── Wi-Fi ────────────────────────────────────────────────────────────
        Framed {
            id: wifi

            name: "wi-fi"

            Row {
                spacing: 16

                Column {
                    spacing: 10

                    ListDisplay {
                        width: 380
                        height: 222
                        title: !root.control.wifiEnabled ? "radio off"
                            : root.nets.length === 0 ? (root.control.scanning ? "scanning" : "no stations")
                            : `${root.nets.length} station${root.nets.length === 1 ? "" : "s"}`
                        rows: root.nets.map(n => ({
                            text: n.name,
                            glyph: n.secure ? "\u{F033E}" : "",
                            tail: root.control.pending === n.name ? "linking"
                                : n.connected ? `link ${n.strength}%`
                                : `${n.known ? "saved " : ""}${n.strength}%`,
                            lit: n.connected
                        }))
                        current: root.current
                        status: root.control.error ? `err ${root.control.error}`
                            : root.control.scanning ? "scanning"
                            : root.asking ? "passphrase"
                            : ""
                        alarm: root.control.error !== ""
                        onPicked: index => root.pick(index)
                    }
                    C.TextField {
                        id: passphrase

                        width: 380
                        prompt: ""
                        placeholder: root.asking ? "passphrase" : ""
                        echoMode: TextInput.Password
                        // Always there; it only takes typing when the
                        // station picked needs a passphrase.
                        enabled: root.asking
                        opacity: root.asking ? 1 : 0.45
                        onAccepted: root.join()
                    }
                    Row {
                        spacing: 8

                        C.TextButton {
                            text: "connect"
                            enabled: root.station !== null && !root.station.connected && !root.control.busy
                                && (!root.asking || passphrase.text.length >= 8)
                            onClicked: root.join()
                        }
                        C.TextButton {
                            text: "disconnect"
                            enabled: (root.station?.connected ?? false) && !root.control.busy
                            onClicked: root.control.disconnect()
                        }
                        C.TextButton {
                            text: "forget"
                            enabled: (root.station?.known ?? false) && !root.control.busy
                            onClicked: root.control.forget(root.station)
                        }
                    }
                }

                // The meter, the knob, the switches.
                Column {
                    spacing: 14

                    PanelMeter {
                        name: "SIG"
                        detail: root.station?.name ?? ""
                        value: (root.station?.strength ?? 0) / 100
                        reading: root.station ? `${root.station.strength}%` : ""
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 22

                        Column {
                            spacing: 6

                            TuningKnob {
                                anchors.horizontalCenter: parent.horizontalCenter
                                live: root.nets.length > 1
                                onStepped: step => root.pick(Math.max(0, Math.min(root.nets.length - 1, root.current + step)))
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

                                        on: root.control.wifiEnabled
                                        hovered: powerArea.containsMouse
                                        lit: root.control.wifiEnabled
                                    }
                                    MouseArea {
                                        id: powerArea

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.control.setWifiEnabled(!root.control.wifiEnabled)
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
                                    latched: root.control.scanning
                                    opacity: root.control.wifiEnabled ? 1 : 0.45
                                    enabled: root.control.wifiEnabled
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
}
