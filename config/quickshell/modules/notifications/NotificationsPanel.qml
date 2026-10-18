import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.components
import qs.core
import qs.services

// Notification center: do-not-disturb (on, or for an hour), per-app muting,
// and the history. Click a notification to run its action, × dismisses it.
ColumnLayout {
    id: root

    width: 380
    spacing: 10

    readonly property var history: Notifs.list.slice().reverse()  // newest first

    function ago(n: var): string {
        const t = Notifs.received[n?.id];
        if (!t)
            return "";
        const m = Math.floor((Time.now - t) / 60000);
        return m < 1 ? "now" : m < 60 ? `${m}m` : m < 1440 ? `${Math.floor(m / 60)}h` : `${Math.floor(m / 1440)}d`;
    }

    // ── Do not disturb ───────────────────────────────────────────────────────
    SectionTitle {
        text: "Do not disturb"
        code: !Notifs.dnd ? "off"
            : Notifs.dndUntil > 0 ? `${Math.max(1, Math.ceil((Notifs.dndUntil - Time.now) / 60000))} min left`
            : "on"
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        TextButton {
            text: Notifs.dnd && Notifs.dndUntil === 0 ? "\u{F009B}  on" : "\u{F009A}  off"
            lit: Notifs.dnd && Notifs.dndUntil === 0
            onClicked: Notifs.setDnd(!(Notifs.dnd && Notifs.dndUntil === 0), 0)
        }
        TextButton {
            text: "\u{F051F}  1 h"
            lit: Notifs.dnd && Notifs.dndUntil > 0
            onClicked: Notifs.setDnd(!(Notifs.dnd && Notifs.dndUntil > 0), 60)
        }
        Item {
            Layout.fillWidth: true
        }
        StyledText {
            text: "critical ones still show"
            color: Theme.palette.muted
            font.pixelSize: Theme.font.size - 3
            visible: Notifs.dnd
        }
    }

    // ── Sources: mute per app ────────────────────────────────────────────────
    SectionTitle {
        Layout.topMargin: 4
        text: "Sources"
        code: Notifs.mutedApps.length > 0 ? `${String(Notifs.mutedApps.length).padStart(2, "0")} muted` : ""
        visible: Notifs.apps.length > 0
    }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        visible: Notifs.apps.length > 0

        Repeater {
            model: Notifs.apps

            Chip {
                required property string modelData

                text: modelData
                on: !Notifs.isMuted(modelData)
                onClicked: Notifs.toggleApp(modelData)
            }
        }
    }

    // ── History ──────────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 6

        SectionTitle {
            text: "History"
            code: String(root.history.length).padStart(2, "0")
        }
        TextButton {
            text: "\u{F0A7A}  clear"
            visible: root.history.length > 0
            onClicked: Notifs.clear()
        }
    }
    StyledText {
        Layout.leftMargin: 8
        text: "-- nothing here --"
        color: Theme.palette.muted
        visible: root.history.length === 0
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: list.height
        visible: root.history.length > 0

        ListView {
            id: list

            width: parent.width
            height: Math.min(contentHeight, 440)
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            model: root.history

            delegate: Entry {
                id: entry

                required property var modelData
                readonly property bool critical: modelData?.urgency === NotificationUrgency.Critical

                width: ListView.view.width
                implicitHeight: body.implicitHeight + 16
                tone: critical ? Theme.palette.error : "transparent"
                onClicked: entry.modelData?.actions.find(a => a.identifier === "default")?.invoke()

                ColumnLayout {
                    id: body

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 8
                        leftMargin: 10
                    }
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            text: (entry.modelData?.appName ?? "")
                            caps: true
                            color: entry.critical ? Theme.palette.error : Theme.palette.muted
                            font.pixelSize: Theme.font.size - 3
                            font.bold: true
                            tracking: 1.5
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: root.ago(entry.modelData)
                            caps: true
                            color: Theme.palette.muted
                            font.pixelSize: Theme.font.size - 3
                            font.bold: true
                        }
                        IconButton {
                            size: 20
                            icon: "\u{F0156}"
                            iconColor: Theme.palette.muted
                            onClicked: Notifs.dismiss(entry.modelData)
                        }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: entry.modelData?.summary ?? ""
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: (entry.modelData?.body ?? "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ")
                        color: Theme.palette.dim
                        font.pixelSize: Theme.font.size - 1
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }
            }
        }
        ScrollLamp {
            view: list
        }
    }
}
