import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core
import qs.modules.control as M

// System (hostname, uptime; CPU, GPU, RAM with their levels; board, kernel),
// updates per repository, storage (disks, drives to mount, network shares),
// USB devices and tool keys, in one scrolling column.
Item {
    id: root

    required property M.ControlPanel control

    implicitWidth: 400
    implicitHeight: Math.min(column.implicitHeight, control.maxHeight)

    // "CPU  AMD Ryzen 5 5600G" style label + value line.
    component Fact: RowLayout {
        property string label
        property string value
        property alias trailing: extra.data

        Layout.fillWidth: true
        spacing: 10

        C.StyledText {
            Layout.preferredWidth: 52
            text: parent.label
            caps: true
            color: Theme.palette.muted
            font.pixelSize: Theme.font.size - 3
            font.bold: true
            tracking: 1.5
        }
        C.StyledText {
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

        C.Meter {
            Layout.fillWidth: true
            implicitHeight: 8
            interactive: false
            segments: 24
            value: parent.value
            color: parent.value >= 0.85 ? Theme.palette.warn : Theme.palette.accent
        }
        C.StyledText {
            text: root.control.percent(parent.value)
            color: Theme.palette.dim
            font.pixelSize: Theme.font.size - 2
            font.bold: true
        }
        C.StyledText {
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
            text: parent.extra
            color: Theme.palette.muted
            font.pixelSize: Theme.font.size - 2
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

                C.SectionTitle {
                    text: "System"
                    code: `${root.control.hostname} · up ${root.control.uptimeText}`
                }
                C.IconButton {
                    size: 24
                    icon: "\u{F0493}"
                    onClicked: root.control.openSettings()
                }
            }
            Fact {
                label: "CPU"
                value: root.control.cpuName
            }
            Level {
                value: root.control.cpuUsage
                extra: root.control.cpuTemp >= 0 ? `${root.control.cpuTemp}°` : ""
            }
            Fact {
                label: "GPU"
                value: root.control.gpuName
            }
            Level {
                value: root.control.gpuUsage
                extra: root.control.gpuTemp >= 0 ? `${root.control.gpuTemp}°` : ""
            }
            Fact {
                label: "RAM"
                value: `${root.control.gib(root.control.memUsed)} / ${root.control.gib(root.control.memTotal)} GiB`
                    + (root.control.gpuMemTotal > 0 ? `  · VRAM ${(root.control.gpuMemUsed / 1024).toFixed(1)} / ${(root.control.gpuMemTotal / 1024).toFixed(0)}` : "")
            }
            Level {
                value: root.control.memTotal > 0 ? root.control.memUsed / root.control.memTotal : 0
            }
            Fact {
                label: "board"
                value: root.control.board
            }
            Fact {
                label: "kernel"
                value: root.control.kernel

                trailing: C.Tag {
                    text: "reboot pending"
                    visible: root.control.rebootPending
                }
            }

            // ── Updates ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 4

                C.SectionTitle {
                    text: "Updates"
                    code: root.control.updatesChecking ? "" : root.control.updateCount > 0 ? String(root.control.updateCount).padStart(2, "0") : "--"
                }
                C.IconButton {
                    size: 24
                    icon: "\u{F0450}"
                    enabled: !root.control.updatesChecking
                    iconColor: root.control.updatesChecking ? Theme.palette.accent : Theme.palette.fg
                    onClicked: root.control.checkUpdates()

                    NumberAnimation on iconRotation {
                        running: root.control.updatesChecking
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

                readonly property var repos: Object.keys(root.control.updateCounts)

                Layout.fillWidth: true
                implicitHeight: 44
                visible: !root.control.updatesFailed

                Repeater {
                    model: repoReadouts.repos

                    Column {
                        required property string modelData
                        required property int index
                        readonly property int n: root.control.updateCounts[modelData]

                        x: index * repoReadouts.width / repoReadouts.repos.length
                        width: repoReadouts.width / repoReadouts.repos.length
                        spacing: 0

                        C.StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: parent.modelData
                            caps: true
                            color: Theme.palette.muted
                            font.pixelSize: Theme.font.size - 3
                            font.bold: true
                            tracking: 1.5
                        }
                        C.StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: root.control.updatesChecking ? "··" : String(parent.n).padStart(2, "0")
                            color: parent.n > 0 && !root.control.updatesChecking ? Theme.palette.accent : Theme.palette.surface
                            glow: parent.n > 0 && !root.control.updatesChecking
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

                C.StyledText {
                    Layout.fillWidth: true
                    text: root.control.updatesChecking ? "checking…"
                        : root.control.updatesFailed ? "-- check failed (offline?) --"
                        : root.control.updateCount === 0 ? "-- up to date --"
                        : `last upgrade ${root.control.ago(root.control.lastUpgrade)}`
                    color: Theme.palette.muted
                    font.pixelSize: Theme.font.size - 2
                }
                C.TextButton {
                    text: `\u{F06B0}  update${root.control.aurHelper ? " (" + root.control.aurHelper + ")" : ""}`
                    visible: root.control.updateCount > 0 && !root.control.updatesChecking
                    onClicked: {
                        root.control.upgrade();
                    }
                }
            }

            // ── Storage ──────────────────────────────────────────────────────
            C.SectionTitle {
                Layout.topMargin: 6
                text: "Storage"
                code: String(root.control.mounted.length + root.control.shares.length).padStart(2, "0")
            }
            C.StyledText {
                Layout.leftMargin: 8
                text: Theme.caps("err") + " " + root.control.storageError
                color: Theme.palette.error
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                visible: root.control.storageError !== ""
            }
            Repeater {
                model: root.control.mounted

                ColumnLayout {
                    id: disk

                    required property var modelData
                    readonly property real usage: modelData.size > 0 ? modelData.used / modelData.size : 0

                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        C.StyledText {
                            Layout.preferredWidth: 52
                            text: disk.modelData.removable ? "\u{F129E}" : "\u{F02CA}"
                            color: disk.usage >= 0.85 ? Theme.palette.warn : Theme.palette.dim
                        }
                        C.StyledText {
                            text: disk.modelData.mount
                            font.bold: true
                        }
                        C.StyledText {
                            Layout.fillWidth: true
                            text: `${disk.modelData.name} · ${disk.modelData.fstype}`
                            color: Theme.palette.muted
                            font.pixelSize: Theme.font.size - 2
                            elide: Text.ElideRight
                        }
                        C.StyledText {
                            text: `${root.control.sizeText(disk.modelData.avail)} free`
                            color: disk.usage >= 0.85 ? Theme.palette.warn : Theme.palette.dim
                            font.pixelSize: Theme.font.size - 2
                            font.bold: true
                        }
                        C.IconButton {
                            size: 22
                            icon: "\u{F07AF}"
                            iconColor: Theme.palette.dim
                            onClicked: root.control.inspect(disk.modelData.mount)
                        }
                        C.IconButton {
                            size: 22
                            icon: "\u{F01EA}"
                            iconColor: Theme.palette.dim
                            visible: disk.modelData.removable
                            onClicked: root.control.eject(disk.modelData.device)
                        }
                    }
                    Level {
                        value: disk.usage
                        extra: root.control.sizeText(disk.modelData.size)
                    }
                }
            }
            Repeater {
                model: root.control.mountable

                RowLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 10

                    C.StyledText {
                        Layout.preferredWidth: 52
                        text: "\u{F129E}"
                        color: Theme.palette.muted
                    }
                    C.StyledText {
                        Layout.fillWidth: true
                        text: `${modelData.name} · ${modelData.fstype} · ${root.control.sizeText(modelData.size)}`
                        color: Theme.palette.dim
                        elide: Text.ElideRight
                    }
                    C.TextButton {
                        text: "mount"
                        onClicked: root.control.mount(modelData.device)
                    }
                }
            }

            // Network shares (systemd mount/automount units)
            Repeater {
                model: root.control.shares

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

                        C.StyledText {
                            Layout.preferredWidth: 52
                            text: "\u{F08F3}"
                            color: share.modelData.state === "failed" ? Theme.palette.warn
                                : share.mounted ? Theme.palette.dim : Theme.palette.muted
                        }
                        C.StyledText {
                            text: share.modelData.mount
                            font.bold: true
                            color: share.mounted ? Theme.palette.fg : Theme.palette.dim
                        }
                        C.StyledText {
                            Layout.fillWidth: true
                            text: `${share.modelData.source} · ${share.modelData.fstype}`
                            color: Theme.palette.muted
                            font.pixelSize: Theme.font.size - 2
                            elide: Text.ElideRight
                        }
                        C.StyledText {
                            text: `${root.control.sizeText(share.modelData.avail)} free`
                            color: share.usage >= 0.85 ? Theme.palette.warn : Theme.palette.dim
                            font.pixelSize: Theme.font.size - 2
                            font.bold: true
                            visible: share.mounted && share.modelData.size > 0
                        }
                        C.Tag {
                            text: share.modelData.state === "failed" ? "failed" : share.modelData.state === "idle" ? "idle" : "off"
                            fill: share.modelData.state === "failed" ? Theme.palette.warn : Theme.palette.surface
                            textColor: share.modelData.state === "failed" ? Theme.palette.shadow : Theme.palette.dim
                            visible: !share.mounted
                        }
                        C.TextButton {
                            text: "connect"
                            visible: share.modelData.state === "idle" || share.modelData.state === "failed"
                            onClicked: root.control.connect(share.modelData.mount)
                        }
                        C.IconButton {
                            size: 22
                            icon: "\u{F07AF}"
                            iconColor: Theme.palette.dim
                            visible: share.mounted
                            onClicked: root.control.inspect(share.modelData.mount)
                        }
                    }
                    Level {
                        value: share.usage
                        extra: root.control.sizeText(share.modelData.size)
                        visible: share.mounted && share.modelData.size > 0
                    }
                    C.StyledText {
                        Layout.leftMargin: 62
                        text: `systemd: ${share.modelData.reason}`
                        color: Theme.palette.warn
                        font.pixelSize: Theme.font.size - 3
                        visible: share.modelData.state === "failed"
                    }
                }
            }

            // ── USB ──────────────────────────────────────────────────────────
            C.SectionTitle {
                Layout.topMargin: 6
                text: "USB"
                code: String(root.control.usb.length).padStart(2, "0")
            }
            C.Placeholder {
                text: "-- nothing connected --"
                visible: root.control.usb.length === 0
            }
            Repeater {
                model: root.control.usb

                RowLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 10

                    C.StyledText {
                        Layout.preferredWidth: 52
                        text: "\u{F0553}"
                        color: Theme.palette.dim
                    }
                    C.StyledText {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: Theme.palette.dim
                        elide: Text.ElideRight
                    }
                    C.StyledText {
                        text: modelData.id
                        color: Theme.palette.muted
                        font.pixelSize: Theme.font.size - 3
                    }
                }
            }

            // ── Tools ────────────────────────────────────────────────────────
            C.SectionTitle {
                Layout.topMargin: 6
                text: "Tools"
            }
            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.control.tools

                    C.TextButton {
                        required property var modelData

                        text: `\u{F018D}  ${modelData.label}`
                        onClicked: root.control.run(modelData.command)
                    }
                }
            }
        }
    }

    // Scroll position lamp, when scrolling is possible.
    C.ScrollLamp {
        view: flick
    }
}
