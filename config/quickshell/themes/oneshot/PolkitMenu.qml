import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.modules.polkit as M

// A window in the middle of the screen, titled in amber like the panels,
// with the request, who you authenticate as, and the password line. A
// wrong password shakes it.
Item {
    id: root

    required property M.PolkitAsk control

    function refocus(): void {
        if (root.control.active)
            field.focusInput();
    }
    function submit(): void {
        if (root.control.submit(field.text))
            field.text = "";
    }

    Connections {
        target: root.control

        function onActiveChanged(): void {
            field.text = "";
        }
        function onDenied(): void {
            shakeAnim.restart();
        }
        function onRefocusRequested(): void {
            root.refocus();
        }
    }

    Item {
        id: console_

        anchors.centerIn: parent
        implicitWidth: 460
        implicitHeight: box.implicitHeight + 36
        width: implicitWidth
        height: implicitHeight

        transform: Translate {
            id: shake
        }
        SequentialAnimation {
            id: shakeAnim

            NumberAnimation { target: shake; property: "x"; to: -10; duration: 50 }
            NumberAnimation { target: shake; property: "x"; to: 10; duration: 70 }
            NumberAnimation { target: shake; property: "x"; to: -6; duration: 60 }
            NumberAnimation { target: shake; property: "x"; to: 0; duration: 80; easing.type: Theme.motion.spring; easing.overshoot: Theme.motion.bounce }
        }

        Card {
            anchors.fill: parent
            tone: Theme.palette.warn
        }

        ColumnLayout {
            id: box

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 18
            }
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                StyledText {
                    text: "Authorize"
                    color: Theme.palette.accent
                    font.pixelSize: Theme.font.size + 6
                    font.weight: Font.DemiBold
                }
                Item {
                    Layout.fillWidth: true
                }
                StyledText {
                    text: "polkit"
                    caps: true
                    color: Theme.palette.muted
                    font.family: Theme.get("font.labels") ?? Theme.font.family
                    font.pixelSize: Theme.font.size - 3
                }
            }

            // The request
            RowLayout {
                spacing: 12

                Image {
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    sourceSize: Qt.size(32, 32)
                    source: Icons.url(root.control.flow?.iconName ?? "")
                    visible: status === Image.Ready
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        Layout.fillWidth: true
                        text: root.control.flow?.message ?? ""
                        font.bold: true
                        wrapMode: Text.Wrap
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: root.control.flow?.actionId ?? ""
                        color: Theme.palette.muted
                        font.pixelSize: Theme.font.size - 3
                        elide: Text.ElideRight
                    }
                }
            }

            // Who you authenticate as (a key each when there's a choice)
            RowLayout {
                spacing: 10

                Lamp {
                    on: true
                    litColor: root.control.flow?.failed ? Theme.palette.warn : Theme.palette.accent
                }
                StyledText {
                    text: root.control.nameOf(root.control.identity)
                    font.bold: true
                    visible: root.control.identities.length <= 1
                }
                Repeater {
                    model: root.control.identities.length > 1 ? root.control.identities : []

                    TextButton {
                        required property var modelData

                        text: modelData.displayName || modelData.name
                        lit: root.control.flow?.selectedIdentity === modelData
                        onClicked: root.control.choose(modelData)
                    }
                }
            }

            TextField {
                id: field

                Layout.fillWidth: true
                prompt: "pass>"
                placeholder: (root.control.flow?.inputPrompt ?? "").replace(/:\s*$/, "").toLowerCase() || "password"
                echoMode: root.control.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                onAccepted: root.submit()
                // Never let the focus wander off.
                onInputFocusedChanged: {
                    if (!inputFocused)
                        Qt.callLater(root.refocus);
                }
            }

            StyledText {
                Layout.fillWidth: true
                readonly property string extra: root.control.flow?.supplementaryMessage ?? ""

                text: root.control.checking ? "authenticating…"
                    : extra ? extra
                    : root.control.flow?.failed ? "access denied · try again"
                    : "enter to authorize · esc to cancel"
                caps: extra === ""  // the agent's own message as it comes
                color: root.control.flow?.failed || root.control.flow?.supplementaryIsError ? Theme.palette.warn : Theme.palette.muted
                font.pixelSize: Theme.font.size - 2
                font.bold: true
                tracking: 1.5
                wrapMode: Text.Wrap
            }

            Divider {
                Layout.fillWidth: true
                Layout.topMargin: 4
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextButton {
                    text: "\u{F0156}  cancel"
                    onClicked: root.control.cancel()
                }
                Item {
                    Layout.fillWidth: true
                }
                TextButton {
                    text: "\u{F0341}  authorize"
                    lit: true
                    onClicked: root.submit()
                }
            }
        }
    }
}
