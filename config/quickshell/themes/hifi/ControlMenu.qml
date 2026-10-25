import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components as C
import qs.core
import qs.modules.control as M

// A rack-mount service unit in a drawer, its sections framed in silkscreen
// and tagged:
//
//   SYSTEM   three moving-coil panel meters (CPU, GPU, RAM) on backlit cream
//            faces, their needles swinging and settling as the readings
//            come in; beside them a riveted nameplate (host, uptime, board,
//            kernel), the REBOOT lamp and the settings key.
//   UPDATES  a red seven-segment display, like the clock's: a count per
//            repository, rolling while it checks; CHECK and UPDATE keys.
//   USB      a strip of sockets, a plug in one for each device.
//   STORAGE  drive bays: each disk a caddy with its mount on a label, a
//            bargraph of how full it is, a key to look inside and, for
//            removable ones, a lever to pull it; a drive that isn't mounted
//            sits half out with a MOUNT key; a network share has a link lamp
//            (green mounted, amber idle, red failed) and CONNECT.
//   TOOLS    a key for each of your tools.
Item {
    id: root

    required property M.ControlPanel control

    readonly property var sys: control.system
    readonly property var upd: control.updates
    readonly property var disks: control.storage
    readonly property color silk: Theme.values.display?.silk ?? Theme.palette.dim
    readonly property color red: Theme.values.display?.clock ?? Theme.palette.error
    readonly property color ink: "#2a2119"
    readonly property real margin: 12

    implicitWidth: 780 + 2 * margin
    implicitHeight: Math.min(column.implicitHeight + 2 * margin, control.maxHeight)

    Flickable {
        id: flick

        x: root.margin
        y: root.margin
        width: root.width - 2 * root.margin
        height: root.height - 2 * root.margin
        contentHeight: column.implicitHeight
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: column

            // Clear of the scroll lamp when it scrolls.
            width: flick.width - (flick.interactive ? 10 : 0)
            spacing: 12

            // ── System ───────────────────────────────────────────────────────
            Framed {
                width: column.width
                name: "system"

                Row {
                    spacing: 12

                    PanelMeter {
                        name: "CPU"
                        detail: root.sys.cpu
                        value: root.sys.cpuUsage
                        reading: root.sys.cpuTemp >= 0 ? `${root.sys.cpuTemp}°C` : ""
                        hot: root.sys.cpuTemp >= 85
                    }
                    PanelMeter {
                        name: "GPU"
                        detail: root.sys.gpu.replace(/^NVIDIA /, "")
                        value: root.sys.gpuUsage
                        reading: root.sys.gpuTemp >= 0 ? `${root.sys.gpuTemp}°C` : ""
                        hot: root.sys.gpuTemp >= 85
                    }
                    PanelMeter {
                        name: "RAM"
                        detail: `${root.sys.gib(root.sys.memUsed)} / ${root.sys.gib(root.sys.memTotal)} GiB`
                        value: root.sys.memTotal > 0 ? root.sys.memUsed / root.sys.memTotal : 0
                        reading: root.sys.gpuMemTotal > 0 ? `VRAM ${(root.sys.gpuMemUsed / 1024).toFixed(1)}/${(root.sys.gpuMemTotal / 1024).toFixed(0)}` : ""
                    }

                    // The nameplate, riveted on.
                    Item {
                        width: 214
                        height: 122

                        Rectangle {
                            anchors.fill: parent
                            radius: 3
                            border.width: 1
                            border.color: "black"
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#d6d8dc" }
                                GradientStop { position: 1; color: "#9b9ea4" }
                            }
                        }
                        Image {
                            anchors {
                                fill: parent
                                margins: 1
                            }
                            source: Qt.resolvedUrl("brushed.png")
                            fillMode: Image.Tile
                            opacity: 0.35
                        }
                        Repeater {
                            model: [[0, 0], [1, 0], [0, 1], [1, 1]]

                            Rectangle {
                                required property var modelData

                                x: modelData[0] ? parent.width - 9 : 4
                                y: modelData[1] ? parent.height - 9 : 4
                                width: 5
                                height: 5
                                radius: 2.5
                                gradient: Gradient {
                                    GradientStop { position: 0; color: "#f4f5f7" }
                                    GradientStop { position: 1; color: "#5d6066" }
                                }
                            }
                        }
                        Column {
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Repeater {
                                model: [
                                    ["host", root.control.session.hostname],
                                    ["os", root.sys.os],
                                    ["up", root.control.session.uptimeText],
                                    ["board", root.sys.board],
                                    ["kernel", root.sys.kernel]
                                ]

                                Item {
                                    id: line

                                    required property var modelData

                                    width: 186
                                    height: 14

                                    Text {
                                        text: line.modelData[0].toUpperCase()
                                        color: Qt.alpha("#16171a", 0.6)
                                        font.family: Theme.font.family
                                        font.pixelSize: 8
                                        font.bold: true
                                        font.letterSpacing: 1
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        x: 44
                                        width: parent.width - x
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: line.modelData[1] || "--"
                                        elide: Text.ElideRight
                                        color: "#16171a"
                                        style: Text.Raised
                                        styleColor: Qt.alpha("white", 0.5)
                                        font.family: Theme.font.family
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Row {
                spacing: 12

                // ── Updates ──────────────────────────────────────────────────
                Framed {
                    id: updatesSection

                    name: "updates"

                    // While it checks, the counts roll.
                    property int roll: 0

                    Timer {
                        interval: 70
                        running: root.upd.checking && root.control.open
                        repeat: true
                        onTriggered: updatesSection.roll = (updatesSection.roll + 1) % 100
                    }

                    Column {
                        spacing: 10

                        // The display, behind smoked glass.
                        Item {
                            id: counts

                            readonly property var repos: Object.keys(root.upd.counts)

                            width: Math.max(1, repos.length) * 62 + 16
                            height: 74

                            Well {
                                id: glass

                                anchors.fill: parent
                                fill: Qt.tint(Theme.palette.bgAlt, Qt.alpha(root.red, 0.05))
                            }
                            Column {
                                x: 8
                                y: 8
                                spacing: 6
                                layer.enabled: (Theme.glow.opacity ?? 0) > 0
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: root.red
                                    shadowOpacity: Theme.glow.opacity ?? 0
                                    shadowBlur: 0.5
                                    blurMax: 12
                                    shadowHorizontalOffset: 0
                                    shadowVerticalOffset: 0
                                }

                                Row {
                                Repeater {
                                    model: counts.repos

                                    Column {
                                        id: repo

                                        required property string modelData
                                        readonly property int n: root.upd.checking ? updatesSection.roll : Math.min(99, root.upd.counts[modelData])
                                        readonly property bool lit: root.upd.checking || n > 0

                                        width: 62
                                        spacing: 4

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: repo.modelData.toUpperCase()
                                            color: repo.lit ? root.red : Qt.alpha(root.red, 0.25)
                                            font.family: Theme.font.family
                                            font.pixelSize: 8
                                            font.bold: true
                                        }
                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            height: 24
                                            spacing: 4
                                            transform: Matrix4x4 {
                                                matrix: Qt.matrix4x4(1, -0.1, 0, 1.2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                                            }

                                            Segment7 {
                                                width: 13
                                                height: parent.height
                                                color: root.red
                                                digit: repo.lit ? Math.floor(repo.n / 10) : 0
                                                opacity: repo.lit ? 1 : 0.3
                                            }
                                            Segment7 {
                                                width: 13
                                                height: parent.height
                                                color: root.red
                                                digit: repo.lit ? repo.n % 10 : 0
                                                opacity: repo.lit ? 1 : 0.3
                                            }
                                        }
                                    }
                                }
                                }
                                // How it went, in small segments under the counts.
                                Text {
                                    width: counts.width - 16
                                    horizontalAlignment: Text.AlignHCenter
                                    text: (root.upd.checking ? "checking"
                                        : root.upd.failed ? "check failed"
                                        : root.upd.count === 0 ? "up to date"
                                        : `last upgrade ${root.control.ago(root.upd.lastUpgrade)}`).toUpperCase()
                                    color: root.red
                                    font.family: Theme.font.family
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }
                            Gloss {
                                anchors {
                                    fill: parent
                                    margins: 1
                                }
                                roundness: glass.r
                            }
                        }
                        Row {
                            spacing: 14

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                PushSwitch {
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon: "\u{F0450}"
                                    latched: root.upd.checking
                                    onPushed: root.control.checkUpdates()
                                }
                                Silk {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "check"
                                }
                            }
                            C.TextButton {
                                anchors.verticalCenter: parent.verticalCenter
                                text: `update${root.upd.aurHelper ? " · " + root.upd.aurHelper : ""}`
                                enabled: root.upd.count > 0 && !root.upd.checking
                                onClicked: root.control.upgrade()
                            }
                        }
                    }
                }

                // ── USB ──────────────────────────────────────────────────────
                Framed {
                    id: usbSection

                    width: column.width - updatesSection.width - 12
                    height: updatesSection.height
                    name: "usb"

                    // A list on the display, rolled through with the
                    // thumbwheel beside it (or scrolled).
                    Row {
                        spacing: 10

                        Item {
                            id: usbScreen

                            readonly property real row: 17

                            width: usbSection.width - 2 * usbSection.pad - 10 - wheel.width
                            height: usbSection.height - 2 * usbSection.pad - 18

                            Well {
                                id: usbGlass

                                anchors.fill: parent
                                roundness: 3
                                fill: Qt.tint("#050807", Qt.alpha(Theme.palette.accent, 0.04))
                            }
                            C.StyledText {
                                x: 8
                                y: 6
                                text: root.disks.usb.length === 0 ? "nothing connected"
                                    : `${root.disks.usb.length} device${root.disks.usb.length === 1 ? "" : "s"}`
                                caps: true
                                color: Theme.palette.accent
                                glow: true
                                font.pixelSize: 10
                                font.bold: true
                            }
                            ListView {
                                id: usbList

                                x: 8
                                y: 24
                                width: parent.width - 16
                                // Whole rows only.
                                height: Math.floor((parent.height - y - 4) / usbScreen.row) * usbScreen.row
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                snapMode: ListView.SnapToItem
                                model: root.disks.usb

                                Behavior on contentY {
                                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                }

                                delegate: Item {
                                    required property var modelData

                                    width: ListView.view.width
                                    height: usbScreen.row

                                    C.StyledText {
                                        width: parent.width - deviceId.width - 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: parent.modelData.name
                                        caps: true
                                        elide: Text.ElideRight
                                        color: Qt.alpha(Theme.palette.accent, 0.8)
                                        font.pixelSize: 10
                                    }
                                    C.StyledText {
                                        id: deviceId

                                        anchors {
                                            right: parent.right
                                            verticalCenter: parent.verticalCenter
                                        }
                                        text: parent.modelData.id
                                        color: Qt.alpha(Theme.palette.accent, 0.5)
                                        font.pixelSize: 9
                                    }
                                }

                                // A row at a time.
                                function roll(step: int): void {
                                    const max = Math.max(0, contentHeight - height);
                                    contentY = Math.max(0, Math.min(max, Math.round(contentY / usbScreen.row + step) * usbScreen.row));
                                }
                            }
                            Gloss {
                                anchors {
                                    fill: parent
                                    margins: 1
                                }
                                roundness: usbGlass.r
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton
                                onWheel: wheel => usbList.roll(wheel.angleDelta.y > 0 ? -1 : 1)
                            }
                        }

                        // The thumbwheel: a knurled wheel in a slot, its
                        // ridges turning with the list. Click above or below
                        // its middle for a row up or down, or roll it.
                        Item {
                            id: wheel

                            width: 22
                            height: usbScreen.height

                            Well {
                                anchors.fill: parent
                                roundness: 4
                            }
                            Item {
                                anchors {
                                    fill: parent
                                    margins: 3
                                }
                                clip: true

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 3
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: "#0e0e10" }
                                        GradientStop { position: 0.5; color: wheelArea.containsMouse ? "#5a5c62" : "#47494e" }
                                        GradientStop { position: 1; color: "#0e0e10" }
                                    }
                                }
                                // The knurling, rolling as the list moves.
                                Repeater {
                                    model: Math.ceil(wheel.height / 5) + 2

                                    Rectangle {
                                        required property int index

                                        x: 2
                                        y: index * 5 - (usbList.contentY * 0.6) % 5 - 5
                                        width: parent.width - 4
                                        height: 1.5
                                        color: Qt.alpha("black", 0.55)
                                    }
                                }
                                // Shading: the wheel turns away top and bottom.
                                Rectangle {
                                    anchors.fill: parent
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: Qt.alpha("black", 0.7) }
                                        GradientStop { position: 0.3; color: "transparent" }
                                        GradientStop { position: 0.7; color: "transparent" }
                                        GradientStop { position: 1; color: Qt.alpha("black", 0.7) }
                                    }
                                }
                            }
                            MouseArea {
                                id: wheelArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => usbList.roll(mouse.y < height / 2 ? -1 : 1)
                                onWheel: wheel => usbList.roll(wheel.angleDelta.y > 0 ? -1 : 1)
                            }
                        }
                    }
                }
            }

            // ── Storage ──────────────────────────────────────────────────────
            Framed {
                width: column.width
                name: "storage"

                Column {
                    width: parent.width
                    spacing: 6

                    Text {
                        width: parent.width
                        text: `ERR ${root.disks.error}`
                        wrapMode: Text.Wrap
                        color: Theme.palette.error
                        font.family: Theme.font.family
                        font.pixelSize: 10
                        visible: root.disks.error !== ""
                    }
                    Repeater {
                        model: root.disks.mounted

                        DriveCaddy {
                            id: disk

                            required property var modelData

                            label: modelData.mount
                            detail: `${modelData.name} · ${modelData.fstype} · ${root.disks.human(modelData.size)}`
                            usage: modelData.size > 0 ? modelData.used / modelData.size : 0
                            reading: `${root.disks.human(modelData.avail)} free`

                            C.IconButton {
                                anchors.verticalCenter: parent.verticalCenter
                                size: 28
                                icon: "\u{F0349}"
                                onClicked: root.control.inspect(disk.modelData.mount)
                            }
                            Lever {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: disk.modelData.removable
                                onPulled: root.control.eject(disk.modelData.device)
                            }
                        }
                    }
                    Repeater {
                        model: root.disks.mountable

                        DriveCaddy {
                            id: loose

                            required property var modelData

                            out: true
                            label: modelData.name
                            detail: `${modelData.fstype} · ${root.disks.human(modelData.size)}`

                            C.TextButton {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "mount"
                                onClicked: root.control.mount(loose.modelData.device)
                            }
                        }
                    }
                    Repeater {
                        model: root.disks.network

                        Column {
                            id: share

                            required property var modelData
                            readonly property bool mounted: modelData.state === "mounted"

                            width: parent.width
                            spacing: 3

                            DriveCaddy {
                                label: share.modelData.mount
                                detail: `${share.modelData.source} · ${share.modelData.fstype}`
                                link: share.mounted ? Theme.palette.ok : share.modelData.state === "failed" ? Theme.palette.error
                                    : share.modelData.state === "idle" ? Theme.palette.warn : Qt.alpha(Theme.palette.muted, 0.01)
                                usage: share.mounted && share.modelData.size > 0 ? share.modelData.used / share.modelData.size : -1
                                reading: share.mounted && share.modelData.size > 0 ? `${root.disks.human(share.modelData.avail)} free`
                                    : share.modelData.state === "failed" ? "failed" : share.modelData.state === "idle" ? "idle" : "off"

                                C.TextButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "connect"
                                    visible: share.modelData.state === "idle" || share.modelData.state === "failed"
                                    onClicked: root.control.connect(share.modelData.mount)
                                }
                                C.IconButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    size: 28
                                    icon: "\u{F0349}"
                                    visible: share.mounted
                                    onClicked: root.control.inspect(share.modelData.mount)
                                }
                            }
                            Text {
                                x: 60
                                text: `systemd: ${share.modelData.reason}`
                                color: Theme.palette.error
                                font.family: Theme.font.family
                                font.pixelSize: 9
                                visible: share.modelData.state === "failed"
                            }
                        }
                    }
                }
            }

            // ── Tools ────────────────────────────────────────────────────────
            Framed {
                width: column.width
                name: "tools"
                visible: root.control.tools.length > 0

                Flow {
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: root.control.tools

                        C.TextButton {
                            required property var modelData

                            text: modelData.label
                            onClicked: root.control.run(modelData.command)
                        }
                    }
                }
            }
        }
    }

    C.ScrollLamp {
        view: flick
    }
}
