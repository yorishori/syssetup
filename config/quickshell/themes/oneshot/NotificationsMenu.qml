import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core
import qs.modules.notifications as M

// Under the title the frame draws: do not disturb (on, or for an
// hour), the sources to mute, then the history: click a notification to
// run its action, × dismisses it.
Item {
    id: root

    required property M.NotificationsPanel control

    implicitWidth: 400
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 10


        // ── Do not disturb ───────────────────────────────────────────────────
        C.SectionTitle {
            text: "Do not disturb"
            code: !root.control.dnd ? "off"
                : root.control.dndUntil > 0 ? `${root.control.dndMinutesLeft} min left`
                : "on"
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            C.TextButton {
                text: root.control.dnd && root.control.dndUntil === 0 ? "\u{F009B}  on" : "\u{F009A}  off"
                lit: root.control.dnd && root.control.dndUntil === 0
                onClicked: root.control.setDnd(!(root.control.dnd && root.control.dndUntil === 0), 0)
            }
            C.TextButton {
                text: "\u{F051F}  1 h"
                lit: root.control.dnd && root.control.dndUntil > 0
                onClicked: root.control.setDnd(!(root.control.dnd && root.control.dndUntil > 0), 60)
            }
            Item {
                Layout.fillWidth: true
            }
            C.StyledText {
                text: "critical ones still show"
                color: Theme.palette.muted
                font.pixelSize: Theme.font.size - 3
                visible: root.control.dnd
            }
        }

        // ── Sources: mute per app ────────────────────────────────────────────
        C.SectionTitle {
            Layout.topMargin: 4
            text: "Sources"
            code: root.control.mutedApps.length > 0 ? `${String(root.control.mutedApps.length).padStart(2, "0")} muted` : ""
            visible: root.control.apps.length > 0
        }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            visible: root.control.apps.length > 0

            Repeater {
                model: root.control.apps

                C.Chip {
                    required property string modelData

                    text: modelData
                    on: !root.control.isMuted(modelData)
                    onClicked: root.control.toggleApp(modelData)
                }
            }
        }

        // ── History ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 6

            C.SectionTitle {
                text: "History"
                code: String(root.control.history.length).padStart(2, "0")
            }
            C.TextButton {
                text: "\u{F0A7A}  clear"
                visible: root.control.history.length > 0
                onClicked: root.control.clear()
            }
        }
        C.StyledText {
            Layout.leftMargin: 8
            text: "-- nothing here --"
            color: Theme.palette.muted
            visible: root.control.history.length === 0
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: list.height
            visible: root.control.history.length > 0

            ListView {
                id: list

                width: parent.width
                height: Math.min(contentHeight, 460)
                clip: true
                spacing: 8
                boundsBehavior: Flickable.StopAtBounds
                model: root.control.history

                delegate: Letter {
                    required property var modelData

                    width: ListView.view.width
                    app: modelData?.appName ?? ""
                    summary: modelData?.summary ?? ""
                    body: root.control.plain(modelData)
                    when: root.control.ago(modelData)
                    critical: root.control.critical(modelData)
                    maxLines: 1
                    onOpened: root.control.invoke(modelData)
                    onDismissed: root.control.dismiss(modelData)
                }
            }
            C.ScrollLamp {
                view: list
            }
        }
    }
}
