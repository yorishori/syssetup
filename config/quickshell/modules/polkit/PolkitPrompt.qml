import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.core
import qs.services

// Admin password prompt for polkit (the agent lives in services/Polkit): a
// console in the middle of a darkened screen, with the request, who you
// authenticate as, and the password line (focus always returns to it). Enter
// authorizes, Escape cancels; a wrong password shakes and asks again.
PanelWindow {
    id: win

    readonly property var flow: Polkit.flow
    readonly property var identities: flow?.identities ?? []
    property bool checking: false

    function refocus(): void {
        if (visible)
            field.focusInput();
    }

    function submit(): void {
        if (!flow?.isResponseRequired || checking)
            return;
        checking = true;
        Polkit.submit(field.text);
        field.text = "";
    }

    screen: Display.primary
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: Polkit.active
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-polkit"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: {
        checking = false;
        field.text = "";
        Qt.callLater(refocus);
    }

    Connections {
        target: win.flow
        ignoreUnknownSignals: true

        function onAuthenticationFailed(): void {
            win.checking = false;
            shakeAnim.restart();
            win.refocus();
        }
        function onIsResponseRequiredChanged(): void {
            if (win.flow.isResponseRequired)
                win.checking = false;
            win.refocus();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Config.colors.bg, Math.max(Config.effects.backdrop, 0.6))

        // Clicking anywhere puts the focus back in the input.
        MouseArea {
            anchors.fill: parent
            onClicked: win.refocus()
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
            NumberAnimation { target: shake; property: "x"; to: 0; duration: 80; easing.type: Easing.OutBack }
        }

        Card {
            anchors.fill: parent
            stroke: Config.colors.warn
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

            SectionTitle {
                text: "AUTHORIZE"
                code: "POLKIT"
            }

            // The request
            RowLayout {
                spacing: 12

                Image {
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    sourceSize: Qt.size(32, 32)
                    source: Icons.url(win.flow?.iconName ?? "")
                    visible: status === Image.Ready
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        Layout.fillWidth: true
                        text: win.flow?.message ?? ""
                        font.bold: true
                        wrapMode: Text.Wrap
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: win.flow?.actionId ?? ""
                        color: Config.colors.muted
                        font.pixelSize: Config.font.size - 3
                        elide: Text.ElideRight
                    }
                }
            }

            // Who you authenticate as (a key each when there's a choice)
            RowLayout {
                spacing: 10

                Lamp {
                    on: true
                    litColor: win.flow?.failed ? Config.colors.warn : Config.colors.accent
                }
                StyledText {
                    text: {
                        const id = win.flow?.selectedIdentity;
                        return id ? (id.displayName || id.name) : "";
                    }
                    font.bold: true
                    visible: win.identities.length <= 1
                }
                Repeater {
                    model: win.identities.length > 1 ? win.identities : []

                    TextButton {
                        required property var modelData

                        text: modelData.displayName || modelData.name
                        lit: win.flow?.selectedIdentity === modelData
                        onClicked: {
                            win.flow.selectedIdentity = modelData;
                            win.refocus();
                        }
                    }
                }
            }

            TextField {
                id: field

                Layout.fillWidth: true
                prompt: "pass>"
                placeholder: (win.flow?.inputPrompt ?? "").replace(/:\s*$/, "").toLowerCase() || "password"
                echoMode: win.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                onAccepted: win.submit()
                // Never let the focus wander off.
                onInputFocusedChanged: {
                    if (!inputFocused)
                        Qt.callLater(win.refocus);
                }
                Keys.onEscapePressed: Polkit.cancel()
            }

            StyledText {
                Layout.fillWidth: true
                readonly property string extra: win.flow?.supplementaryMessage ?? ""

                text: win.checking ? "AUTHENTICATING…"
                    : extra ? extra
                    : win.flow?.failed ? "ACCESS DENIED · TRY AGAIN"
                    : "ENTER TO AUTHORIZE · ESC TO CANCEL"
                color: win.flow?.failed || win.flow?.supplementaryIsError ? Config.colors.warn : Config.colors.muted
                font.pixelSize: Config.font.size - 2
                font.bold: true
                font.letterSpacing: 1.5
                wrapMode: Text.Wrap
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: 1
                color: Config.colors.border
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextButton {
                    text: "\u{F0156}  cancel"
                    onClicked: Polkit.cancel()
                }
                Item {
                    Layout.fillWidth: true
                }
                TextButton {
                    text: "\u{F0341}  authorize"
                    lit: true
                    onClicked: win.submit()
                }
            }
        }
    }
}
