import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core

// A notification as a letter: an RPG window with a wax seal in the app's
// own colour (its initial pressed in it), a postmark with when it came, the
// sender, the summary and what it says. Amber-framed on hover; a critical
// one is sealed and framed in red. Left click opens it (its default
// action), right click or × dismisses it.
Item {
    id: root

    property string app: ""
    property string summary: ""
    property string body: ""
    property string when: ""
    property bool critical: false
    property bool closable: true
    property int maxLines: 3
    // The notification's own buttons ([{ text, invoke() }]).
    property var actions: []
    readonly property bool hovered: hover.hovered

    signal opened
    signal dismissed

    readonly property int px: Theme.get("pixel.scale") ?? 3
    readonly property var seals: ["#e8a0b4", "#8fd6b4", "#b5a8e0", "#f2c46d", "#7ab8d6", "#ff9a2e"]
    readonly property color seal: critical ? Theme.palette.error : seals[[...app].reduce((h, ch) => (h * 31 + ch.charCodeAt(0)) % 997, 7) % seals.length]

    implicitWidth: 360
    implicitHeight: Math.max(content.implicitHeight + 28, 70)

    HoverHandler {
        id: hover
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.LeftButton ? root.opened() : root.dismissed()
    }

    Frame {
        anchors.fill: parent
        frame: root.critical ? Theme.palette.error : root.hovered ? Theme.palette.accent : Theme.palette.border
    }

    // The seal: a lumpy pixel disc, a lighter lip, the app's initial.
    Item {
        id: sealItem

        x: 14
        y: 14
        width: 11 * 3
        height: 11 * 3

        PixelArt {
            px: 3
            colors: ({ "s": root.seal.toString(), "d": Qt.darker(root.seal, 1.35).toString(), "l": Qt.lighter(root.seal, 1.2).toString() })
            rows: [
                "...ssss....",
                ".sssssssd..",
                ".slssssssd.",
                "sslsssssssd",
                "ssssssssssd",
                "sssssssssdd",
                "ssssssssssd",
                ".sssssssdd.",
                ".ssssssdd..",
                "..dsssdd...",
                "....dd....."
            ]
        }
        C.StyledText {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -2
            text: root.app.slice(0, 1).toUpperCase()
            color: Qt.darker(root.seal, 2.2)
            font.family: Theme.get("font.labels") ?? Theme.font.family
            font.pixelSize: Theme.font.size + 2
        }
    }

    ColumnLayout {
        id: content

        anchors {
            left: sealItem.right
            right: parent.right
            top: parent.top
            leftMargin: 12
            rightMargin: 12
            topMargin: 12
        }
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            C.StyledText {
                Layout.fillWidth: true
                text: root.app
                caps: true
                color: root.critical ? Theme.palette.error : Theme.palette.dim
                font.family: Theme.get("font.labels") ?? Theme.font.family
                font.pixelSize: Theme.font.size - 4
                elide: Text.ElideRight
            }
            // The postmark: when it came, in a dashed box.
            Item {
                implicitWidth: stamp.implicitWidth + 10
                implicitHeight: stamp.implicitHeight + 4
                visible: root.when !== ""

                Repeater {
                    model: Math.ceil(parent.width / 6)

                    Item {
                        required property int index

                        Rectangle { x: index * 6; width: 3; height: 2; color: Theme.palette.muted }
                        Rectangle { x: index * 6; y: parent.parent.height - 2; width: 3; height: 2; color: Theme.palette.muted }
                    }
                }
                C.StyledText {
                    id: stamp

                    anchors.centerIn: parent
                    text: root.when
                    caps: true
                    color: Theme.palette.muted
                    font.family: Theme.get("font.labels") ?? Theme.font.family
                    font.pixelSize: Theme.font.size - 5
                }
            }
            C.IconButton {
                size: 20
                icon: "\u{F0156}"
                iconColor: Theme.palette.muted
                visible: root.closable
                onClicked: root.dismissed()
            }
        }
        C.StyledText {
            Layout.fillWidth: true
            text: root.summary
            color: Theme.palette.fg
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        C.StyledText {
            Layout.fillWidth: true
            text: root.body
            color: Theme.palette.dim
            wrapMode: Text.Wrap
            maximumLineCount: root.maxLines
            elide: Text.ElideRight
            visible: text !== ""
        }
        Flow {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 6
            visible: root.actions.length > 0

            Repeater {
                model: root.actions

                C.TextButton {
                    required property var modelData

                    text: modelData.text
                    onClicked: modelData.invoke()
                }
            }
        }
    }
}
