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

    // A section of the faceplate, outlined in silkscreen and tagged.
    component Section: Item {
        id: section

        property string name
        default property alias content: inner.data
        readonly property real pad: 14

        implicitWidth: inner.childrenRect.width + 2 * pad
        implicitHeight: inner.childrenRect.height + 2 * pad + 6

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 6
            radius: 4
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(root.silk, 0.55)
        }
        Legend {
            x: 12
            text: section.name
            size: 8
        }
        Item {
            id: inner

            x: section.pad
            y: section.pad + 6
            width: section.width - 2 * section.pad
        }
    }

    // A moving-coil panel meter: a cream face lit from behind, a printed arc
    // with its red zone, the needle on its pivot. `value` 0-1.
    component PanelMeter: Item {
        id: meter

        property real value: 0
        property string name
        property string detail
        property string reading
        property bool hot: false
        readonly property point pivot: Qt.point(width / 2, height - 18)
        readonly property real reach: 78
        property real needle: -50 + 100 * Math.max(0, Math.min(1, value))

        width: 170
        height: 122

        Behavior on needle {
            SpringAnimation { spring: 2.2; damping: 0.18; epsilon: 0.05 }
        }

        // The case and the backlit face.
        Rectangle {
            anchors.fill: parent
            radius: 5
            color: "#0b0b0c"
            border.width: 1
            border.color: "black"
        }
        Rectangle {
            id: face

            anchors {
                fill: parent
                margins: 5
            }
            radius: 3
            gradient: Gradient {
                GradientStop { position: 0; color: "#f3e7c4" }
                GradientStop { position: 1; color: "#d9c79a" }
            }
            clip: true

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.alpha("#7a4a10", 0.18) }
                    GradientStop { position: 0.5; color: Qt.alpha("#fff3c8", 0.25) }
                    GradientStop { position: 1; color: Qt.alpha("#7a4a10", 0.18) }
                }
            }
        }

        // The scale: an arc, ticks every tenth, the last stretch in red.
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: root.ink
                strokeWidth: 1.2
                fillColor: "transparent"
                PathAngleArc {
                    centerX: meter.pivot.x
                    centerY: meter.pivot.y
                    radiusX: meter.reach - 8
                    radiusY: meter.reach - 8
                    startAngle: -140
                    sweepAngle: 100 * 0.85
                }
            }
            ShapePath {
                strokeColor: "#c0281c"
                strokeWidth: 4
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                PathAngleArc {
                    centerX: meter.pivot.x
                    centerY: meter.pivot.y
                    radiusX: meter.reach - 6
                    radiusY: meter.reach - 6
                    startAngle: -140 + 85
                    sweepAngle: 15
                }
            }
        }
        Repeater {
            model: 11

            Item {
                required property int index

                x: meter.pivot.x
                y: meter.pivot.y
                rotation: -50 + index * 10

                Rectangle {
                    x: -0.6
                    y: -meter.reach + (parent.index % 5 === 0 ? 0 : 3)
                    width: parent.index % 5 === 0 ? 1.6 : 1.2
                    height: parent.index % 5 === 0 ? 10 : 6
                    color: parent.index >= 9 ? "#c0281c" : root.ink
                }
            }
        }
        Repeater {
            model: [0, 50, 100]

            Text {
                required property int modelData
                readonly property real a: (-50 + modelData) * Math.PI / 180

                x: meter.pivot.x + Math.sin(a) * (meter.reach + 9) - width / 2
                y: meter.pivot.y - Math.cos(a) * (meter.reach + 9) - height / 2
                text: modelData
                color: root.ink
                font.family: Theme.font.family
                font.pixelSize: 8
            }
        }

        // What it reads.
        Text {
            anchors {
                left: parent.left
                leftMargin: 12
                bottom: parent.bottom
                bottomMargin: 8
            }
            text: meter.name
            color: root.ink
            font.family: Theme.font.family
            font.pixelSize: 13
            font.bold: true
            font.letterSpacing: 2
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: meter.pivot.y - 34
            width: parent.width - 60
            horizontalAlignment: Text.AlignHCenter
            text: meter.detail
            elide: Text.ElideRight
            color: Qt.alpha(root.ink, 0.65)
            font.family: Theme.font.family
            font.pixelSize: 8
        }
        Text {
            anchors {
                right: parent.right
                rightMargin: 12
                bottom: parent.bottom
                bottomMargin: 9
            }
            text: meter.reading
            color: meter.hot ? "#c0281c" : root.ink
            font.family: Theme.font.family
            font.pixelSize: 9
            font.bold: true
        }

        // The needle and its pivot.
        Item {
            x: meter.pivot.x
            y: meter.pivot.y
            rotation: meter.needle

            Rectangle {
                x: -1
                y: -meter.reach + 2
                width: 2
                height: meter.reach + 6
                radius: 1
                antialiasing: true
                color: "#1a1612"
            }
        }
        Rectangle {
            x: meter.pivot.x - 7
            y: meter.pivot.y - 7
            width: 14
            height: 14
            radius: 7
            gradient: Gradient {
                GradientStop { position: 0; color: "#4a4b50" }
                GradientStop { position: 1; color: "#111113" }
            }
        }

        Gloss {
            anchors {
                fill: face
                margins: 1
            }
            roundness: 3
        }
    }

    // How full a disk is: a row of LEDs, green, then amber, then red.
    component Bargraph: Row {
        id: graph

        property real value: 0
        readonly property int count: 12

        spacing: 2

        Repeater {
            model: graph.count

            Rectangle {
                required property int index
                readonly property bool on: graph.value * graph.count > index + 0.25
                readonly property color tone: index >= 10 ? Theme.palette.error : index >= 8 ? Theme.palette.warn : Theme.palette.ok

                width: 5
                height: 10
                radius: 1
                color: on ? tone : Qt.alpha(tone, 0.12)
                border.width: 1
                border.color: Qt.alpha("black", 0.6)

                RectangularShadow {
                    anchors.fill: parent
                    radius: 1
                    blur: 6
                    color: Qt.alpha(parent.tone, 0.6)
                    visible: parent.on
                    z: -1
                }
            }
        }
    }

    // A drive caddy in its bay. `out` slides it half out of the bay.
    component Caddy: Item {
        id: caddy

        property string label
        property string detail
        property string reading
        property real usage: -1   // -1: no bargraph
        property bool out: false
        property color link: "transparent"  // its link lamp, for a share
        default property alias keys: keyRow.data

        width: parent?.width ?? 0
        height: 46

        // The bay.
        Rectangle {
            anchors.fill: parent
            radius: 3
            color: "#070707"
            border.width: 1
            border.color: "black"
        }
        // The caddy's front.
        Item {
            id: front

            x: caddy.out ? 26 : 3
            y: 3
            width: caddy.width - 6 - (caddy.out ? 23 : 0)
            height: caddy.height - 6

            RectangularShadow {
                anchors.fill: parent
                radius: 2
                offset.x: caddy.out ? -6 : 0
                blur: caddy.out ? 8 : 2
                color: Qt.alpha("black", 0.7)
            }
            Rectangle {
                anchors.fill: parent
                radius: 2
                border.width: 1
                border.color: "black"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#4a4c52" }
                    GradientStop { position: 0.12; color: "#33353a" }
                    GradientStop { position: 1; color: "#212226" }
                }
            }
            // Its vent.
            Image {
                x: 6
                y: 6
                width: 44
                height: parent.height - 12
                source: Qt.resolvedUrl("grille.png")
                fillMode: Image.Tile
                opacity: 0.7
            }
            Led {
                x: 20
                anchors.verticalCenter: parent.verticalCenter
                size: 8
                on: caddy.link.a > 0
                color: caddy.link.a > 0 ? caddy.link : Theme.palette.ok
                visible: caddy.link.a > 0 || caddy.usage < 0
            }
            Column {
                x: 60
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Legend {
                    text: caddy.label
                    size: 8
                }
                Text {
                    text: caddy.detail
                    color: Theme.palette.dim
                    font.family: Theme.font.family
                    font.pixelSize: 9
                }
            }
            Row {
                anchors {
                    right: keyRow.left
                    rightMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: caddy.reading
                    color: caddy.usage >= 0.85 ? Theme.palette.warn : Theme.palette.fg
                    font.family: Theme.font.family
                    font.pixelSize: 10
                    font.bold: true
                }
                Bargraph {
                    anchors.verticalCenter: parent.verticalCenter
                    value: caddy.usage
                    visible: caddy.usage >= 0
                }
            }
            Row {
                id: keyRow

                anchors {
                    right: parent.right
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                spacing: 8
            }
        }
    }

    // A removable drive's pull lever: pulled, it swings out and the drive
    // is let go.
    component Lever: Item {
        id: lever

        property real pull: 0

        signal pulled

        width: 34
        height: 28

        SequentialAnimation {
            id: pullOut

            NumberAnimation { target: lever; property: "pull"; to: 1; duration: 180; easing.type: Easing.OutCubic }
            ScriptAction { script: lever.pulled() }
            PauseAnimation { duration: 400 }
            NumberAnimation { target: lever; property: "pull"; to: 0; duration: 260; easing.type: Easing.InOutQuad }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 6
            radius: 3
            color: "#111113"
        }
        Item {
            anchors.centerIn: parent
            width: 30
            height: 8
            rotation: -38 * lever.pull
            transformOrigin: Item.Left

            Rectangle {
                anchors.fill: parent
                radius: 4
                border.width: 1
                border.color: "black"
                gradient: Gradient {
                    GradientStop { position: 0; color: leverArea.containsMouse ? "#f0f1f4" : "#d4d6db" }
                    GradientStop { position: 1; color: "#6a6c72" }
                }
            }
        }
        MouseArea {
            id: leverArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (!pullOut.running) pullOut.start()
        }
    }

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

            width: flick.width
            spacing: 12

            // ── System ───────────────────────────────────────────────────────
            Section {
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

                    // The nameplate, riveted on, and under it the REBOOT
                    // lamp and the settings key.
                    Column {
                        spacing: 12

                        Item {
                            width: 214
                            height: 84

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
                                spacing: 3

                                Repeater {
                                    model: [
                                        ["host", root.control.session.hostname],
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
                        Item {
                            width: 214
                            height: 30

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Led {
                                    anchors.verticalCenter: parent.verticalCenter
                                    size: 10
                                    on: root.sys.rebootPending
                                    pulse: root.sys.rebootPending
                                    color: Theme.palette.warn
                                }
                                Legend {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "reboot"
                                    size: 8
                                }
                            }
                            C.IconButton {
                                anchors {
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                }
                                size: 30
                                icon: "\u{F0493}"
                                onClicked: root.control.openSettings()
                            }
                        }
                    }
                }
            }

            Row {
                spacing: 12

                // ── Updates ──────────────────────────────────────────────────
                Section {
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
                            height: 58

                            Well {
                                id: glass

                                anchors.fill: parent
                                fill: Qt.tint(Theme.palette.bgAlt, Qt.alpha(root.red, 0.05))
                            }
                            Row {
                                x: 8
                                anchors.verticalCenter: parent.verticalCenter
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
                            Gloss {
                                anchors {
                                    fill: parent
                                    margins: 1
                                }
                                roundness: glass.r
                            }
                        }
                        Row {
                            spacing: 8

                            C.IconButton {
                                anchors.verticalCenter: parent.verticalCenter
                                size: 30
                                icon: "\u{F0450}"
                                enabled: !root.upd.checking
                                onClicked: root.control.checkUpdates()

                                NumberAnimation on iconRotation {
                                    running: root.upd.checking
                                    loops: Animation.Infinite
                                    from: 0
                                    to: 360
                                    duration: 900
                                    alwaysRunToEnd: true
                                }
                            }
                            C.TextButton {
                                anchors.verticalCenter: parent.verticalCenter
                                text: `update${root.upd.aurHelper ? " · " + root.upd.aurHelper : ""}`
                                visible: root.upd.count > 0 && !root.upd.checking
                                onClicked: root.control.upgrade()
                            }
                        }
                        Legend {
                            text: root.upd.checking ? "checking"
                                : root.upd.failed ? "check failed"
                                : root.upd.count === 0 ? "up to date"
                                : `last upgrade ${root.control.ago(root.upd.lastUpgrade)}`
                            size: 7
                        }
                    }
                }

                // ── USB ──────────────────────────────────────────────────────
                Section {
                    width: column.width - updatesSection.width - 12
                    height: updatesSection.height
                    name: "usb"

                    Flow {
                        width: parent.width
                        spacing: 10

                        Repeater {
                            model: Math.max(6, root.disks.usb.length)

                            Item {
                                id: socket

                                required property int index
                                readonly property var device: root.disks.usb[index] ?? null

                                width: 54
                                height: 92

                                // The port.
                                Rectangle {
                                    id: port

                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 6
                                    width: 30
                                    height: 14
                                    radius: 1
                                    color: "#050505"
                                    border.width: 2
                                    border.color: "#8d9096"

                                    Rectangle {
                                        x: 5
                                        y: 3
                                        width: parent.width - 10
                                        height: 4
                                        color: "#2a64c8"
                                    }
                                }
                                // A plug in it, its boot and cable going down.
                                Item {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 34
                                    height: 58
                                    visible: socket.device !== null

                                    Rectangle {
                                        x: 1
                                        y: 4
                                        width: 32
                                        height: 16
                                        radius: 1
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0; color: "#7c7f85" }
                                            GradientStop { position: 0.5; color: "#e1e3e7" }
                                            GradientStop { position: 1; color: "#6c6f75" }
                                        }
                                    }
                                    Rectangle {
                                        y: 18
                                        width: 34
                                        height: 26
                                        radius: 3
                                        color: "#151517"
                                        border.width: 1
                                        border.color: "black"

                                        Rectangle {
                                            x: 3
                                            y: 1
                                            width: parent.width - 6
                                            height: 1
                                            color: Qt.alpha("white", 0.18)
                                        }
                                    }
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 44
                                        width: 8
                                        height: 14
                                        color: "#101012"
                                    }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 66
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: socket.device ? socket.device.name : ""
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    color: Theme.palette.dim
                                    font.family: Theme.font.family
                                    font.pixelSize: 8
                                }
                            }
                        }
                    }
                }
            }

            // ── Storage ──────────────────────────────────────────────────────
            Section {
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

                        Caddy {
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

                        Caddy {
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

                            Caddy {
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
            Section {
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
