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
    stroke: critical ? Config.colors.error : hovered ? Config.colors.accent : Config.colors.border

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

            // App name on a label tag, like a sticker on hardware.
            Item {
                implicitWidth: tagText.implicitWidth + 14
                implicitHeight: tagText.implicitHeight + 4
                visible: tagText.text !== ""

                Chamfer {
                    anchors.fill: parent
                    cut: 4
                    fill: root.critical ? Config.colors.error : Config.colors.surface
                }
                StyledText {
                    id: tagText

                    anchors.centerIn: parent
                    text: (root.notif?.appName ?? "").toUpperCase()
                    color: root.critical ? Config.colors.shadow : Config.colors.dim
                    font.pixelSize: Config.font.size - 3
                    font.bold: true
                    font.letterSpacing: 1.5
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.notif?.summary ?? ""
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.notif?.body ?? ""
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
