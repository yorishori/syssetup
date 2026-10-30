pragma Singleton

import QtQuick
import Quickshell

// How this machine is set up: the things decided once and changed by editing
// this file (it's part of the project). What's changed now and then from the
// Settings panel lives in Config instead.
Singleton {
    // Your tweaks to each theme's tokens, over its own (themes/<name>/Spec.qml:
    // only what differs). See core/Theme.qml.
    readonly property var themes: ({
        cyber: {
            palette: { accent: "#89b4fa" },
            font: { size: 14 }
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
                command: "cd $HOME/.config/sway && nvim config",
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
