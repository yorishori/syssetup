pragma Singleton

import QtQuick
import Quickshell

// How this machine is set up: the things decided once and changed by editing
// this file (it's part of the project). What's changed now and then from the
// Settings panel lives in Config instead.
Singleton {
    // Each theme's tokens, over its own (themes/<name>/Spec.qml), e.g.
    // cyber: { palette: { accent: "#89b4fa" } }. See core/Theme.qml.
    readonly property var themes: ({
        cyber: {
            palette: {
                bg: "#11111b",
                bgAlt: "#181825",
                shadow: "#11111b",
                surface: "#313244",
                border: "#45475a",
                fg: "#cdd6f4",
                dim: "#a6adc8",
                muted: "#6c7086",
                off: "#99eba0ac",
                accent: "#89b4fa",
                ok: "#a6e3a1",
                warn: "#fab387",
                error: "#f38ba8"
            },
            font: {
                family: "JetBrainsMono Nerd Font",
                size: 14
            },
            shape: {
                cut: 6,
                border: 1
            },
            glow: {
                opacity: 0.6
            },
            effects: {
                scanlines: 0.25,
                backdrop: 0.45
            }
        },
        bubble: {},
        hifi: {}
    })

    // The bar: its height (a theme can ask for more), and the room at its
    // ends and between its groups.
    readonly property var bar: ({
        height: 40,
        padding: 18,
        spacing: 16
    })

    readonly property var launcher: ({
        terminal: ["kitty", "-e"],                  // prefix for terminal commands
        search: "https://duckduckgo.com/?q=%s",     // web search URL (%s = query)
        // Your own entries: { name, command, description?, icon?, terminal?, keywords? }
        entries: [
            {
                name: "QS",
                description: "Edit Quickshell",
                icon: "nvim",
                command: "cd $HOME/.config/quickshell && nvim .",
                terminal: true,
                keywords: ["quickshell", "shell", "config"]
            },
            {
                name: "sway",
                description: "Edit Sway",
                icon: "nvim",
                command: "cd $HOME/.config/sway && nvim .",
                terminal: true,
                keywords: ["sway", "config"]
            }
        ]
    })

    readonly property var calendar: ({
        weekStart: 1,       // first day of the week: 1 = Monday, 0 = Sunday
        // CalDAV server (read-only); login from ~/.netrc. Empty = no events.
        url: "http://192.168.1.10:9001/dav/",
        // One color per calendar, in the order the server lists them.
        colors: ["#94e2d5", "#cba6f7", "#89b4fa", "#a6e3a1", "#f5c2e7", "#fab387"]
    })

    // The control center's tool keys; each opens in the terminal.
    readonly property var tools: [
        { label: "btop", command: "btop" },
        { label: "nyst", command: "nyst" },
        { label: "ssh", command: "ssh yori@192.168.1.10" }
    ]

    // Where the capture prompt suggests saving at first (after that, the
    // last folder used; see Config).
    readonly property var capture: ({
        screenshots: "~/Pictures/Screenshots",
        recordings: "~/Videos/Recordings",
        voice: "~/Music/Voice"
    })

    // Window classes that paste with Ctrl+Shift+V instead of Ctrl+V.
    readonly property var terminals: ["kitty"]

    // Seconds a notification popup stays up when the app doesn't say.
    readonly property int popupTimeout: 5

    // Seconds idle before the bar's sleep glyph shows; 0 = never.
    readonly property int idleIndicator: 10
}
