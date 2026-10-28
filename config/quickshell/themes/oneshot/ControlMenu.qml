import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core
import qs.modules.control as M

// A character status screen (the frame draws its title): the cat's
// portrait beside the machine's name, how long it's been up and its kernel
// (the cat itself comes and sits on the window, see BarCat); then the
// system (CPU, GPU, RAM as block meters; board, kernel), updates per
// repository, storage, USB devices and your tools, in one scrolling column.
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
            color: Theme.palette.dim
            font.family: Theme.get("font.labels") ?? Theme.font.family
            font.pixelSize: Theme.font.size - 4
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

            // ── The character: the cat's portrait, the machine's name ───────
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                spacing: 14

                Item {
                    implicitWidth: 72
                    implicitHeight: 66

                    Frame {
                        anchors.fill: parent
                        face: Theme.palette.bgAlt
                    }
                    Item {
                        x: 6
                        y: 6
                        width: 60
                        height: 54
                        clip: true

                        Cat {
                            x: (parent.width - width) / 2 + 2
                            y: 4
                            px: 4
                            pose: "sit"
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    C.StyledText {
                        Layout.fillWidth: true
                        text: root.control.session.hostname
                        color: Theme.palette.accent
                        font.pixelSize: Theme.font.size + 6
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    C.StyledText {
                        text: `up ${root.control.session.uptimeText}`
                        caps: true
                        color: Theme.palette.dim
                        font.family: Theme.get("font.labels") ?? Theme.font.family
                        font.pixelSize: Theme.font.size - 3
                    }
                    C.StyledText {
                        Layout.fillWidth: true
                        text: root.control.system.kernel
                        color: Theme.palette.muted
                        font.pixelSize: Theme.font.size - 2
                        elide: Text.ElideRight
                    }
                }
            }

            // ── System ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                C.SectionTitle {
                    text: "System"
                }
                C.IconButton {
                    size: 24
                    icon: "\u{F0493}"
                    onClicked: root.control.openSettings()
                }
            }
            Fact {
                label: "CPU"
                value: root.control.system.cpu
            }
            Level {
                value: root.control.system.cpuUsage
                extra: root.control.system.cpuTemp >= 0 ? `${root.control.system.cpuTemp}°` : ""
            }
            Fact {
                label: "GPU"
                value: root.control.system.gpu.replace(/^NVIDIA /, "")
            }
            Level {
                value: root.control.system.gpuUsage
                extra: root.control.system.gpuTemp >= 0 ? `${root.control.system.gpuTemp}°` : ""
            }
            Fact {
                label: "RAM"
                value: `${root.control.system.gib(root.control.system.memUsed)} / ${root.control.system.gib(root.control.system.memTotal)} GiB`
                    + (root.control.system.gpuMemTotal > 0 ? `  · VRAM ${(root.control.system.gpuMemUsed / 1024).toFixed(1)} / ${(root.control.system.gpuMemTotal / 1024).toFixed(0)}` : "")
            }
            Level {
                value: root.control.system.memTotal > 0 ? root.control.system.memUsed / root.control.system.memTotal : 0
            }
            Fact {
                label: "board"
                value: root.control.system.board
            }
            Fact {
                label: "kernel"
                value: root.control.system.kernel

                trailing: C.Tag {
                    text: "reboot pending"
                    visible: root.control.system.rebootPending
                }
            }

            // ── Updates ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 4

                C.SectionTitle {
                    text: "Updates"
                    code: root.control.updates.checking ? "" : root.control.updates.count > 0 ? String(root.control.updates.count).padStart(2, "0") : "--"
                }
                C.IconButton {
                    size: 24
                    icon: "\u{F0450}"
                    enabled: !root.control.updates.checking
                    iconColor: root.control.updates.checking ? Theme.palette.accent : Theme.palette.fg
                    onClicked: root.control.checkUpdates()

                    NumberAnimation on iconRotation {
                        running: root.control.updates.checking
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

                readonly property var repos: Object.keys(root.control.updates.counts)

                Layout.fillWidth: true
                implicitHeight: 44
                visible: !root.control.updates.failed

                Repeater {
                    model: repoReadouts.repos

                    Column {
                        required property string modelData
                        required property int index
                        readonly property int n: root.control.updates.counts[modelData]

                        x: index * repoReadouts.width / repoReadouts.repos.length
                        width: repoReadouts.width / repoReadouts.repos.length
                        spacing: 0

                        C.StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: parent.modelData
                            caps: true
                            color: Theme.palette.dim
                            font.family: Theme.get("font.labels") ?? Theme.font.family
                            font.pixelSize: Theme.font.size - 4
                        }
                        C.StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: root.control.updates.checking ? "··" : String(parent.n).padStart(2, "0")
                            color: parent.n > 0 && !root.control.updates.checking ? Theme.palette.accent : Theme.palette.surface
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
                    text: root.control.updates.checking ? "checking…"
                        : root.control.updates.failed ? "-- check failed (offline?) --"
                        : root.control.updates.count === 0 ? "-- up to date --"
                        : `last upgrade ${root.control.ago(root.control.updates.lastUpgrade)}`
                    color: Theme.palette.muted
                    font.pixelSize: Theme.font.size - 2
                }
                C.TextButton {
                    text: `\u{F06B0}  update${root.control.updates.aurHelper ? " (" + root.control.updates.aurHelper + ")" : ""}`
                    visible: root.control.updates.count > 0 && !root.control.updates.checking
                    onClicked: {
                        root.control.upgrade();
                    }
                }
            }

            // ── Storage ──────────────────────────────────────────────────────
            C.SectionTitle {
                Layout.topMargin: 6
                text: "Storage"
                code: String(root.control.storage.mounted.length + root.control.storage.network.length).padStart(2, "0")
            }
            C.StyledText {
                Layout.leftMargin: 8
                text: Theme.caps("err") + " " + root.control.storage.error
                color: Theme.palette.error
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                visible: root.control.storage.error !== ""
            }
            Repeater {
                model: root.control.storage.mounted

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
                            text: `${root.control.storage.human(disk.modelData.avail)} free`
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
                        extra: root.control.storage.human(disk.modelData.size)
                    }
                }
            }
            Repeater {
                model: root.control.storage.mountable

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
                        text: `${modelData.name} · ${modelData.fstype} · ${root.control.storage.human(modelData.size)}`
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
                model: root.control.storage.network

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
                            text: `${root.control.storage.human(share.modelData.avail)} free`
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
                        extra: root.control.storage.human(share.modelData.size)
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
                code: String(root.control.storage.usb.length).padStart(2, "0")
            }
            C.Placeholder {
                text: "-- nothing connected --"
                visible: root.control.storage.usb.length === 0
            }
            Repeater {
                model: root.control.storage.usb

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
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Flow {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignBottom
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
    }

    // Scroll position lamp, when scrolling is possible.
    C.ScrollLamp {
        view: flick
    }
}
