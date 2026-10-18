import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.core
import qs.services

// Settings: edits config.json through Config.set (changes apply live, the file
// is written shortly after). The panel is built from `sections` below; adding
// a setting is one line there. ↺ resets a setting to its default.
//
// Types: int (stepper), level (0..1 meter), color (palette), choice, screen,
// text, words (space-separated list), strings, objects, colors (list editors),
// action (a key that runs something: run(), busy(), status(); no path).
// Optional: `when: () => bool` shows a setting only while it applies; a color
// setting takes `palette: "dark"` for background tones. `themed` marks the
// active theme's own settings (from its Spec.qml): read through Theme, with
// the theme's values as defaults.
Item {
    id: root

    property bool open: false
    property real maxHeight: 900

    property int section: 0

    readonly property var sections: [
        { title: "Appearance", items: [
            { label: "Wallpaper", path: "wallpaper.path", type: "text", hint: "image file; empty = plain" },
            { label: "Fit", path: "wallpaper.fit", type: "choice",
              options: [{ label: "fill", value: "fill" }, { label: "fit", value: "fit" },
                        { label: "center", value: "center" }, { label: "tile", value: "tile" }],
              when: () => !!Config.wallpaper.path },
            { label: "Plain color", path: "wallpaper.color", type: "color", palette: "dark",
              hint: "the background without a wallpaper", when: () => !Config.wallpaper.path },
            // The active theme's own knobs (its Spec.qml), kept per theme.
            ...(Theme.spec?.settings ?? []).map(item => Object.assign({}, item, {
                path: `theme.${Theme.name}.${item.path}`, themed: item.path
            }))
        ] },
        { title: "Bar", items: [
            { label: "Screen", path: "screen", type: "screen", hint: "where the shell lives" },
            { label: "Height", path: "bar.height", type: "int", min: 24, max: 48, suffix: "px" },
            { label: "Workspaces", path: "bar.workspaces", type: "int", min: 1, max: 10, hint: "shown at least" }
        ] },
        { title: "Launcher", items: [
            { label: "Terminal", path: "launcher.terminal", type: "words", hint: "command prefix, e.g. kitty -e" },
            { label: "Web search", path: "launcher.search", type: "text", hint: "%s is the query" },
            { label: "Entries", path: "launcher.entries", type: "objects", hint: "your own commands",
              fields: [
                  { key: "name", label: "name", type: "text" },
                  { key: "command", label: "command", type: "text", hint: "sh -c …" },
                  { key: "description", label: "description", type: "text" },
                  { key: "icon", label: "icon", type: "text", hint: "icon name or path" },
                  { key: "keywords", label: "keywords", type: "words", hint: "space separated" },
                  { key: "terminal", label: "in terminal", type: "bool" }
              ],
              title: e => e.name ?? "", subtitle: e => e.command ?? "" }
        ] },
        { title: "Calendar", items: [
            { label: "Week starts", path: "calendar.weekStart", type: "choice",
              options: [{ label: "mon", value: 1 }, { label: "sun", value: 0 }] },
            { label: "CalDAV URL", path: "calendar.url", type: "text", hint: "login from ~/.netrc" },
            { label: "Colors", path: "calendar.colors", type: "colors", hint: "one per calendar, in order" }
        ] },
        { title: "Notifications", items: [
            { label: "Popup time", path: "notifications.timeout", type: "int", min: 1, max: 30, suffix: "s",
              hint: "when the app doesn't say" },
            { label: "Muted apps", path: "notifications.mutedApps", type: "strings", hint: "popups silenced" }
        ] },
        { title: "Lock", items: [
            { label: "Lock after", path: "idle.lock", type: "int", min: 0, max: 120, suffix: "min",
              hint: "idle time before locking; 0 = never" },
            { label: "Screen off", path: "idle.screenOff", type: "int", min: 0, max: 120, suffix: "min",
              hint: "idle time before the display sleeps; 0 = never" },
            { label: "Idle icon", path: "idle.indicator", type: "int", min: 0, max: 300, suffix: "s",
              hint: "idle time before the bar's sleep glyph shows; 0 = never" },
            { label: "Passcode", path: "lock.passcode", type: "int", min: 0, max: 12, suffix: "ch",
              hint: "checks by itself after this many characters; must equal your password's length; 0 = press Enter" }
        ] },
        { title: "Control", items: [
            { label: "Tools", path: "controlCenter.tools", type: "objects", hint: "terminal keys",
              fields: [
                  { key: "label", label: "label", type: "text" },
                  { key: "command", label: "command", type: "text" }
              ],
              title: t => t.label ?? "", subtitle: t => t.command ?? "" }
        ] },
        { title: "Clipboard", items: [
            { label: "Terminals", path: "clipboard.terminals", type: "strings",
              hint: "window classes that paste with Ctrl+Shift+V" },
            { label: "Symbols", type: "action", button: "\u{F0450}  refresh",
              hint: "download the latest emoji, Nerd glyphs and symbols; kaomoji from assets/kaomoji.json",
              run: () => Symbols.refresh(), busy: () => Symbols.refreshing, status: () => Symbols.refreshStatus }
        ] },
        { title: "Shell", items: [
            { label: "Theme", path: "theme.name", type: "choice", hint: "how the shell looks; tweaks are kept per theme",
              options: Theme.names.map(n => ({ label: Theme.specs[n]?.label ?? n, value: n })) },
            { label: "Restart", type: "action", button: "\u{F0453}  restart",
              hint: "start Quickshell over as a new process; also: qs ipc call session restart",
              run: () => Session.restartShell(), busy: () => false, status: () => "" }
        ] }
    ]

    function defaultOf(item: var): var {
        return item.themed ? Theme.defaultOf(item.themed) : item.path.split(".").reduce((o, k) => o?.[k], Config.defaults);
    }

    width: 700
    implicitHeight: row.implicitHeight
    height: implicitHeight

    // Keys from a field (while typing, or after Enter leaves it) end up here.
    Keys.onEscapePressed: Panels.close()

    RowLayout {
        id: row

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: 14

        // ── Sections ─────────────────────────────────────────────────────────
        ColumnLayout {
            id: nav

            Layout.preferredWidth: 150
            Layout.maximumWidth: 150
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignTop
            spacing: 2

            SectionTitle {
                text: "Settings"
            }
            Repeater {
                model: root.sections

                ListRow {
                    required property var modelData
                    required property int index

                    implicitHeight: 28
                    current: root.section === index
                    onClicked: root.section = index

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.title
                        caps: true
                        color: root.section === index ? Theme.palette.accent : Theme.palette.dim
                        glow: root.section === index
                        font.pixelSize: Theme.font.size - 2
                        font.bold: true
                        tracking: 1.5
                    }
                }
            }
            Item {
                implicitHeight: 10
            }
            TextButton {
                text: "\u{F03EB}  edit file"
                onClicked: {
                    Launcher.runInTerminal(`nvim '${Quickshell.shellPath("config.json")}'`);
                    Panels.close();
                }
            }
        }

        Divider {
            Layout.fillHeight: true
            vertical: true
        }

        // ── The section's settings ───────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.preferredHeight: Math.max(nav.implicitHeight, Math.min(body.implicitHeight, root.maxHeight))

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
                        text: root.sections[root.section].title
                        code: "config.json"
                    }

                    Repeater {
                        model: root.sections[root.section].items

                        ColumnLayout {
                            id: setting

                            required property var modelData
                            readonly property var value: modelData.themed ? Theme.get(modelData.themed) : modelData.path ? Config.get(modelData.path) : undefined
                            readonly property bool wide: ["objects", "strings", "colors"].includes(modelData.type)
                            readonly property bool changed: !!modelData.path && JSON.stringify(value) !== JSON.stringify(root.defaultOf(modelData))

                            function save(v: var): void {
                                Config.set(modelData.path, v);
                            }

                            Layout.fillWidth: true
                            visible: modelData.when?.() ?? true
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                ColumnLayout {
                                    Layout.preferredWidth: 150
                                    Layout.minimumWidth: 150
                                    Layout.maximumWidth: 150
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
                                            onClicked: setting.save(root.defaultOf(setting.modelData))
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
                                    visible: !setting.wide
                                    active: !setting.wide
                                    sourceComponent: ({
                                        int: intControl, level: levelControl, color: colorControl,
                                        choice: choiceControl, screen: screenControl,
                                        text: textControl, words: textControl, action: actionControl
                                    })[setting.modelData.type] ?? null
                                }
                            }

                            Loader {
                                Layout.fillWidth: true
                                Layout.leftMargin: 4
                                visible: setting.wide
                                active: setting.wide
                                sourceComponent: ({
                                    strings: stringsControl, objects: objectsControl, colors: colorsControl
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
                                id: levelControl

                                RowLayout {
                                    spacing: 8

                                    Meter {
                                        Layout.fillWidth: true
                                        implicitHeight: 10
                                        value: setting.value ?? 0
                                        onMoved: v => setting.save(Math.round(v * 100) / 100)
                                    }
                                    StyledText {
                                        text: String(Math.round(setting.value * 100)).padStart(3, "0")
                                        color: Theme.palette.dim
                                        font.bold: true
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
                                        options: [{ label: "auto", value: "" }, ...Quickshell.screens.map(s => ({ label: s.name, value: s.name }))]
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
                                    readonly property bool words: setting.modelData.type === "words"

                                    prompt: ">"
                                    submitOnEnter: true
                                    text: words ? (setting.value ?? []).join(" ") : (setting.value ?? "")
                                    onAccepted: flash()
                                    onEditingFinished: {
                                        const v = words ? text.split(/\s+/).filter(w => w) : text.trim();
                                        if (JSON.stringify(v) !== JSON.stringify(setting.value)) {
                                            setting.save(v);
                                            flash();
                                        }
                                    }
                                }
                            }
                            Component {
                                id: actionControl

                                RowLayout {
                                    spacing: 12

                                    TextButton {
                                        text: setting.modelData.button
                                        enabled: !setting.modelData.busy()
                                        onClicked: setting.modelData.run()
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: setting.modelData.status()
                                        color: Theme.palette.dim
                                        font.pixelSize: Theme.font.size - 2
                                        wrapMode: Text.Wrap
                                    }
                                }
                            }
                            Component {
                                id: stringsControl

                                StringListEditor {
                                    items: setting.value ?? []
                                    onChanged: items => setting.save(items)
                                }
                            }
                            Component {
                                id: objectsControl

                                ObjectListEditor {
                                    items: setting.value ?? []
                                    fields: setting.modelData.fields
                                    title: setting.modelData.title
                                    subtitle: setting.modelData.subtitle
                                    onChanged: items => setting.save(items)
                                }
                            }
                            Component {
                                id: colorsControl

                                ColorListEditor {
                                    items: setting.value ?? []
                                    onChanged: items => setting.save(items)
                                }
                            }
                        }
                    }
                }
            }
            ScrollLamp {
                view: flick
            }
        }
    }
}
