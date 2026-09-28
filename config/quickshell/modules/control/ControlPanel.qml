import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services

// Control center: system readouts, pending updates, storage, USB devices and
// tool keys. Live readings only run while it's open. Scrolls if taller than
// the screen allows (`maxHeight`).
Item {
    id: root

    property bool open: false
    property real maxHeight: 900

    // Emitted after launching something, so the bar closes and the new window
    // gets focus.
    signal done

    function run(command: string): void {
        Launcher.runInTerminal(command);
        done();
    }

    width: 400
    implicitHeight: Math.min(column.implicitHeight, maxHeight)
    height: implicitHeight

    onOpenChanged: {
        Sysinfo.active = open;
        Storage.active = open;
        if (open) {
            Session.refresh();
            Updates.check(false);
            Server.check();
        }
    }

    function percent(v: real): string {
        return String(Math.round(Math.max(0, Math.min(1, v)) * 100)).padStart(3, "0");
    }

    function ago(iso: string): string {
        if (!iso)
            return "never";
        const days = Math.floor((Date.now() - new Date(iso).getTime()) / 86400000);
        return days <= 0 ? "today" : days === 1 ? "yesterday" : `${days} days ago`;
    }

    // "CPU  AMD Ryzen 5 5600G" style label + value line.
    component Fact: RowLayout {
        property string label
        property string value
        property alias trailing: extra.data

        Layout.fillWidth: true
        spacing: 10

        StyledText {
            Layout.preferredWidth: 52
            text: parent.label
            color: Config.colors.muted
            font.pixelSize: Config.font.size - 3
            font.bold: true
            font.letterSpacing: 1.5
        }
        StyledText {
            Layout.fillWidth: true
            text: parent.value
            elide: Text.ElideRight
        }
        RowLayout {
            id: extra

            spacing: 6
        }
    }

    // Read-only meter with its readouts: [meter ────] 012%  54°
    component Level: RowLayout {
        property real value: 0
        property string extra: ""

        Layout.fillWidth: true
        Layout.leftMargin: 62
        spacing: 8

        Meter {
            Layout.fillWidth: true
            implicitHeight: 8
            interactive: false
            segments: 24
            value: parent.value
            color: parent.value >= 0.85 ? Config.colors.warn : Config.colors.accent
        }
        StyledText {
            text: root.percent(parent.value)
            color: Config.colors.dim
            font.pixelSize: Config.font.size - 2
            font.bold: true
        }
        StyledText {
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
            text: parent.extra
            color: Config.colors.muted
            font.pixelSize: Config.font.size - 2
            visible: text !== ""
        }
    }

    Flickable {
        id: flick

        anchors.fill: parent
        contentHeight: column.implicitHeight
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: column

            width: flick.width - 6
            spacing: 8

            // ── System ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                SectionTitle {
                    text: "SYSTEM"
                    code: `${Session.hostname.toUpperCase()} · UP ${Session.uptimeText}`
                }
                IconButton {
                    size: 24
                    icon: "\u{F0493}"
                    onClicked: Panels.open("settings")
                }
            }
            Fact {
                label: "CPU"
                value: Sysinfo.cpu
            }
            Level {
                value: Sysinfo.cpuUsage
                extra: Sysinfo.cpuTemp >= 0 ? `${Sysinfo.cpuTemp}°` : ""
            }
            Fact {
                label: "GPU"
                value: Sysinfo.gpu.replace(/^NVIDIA /, "")
            }
            Level {
                value: Sysinfo.gpuUsage
                extra: Sysinfo.gpuTemp >= 0 ? `${Sysinfo.gpuTemp}°` : ""
            }
            Fact {
                label: "RAM"
                value: `${Sysinfo.gib(Sysinfo.memUsed)} / ${Sysinfo.gib(Sysinfo.memTotal)} GiB`
                    + (Sysinfo.gpuMemTotal > 0 ? `  · VRAM ${(Sysinfo.gpuMemUsed / 1024).toFixed(1)} / ${(Sysinfo.gpuMemTotal / 1024).toFixed(0)}` : "")
            }
            Level {
                value: Sysinfo.memTotal > 0 ? Sysinfo.memUsed / Sysinfo.memTotal : 0
            }
            Fact {
                label: "BOARD"
                value: Sysinfo.board
            }
            Fact {
                label: "KERNEL"
                value: Sysinfo.kernel

                trailing: Tag {
                    text: "REBOOT PENDING"
                    visible: Sysinfo.rebootPending
                }
            }

            // ── Updates ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 4

                SectionTitle {
                    text: "UPDATES"
                    code: Updates.checking ? "" : Updates.count > 0 ? String(Updates.count).padStart(2, "0") : "--"
                }
                IconButton {
                    size: 24
                    icon: "\u{F0450}"
                    enabled: !Updates.checking
                    iconColor: Updates.checking ? Config.colors.accent : Config.colors.fg
                    onClicked: Updates.check(true)

                    NumberAnimation on iconRotation {
                        running: Updates.checking
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                        alwaysRunToEnd: true
                    }
                }
            }
            // One readout per repository, in equal cells: stencilled name over a count.
            Item {
                id: repoReadouts

                readonly property var repos: Object.keys(Updates.counts)

                Layout.fillWidth: true
                implicitHeight: 44
                visible: !Updates.failed

                Repeater {
                    model: repoReadouts.repos

                    Column {
                        required property string modelData
                        required property int index
                        readonly property int n: Updates.counts[modelData]

                        x: index * repoReadouts.width / repoReadouts.repos.length
                        width: repoReadouts.width / repoReadouts.repos.length
                        spacing: 0

                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: parent.modelData.toUpperCase()
                            color: Config.colors.muted
                            font.pixelSize: Config.font.size - 3
                            font.bold: true
                            font.letterSpacing: 1.5
                        }
                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: Updates.checking ? "··" : String(parent.n).padStart(2, "0")
                            color: parent.n > 0 && !Updates.checking ? Config.colors.accent : Config.colors.surface
                            glow: parent.n > 0 && !Updates.checking
                            font.pixelSize: 22
                            font.bold: true
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                spacing: 10

                StyledText {
                    Layout.fillWidth: true
                    text: Updates.checking ? "checking…"
                        : Updates.failed ? "-- check failed (offline?) --"
                        : Updates.count === 0 ? "-- up to date --"
                        : `last upgrade ${root.ago(Updates.lastUpgrade)}`
                    color: Config.colors.muted
                    font.pixelSize: Config.font.size - 2
                }
                TextButton {
                    text: `\u{F06B0}  update${Updates.aurHelper ? " (" + Updates.aurHelper + ")" : ""}`
                    visible: Updates.count > 0 && !Updates.checking
                    onClicked: {
                        Updates.upgrade();
                        root.done();
                    }
                }
            }

            // ── Storage ──────────────────────────────────────────────────────
            SectionTitle {
                Layout.topMargin: 6
                text: "STORAGE"
                code: String(Storage.mounted.length + Storage.network.length).padStart(2, "0")
            }
            StyledText {
                Layout.leftMargin: 8
                text: "ERR " + Storage.error
                color: Config.colors.error
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                visible: Storage.error !== ""
            }
            Repeater {
                model: Storage.mounted

                ColumnLayout {
                    id: disk

                    required property var modelData
                    readonly property real usage: modelData.size > 0 ? modelData.used / modelData.size : 0

                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        StyledText {
                            Layout.preferredWidth: 52
                            text: disk.modelData.removable ? "\u{F129E}" : "\u{F02CA}"
                            color: disk.usage >= 0.85 ? Config.colors.warn : Config.colors.dim
                        }
                        StyledText {
                            text: disk.modelData.mount
                            font.bold: true
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: `${disk.modelData.name} · ${disk.modelData.fstype}`
                            color: Config.colors.muted
                            font.pixelSize: Config.font.size - 2
                            elide: Text.ElideRight
                        }
                        StyledText {
                            text: `${Storage.human(disk.modelData.avail)} free`
                            color: disk.usage >= 0.85 ? Config.colors.warn : Config.colors.dim
                            font.pixelSize: Config.font.size - 2
                            font.bold: true
                        }
                        IconButton {
                            size: 22
                            icon: "\u{F07AF}"
                            iconColor: Config.colors.dim
                            onClicked: root.run(`ncdu -x '${disk.modelData.mount}'`)
                        }
                        IconButton {
                            size: 22
                            icon: "\u{F01EA}"
                            iconColor: Config.colors.dim
                            visible: disk.modelData.removable
                            onClicked: Storage.eject(disk.modelData.device)
                        }
                    }
                    Level {
                        value: disk.usage
                        extra: Storage.human(disk.modelData.size)
                    }
                }
            }
            Repeater {
                model: Storage.mountable

                RowLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 10

                    StyledText {
                        Layout.preferredWidth: 52
                        text: "\u{F129E}"
                        color: Config.colors.muted
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: `${modelData.name} · ${modelData.fstype} · ${Storage.human(modelData.size)}`
                        color: Config.colors.dim
                        elide: Text.ElideRight
                    }
                    TextButton {
                        text: "mount"
                        onClicked: Storage.mount(modelData.device)
                    }
                }
            }

            // Network shares (systemd mount/automount units)
            Repeater {
                model: Storage.network

                ColumnLayout {
                    id: share

                    required property var modelData
                    readonly property bool mounted: modelData.state === "mounted"
                    readonly property real usage: modelData.size > 0 ? modelData.used / modelData.size : 0

                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        StyledText {
                            Layout.preferredWidth: 52
                            text: "\u{F08F3}"
                            color: share.modelData.state === "failed" ? Config.colors.warn
                                : share.mounted ? Config.colors.dim : Config.colors.muted
                        }
                        StyledText {
                            text: share.modelData.mount
                            font.bold: true
                            color: share.mounted ? Config.colors.fg : Config.colors.dim
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: `${share.modelData.source} · ${share.modelData.fstype}`
                            color: Config.colors.muted
                            font.pixelSize: Config.font.size - 2
                            elide: Text.ElideRight
                        }
                        StyledText {
                            text: `${Storage.human(share.modelData.avail)} free`
                            color: share.usage >= 0.85 ? Config.colors.warn : Config.colors.dim
                            font.pixelSize: Config.font.size - 2
                            font.bold: true
                            visible: share.mounted && share.modelData.size > 0
                        }
                        Tag {
                            text: share.modelData.state === "failed" ? "FAILED" : share.modelData.state === "idle" ? "IDLE" : "OFF"
                            fill: share.modelData.state === "failed" ? Config.colors.warn : Config.colors.surface
                            textColor: share.modelData.state === "failed" ? Config.colors.shadow : Config.colors.dim
                            visible: !share.mounted
                        }
                        TextButton {
                            text: "connect"
                            visible: share.modelData.state === "idle" || share.modelData.state === "failed"
                            onClicked: Storage.connect(share.modelData.mount)
                        }
                        IconButton {
                            size: 22
                            icon: "\u{F07AF}"
                            iconColor: Config.colors.dim
                            visible: share.mounted
                            onClicked: root.run(`ncdu -x '${share.modelData.mount}'`)
                        }
                    }
                    Level {
                        value: share.usage
                        extra: Storage.human(share.modelData.size)
                        visible: share.mounted && share.modelData.size > 0
                    }
                    StyledText {
                        Layout.leftMargin: 62
                        text: `systemd: ${share.modelData.reason}`
                        color: Config.colors.warn
                        font.pixelSize: Config.font.size - 3
                        visible: share.modelData.state === "failed"
                    }
                }
            }

            // ── Server ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 4
                visible: Server.configured

                SectionTitle {
                    text: "SERVER"
                    code: (Config.server.name || Config.server.host).toUpperCase()
                }
                TextButton {
                    text: "\u{F018D}  ssh"
                    visible: Config.server.ssh !== ""
                    onClicked: root.run(Config.server.ssh)
                }
                IconButton {
                    size: 24
                    icon: "\u{F0450}"
                    enabled: !Server.checking
                    iconColor: Server.checking ? Config.colors.accent : Config.colors.fg
                    onClicked: Server.check()

                    NumberAnimation on iconRotation {
                        running: Server.checking
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                        alwaysRunToEnd: true
                    }
                }
            }
            // General lamp: the machine itself.
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: Server.configured

                Item {
                    Layout.preferredWidth: 52
                    implicitHeight: 12

                    Lamp {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 10
                        implicitHeight: 10
                        on: Server.host !== ""
                        litColor: Server.host === "up" ? (Server.allUp ? Config.colors.ok : Config.colors.warn) : Config.colors.warn
                    }
                }
                StyledText {
                    text: Config.server.name || Config.server.host
                    font.bold: true
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Config.server.host
                    color: Config.colors.muted
                    font.pixelSize: Config.font.size - 2
                    elide: Text.ElideRight
                }
                Tag {
                    text: Server.checking || Server.host === "" ? "CHECKING" : Server.host === "up" ? "ONLINE" : "OFFLINE"
                    fill: Server.host === "down" ? Config.colors.warn : Server.host === "up" ? Config.colors.ok : Config.colors.surface
                    textColor: Server.host === "" ? Config.colors.dim : Config.colors.shadow
                }
            }
            // A lamp per service; click to open it.
            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: 62
                spacing: 6
                visible: Server.configured && Config.server.services.length > 0

                Repeater {
                    model: Config.server.services

                    Item {
                        id: svc

                        required property var modelData
                        readonly property string state: Server.services[modelData.name] ?? ""

                        implicitWidth: svcRow.implicitWidth + 20
                        implicitHeight: 26

                        Chamfer {
                            anchors.fill: parent
                            cut: 5
                            fill: svcArea.containsMouse ? Config.colors.surface : Config.colors.bgAlt
                            stroke: Config.colors.border
                        }
                        Row {
                            id: svcRow

                            anchors.centerIn: parent
                            spacing: 8

                            Lamp {
                                anchors.verticalCenter: parent.verticalCenter
                                on: svc.state !== ""
                                litColor: svc.state === "up" ? Config.colors.ok : Config.colors.warn
                            }
                            StyledText {
                                text: svc.modelData.name
                                color: svc.state === "down" ? Config.colors.warn : Config.colors.dim
                                font.pixelSize: Config.font.size - 1
                            }
                        }
                        MouseArea {
                            id: svcArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Server.open(svc.modelData.url);
                                root.done();
                            }
                        }
                    }
                }
            }

            // ── USB ──────────────────────────────────────────────────────────
            SectionTitle {
                Layout.topMargin: 6
                text: "USB"
                code: String(Storage.usb.length).padStart(2, "0")
            }
            Placeholder {
                text: "-- nothing connected --"
                visible: Storage.usb.length === 0
            }
            Repeater {
                model: Storage.usb

                RowLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 10

                    StyledText {
                        Layout.preferredWidth: 52
                        text: "\u{F0553}"
                        color: Config.colors.dim
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: Config.colors.dim
                        elide: Text.ElideRight
                    }
                    StyledText {
                        text: modelData.id
                        color: Config.colors.muted
                        font.pixelSize: Config.font.size - 3
                    }
                }
            }

            // ── Tools ────────────────────────────────────────────────────────
            SectionTitle {
                Layout.topMargin: 6
                text: "TOOLS"
            }
            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: Config.controlCenter.tools

                    TextButton {
                        required property var modelData

                        text: `\u{F018D}  ${modelData.label}`
                        onClicked: root.run(modelData.command)
                    }
                }
            }
        }
    }

    // Scroll position lamp, when scrolling is possible.
    ScrollLamp {
        view: flick
    }
}
