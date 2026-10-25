import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.core

// One notification. Left click runs the default action, right click dismisses,
// action buttons run their action. `notif` can become null while the card
// animates out, hence the `?.` everywhere.
Card {
    id: root

    required property Notification notif
    readonly property bool hovered: hover.hovered

    signal dismissRequested

    readonly property string iconSource: {
        const n = notif;
        if (n?.image)
            return n.image;
        if (!n?.appIcon)
            return "";
        return Icons.url(n.appIcon);
    }

    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical

    implicitWidth: 360
    implicitHeight: content.implicitHeight + 24
    tone: critical ? Theme.palette.error : hovered ? Theme.palette.accent : "transparent"

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            const action = root.notif?.actions.find(a => a.identifier === "default");
            if (mouse.button === Qt.LeftButton && action)
                action.invoke();
            else
                root.dismissRequested();
        }
    }

    RowLayout {
        id: content

        anchors {
            fill: parent
            margins: 12
        }
        spacing: 12

        IconImage {
            Layout.alignment: Qt.AlignTop
            implicitSize: 36
            visible: root.iconSource !== ""
            source: root.iconSource
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 4

            // App name on a tag.
            Tag {
                text: root.notif?.appName ?? ""
                fill: root.critical ? Theme.palette.error : Theme.palette.surface
                textColor: root.critical ? Theme.palette.shadow : Theme.palette.dim
                visible: text !== ""
            }

            StyledText {
                Layout.fillWidth: true
                text: root.notif?.summary ?? ""
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                // Basic markup, but no images: they'd be fetched from wherever
                // the sender points.
                text: (root.notif?.body ?? "").replace(/<img\b[^>]*>/gi, "")
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                visible: text !== ""
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 6
                visible: actions.count > 0

                Repeater {
                    id: actions

                    model: root.notif?.actions.filter(a => a.identifier !== "default") ?? []

                    TextButton {
                        required property NotificationAction modelData

                        text: modelData.text
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
