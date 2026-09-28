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
// setting takes `palette: "dark"` for background tones.
Item {
    id: root

    property bool open: false
    property real maxHeight: 900

    property int section: 0

    readonly property var sections: [
        { title: "APPEARANCE", items: [
            { label: "Wallpaper", path: "wallpaper.path", type: "text", hint: "image file; empty = plain" },
            { label: "Fit", path: "wallpaper.fit", type: "choice",
              options: [{ label: "FILL", value: "fill" }, { label: "FIT", value: "fit" },
                        { label: "CENTER", value: "center" }, { label: "TILE", value: "tile" }],
              when: () => !!Config.wallpaper.path },
            { label: "Plain color", path: "wallpaper.color", type: "color", palette: "dark",
              hint: "the background without a wallpaper", when: () => !Config.wallpaper.path },
            { label: "Accent", path: "colors.accent", type: "color", hint: "lit, active, in use" },
            { label: "Warning", path: "colors.warn", type: "color", hint: "needs attention" },
            { label: "Font size", path: "font.size", type: "int", min: 10, max: 18, suffix: "px" },
            { label: "Corner cut", path: "shape.cut", type: "int", min: 0, max: 14, suffix: "px" },
            { label: "Glow", path: "effects.glow", type: "level", hint: "halo on lit things" },
            { label: "Scanlines", path: "effects.scanlines", type: "level" },
            { label: "Backdrop", path: "effects.backdrop", type: "level", hint: "darkening behind big panels" }
        ] },
        { title: "BAR", items: [
            { label: "Screen", path: "screen", type: "screen", hint: "where the shell lives" },
            { label: "Height", path: "bar.height", type: "int", min: 24, max: 48, suffix: "px" },
            { label: "Workspaces", path: "bar.workspaces", type: "int", min: 1, max: 10, hint: "shown at least" }
        ] },
        { title: "LAUNCHER", items: [
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
        { title: "CALENDAR", items: [
            { label: "Week starts", path: "calendar.weekStart", type: "choice",
              options: [{ label: "MON", value: 1 }, { label: "SUN", value: 0 }] },
            { label: "CalDAV URL", path: "calendar.url", type: "text", hint: "login from ~/.netrc" },
            { label: "Colors", path: "calendar.colors", type: "colors", hint: "one per calendar, in order" }
        ] },
        { title: "NOTIFICATIONS", items: [
            { label: "Popup time", path: "notifications.timeout", type: "int", min: 1, max: 30, suffix: "s",
              hint: "when the app doesn't say" },
            { label: "Muted apps", path: "notifications.mutedApps", type: "strings", hint: "popups silenced" }
        ] },
        { title: "LOCK", items: [
            { label: "Lock after", path: "idle.lock", type: "int", min: 0, max: 120, suffix: "min",
              hint: "idle time before locking; 0 = never" },
            { label: "Screen off", path: "idle.screenOff", type: "int", min: 0, max: 120, suffix: "min",
              hint: "idle time before the display sleeps; 0 = never" },
            { label: "Passcode", path: "lock.passcode", type: "int", min: 0, max: 12, suffix: "ch",
              hint: "checks by itself after this many characters; must equal your password's length; 0 = press Enter" }
        ] },
        { title: "SERVER", items: [
            { label: "Name", path: "server.name", type: "text" },
            { label: "Host", path: "server.host", type: "text", hint: "pinged for the main lamp; empty hides the section" },
            { label: "SSH key", path: "server.ssh", type: "text", hint: "terminal command, e.g. ssh koi-server" },
            { label: "Services", path: "server.services", type: "objects", hint: "a lamp each, checked over HTTP",
              fields: [
                  { key: "name", label: "name", type: "text" },
                  { key: "url", label: "url", type: "text", hint: "http://host:port" }
              ],
              title: s => s.name ?? "", subtitle: s => s.url ?? "" }
        ] },
        { title: "CONTROL", items: [
            { label: "Tools", path: "controlCenter.tools", type: "objects", hint: "terminal keys",
              fields: [
                  { key: "label", label: "label", type: "text" },
                  { key: "command", label: "command", type: "text" }
              ],
              title: t => t.label ?? "", subtitle: t => t.command ?? "" }
        ] },
        { title: "CLIPBOARD", items: [
            { label: "Terminals", path: "clipboard.terminals", type: "strings",
              hint: "window classes that paste with Ctrl+Shift+V" },
            { label: "Symbols", type: "action", button: "\u{F0450}  refresh",
              hint: "download the latest emoji, Nerd glyphs and symbols; kaomoji from assets/kaomoji.json",
              run: () => Symbols.refresh(), busy: () => Symbols.refreshing, status: () => Symbols.refreshStatus }
        ] }
    ]

    function defaultOf(path: string): var {
        return path.split(".").reduce((o, k) => o?.[k], Config.defaults);
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
                text: "SETTINGS"
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
                        color: root.section === index ? Config.colors.accent : Config.colors.dim
                        glow: root.section === index
                        font.pixelSize: Config.font.size - 2
                        font.bold: true
                        font.letterSpacing: 1.5
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

        Rectangle {
            Layout.fillHeight: true
            implicitWidth: 1
            color: Config.colors.border
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
                        code: "CONFIG.JSON"
                    }

                    Repeater {
                        model: root.sections[root.section].items

                        ColumnLayout {
                            id: setting

                            required property var modelData
                            readonly property var value: modelData.path ? Config.get(modelData.path) : undefined
                            readonly property bool wide: ["objects", "strings", "colors"].includes(modelData.type)
                            readonly property bool changed: !!modelData.path && JSON.stringify(value) !== JSON.stringify(root.defaultOf(modelData.path))

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
                                            iconColor: Config.colors.muted
                                            visible: setting.changed
                                            onClicked: setting.save(root.defaultOf(setting.modelData.path))
                                        }
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: setting.modelData.hint ?? ""
                                        color: Config.colors.muted
                                        font.pixelSize: Config.font.size - 3
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
                                        value: setting.value
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
                                        value: setting.value
                                        onMoved: v => setting.save(Math.round(v * 100) / 100)
                                    }
                                    StyledText {
                                        text: String(Math.round(setting.value * 100)).padStart(3, "0")
                                        color: Config.colors.dim
                                        font.bold: true
                                    }
                                }
                            }
                            Component {
                                id: colorControl

                                Swatches {
                                    palette: setting.modelData.palette === "dark" ? dark : accents
                                    current: setting.value || (setting.modelData.palette === "dark" ? Config.colors.bg : "")
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
                                        options: [{ label: "AUTO", value: "" }, ...Quickshell.screens.map(s => ({ label: s.name, value: s.name }))]
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
                                        color: Config.colors.dim
                                        font.pixelSize: Config.font.size - 2
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
