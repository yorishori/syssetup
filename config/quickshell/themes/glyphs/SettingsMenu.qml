import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.modules.settings as M

// One page: each setting's name and hint on the left, its control on the
// right (↺ when it's not the default), and a key to edit the setup.
Item {
    id: root

    required property M.SettingsPanel control

    implicitWidth: 560
    implicitHeight: Math.min(body.implicitHeight, control.maxHeight)

    Flickable {
        id: flick

        anchors.fill: parent
        contentHeight: body.implicitHeight
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: body

            width: flick.width - 8
            spacing: 14

            SectionTitle {
                text: "Settings"
                code: "settings.json"
            }

            Repeater {
                model: root.control.items

                RowLayout {
                    id: setting

                    required property var modelData
                    readonly property var value: modelData.path ? root.control.value(modelData.path) : undefined
                    readonly property bool changed: !!modelData.path && root.control.changed(modelData.path)

                    function save(v: var): void {
                        root.control.set(modelData.path, v);
                    }

                    Layout.fillWidth: true
                    visible: modelData.when?.() ?? true
                    spacing: 12

                    ColumnLayout {
                        Layout.preferredWidth: 160
                        Layout.minimumWidth: 160
                        Layout.maximumWidth: 160
                        Layout.alignment: Qt.AlignTop
                        spacing: 0

                        RowLayout {
                            spacing: 4

                            StyledText {
                                text: setting.modelData.label
                                font.bold: true
                            }
                            IconButton {
                                size: 18
                                icon: "\u{F0450}"
                                iconColor: Theme.palette.muted
                                visible: setting.changed
                                onClicked: root.control.reset(setting.modelData.path)
                            }
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: setting.modelData.hint ?? ""
                            color: Theme.palette.muted
                            font.pixelSize: Theme.font.size - 3
                            wrapMode: Text.Wrap
                            visible: text !== ""
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        sourceComponent: ({
                            int: intControl, color: colorControl, choice: choiceControl,
                            screen: screenControl, text: textControl, action: actionControl
                        })[setting.modelData.type] ?? null
                    }

                    Component {
                        id: intControl

                        RowLayout {
                            Stepper {
                                value: setting.value ?? 0
                                from: setting.modelData.min
                                to: setting.modelData.max
                                suffix: setting.modelData.suffix ?? ""
                                onMoved: v => setting.save(v)
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }
                    Component {
                        id: colorControl

                        Swatches {
                            palette: setting.modelData.palette === "dark" ? dark : accents
                            current: setting.value || (setting.modelData.palette === "dark" ? Theme.palette.bg : "")
                            onPicked: color => setting.save(color)
                        }
                    }
                    Component {
                        id: choiceControl

                        RowLayout {
                            Choice {
                                options: setting.modelData.options
                                current: setting.value
                                onPicked: v => setting.save(v)
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }
                    Component {
                        id: screenControl

                        RowLayout {
                            Choice {
                                options: [{ label: "auto", value: "" }, ...root.control.screens.map(s => ({ label: s, value: s }))]
                                current: setting.value
                                onPicked: v => setting.save(v)
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }
                    Component {
                        id: textControl

                        TextField {
                            prompt: ">"
                            submitOnEnter: true
                            text: setting.value ?? ""
                            onAccepted: flash()
                            onEditingFinished: {
                                const v = text.trim();
                                if (v !== setting.value) {
                                    setting.save(v);
                                    flash();
                                }
                            }
                        }
                    }
                    Component {
                        id: actionControl

                        RowLayout {
                            TextButton {
                                text: setting.modelData.button
                                onClicked: setting.modelData.run()
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            Divider {
                Layout.fillWidth: true
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                StyledText {
                    Layout.fillWidth: true
                    text: "Terminal, launcher entries, tools, calendar, theme tokens… are the setup, in the project."
                    color: Theme.palette.muted
                    font.pixelSize: Theme.font.size - 3
                    wrapMode: Text.Wrap
                }
                TextButton {
                    text: "\u{F03EB}  edit setup"
                    onClicked: root.control.editSetup()
                }
            }
        }
    }
    ScrollLamp {
        view: flick
    }
}
