import QtQuick

// Bubble: a first sketch, to be designed. For now cyber's layout with
// rounded corners, sentence-case labels, no glow or scanlines.
QtObject {
    readonly property string label: "Bubble"

    readonly property var defaults: ({
        // Catppuccin Mocha, by role (as in cyber).
        palette: {
            bg: "#1e1e2e",       // base
            bgAlt: "#181825",    // mantle
            shadow: "#11111b",   // crust: text on lit surfaces
            surface: "#313244",  // surface0
            border: "#45475a",   // surface1
            fg: "#cdd6f4",       // text
            dim: "#a6adc8",      // subtext0
            muted: "#6c7086",    // overlay0
            off: "#99eba0ac",    // maroon at 60%
            accent: "#cba6f7",   // mauve
            ok: "#a6e3a1",       // green
            warn: "#fab387",     // peach
            error: "#f38ba8"     // red
        },
        font: {
            family: "JetBrainsMono Nerd Font",
            size: 13,
            caps: false,
            tracking: 0
        },
        glow: {
            opacity: 0,
            blur: 0.5,
            blurMax: 8,
            offset: 1,
            tint: "#11111b"
        },
        motion: {
            spring: Easing.OutBack,
            springIn: Easing.InBack
        },
        swatches: {
            accents: [
                "#f5e0dc", "#f2cdcd", "#f5c2e7", "#cba6f7", "#f38ba8", "#eba0ac", "#fab387",
                "#f9e2af", "#a6e3a1", "#94e2d5", "#89dceb", "#74c7ec", "#89b4fa", "#b4befe"
            ],
            dark: [
                "#11111b", "#181825", "#1e1e2e",
                "#272335", "#2c202c", "#2d2428", "#2d2a2d", "#232a2b", "#212a31", "#1f2536", "#2c2633"
            ]
        },
        // Bubble's own.
        shape: {
            radius: 10,          // corner rounding, px
            border: 1            // outline width, px
        },
        effects: {
            backdrop: 0.45       // darkening behind big panels, 0 = off
        }
    })

    // Settings → Appearance, for this theme (paths inside theme.bubble).
    readonly property var settings: [
        { label: "Accent", path: "palette.accent", type: "color", hint: "lit, active, in use" },
        { label: "Warning", path: "palette.warn", type: "color", hint: "needs attention" },
        { label: "Font size", path: "font.size", type: "int", min: 10, max: 18, suffix: "px" },
        { label: "Roundness", path: "shape.radius", type: "int", min: 0, max: 20, suffix: "px" },
        { label: "Backdrop", path: "effects.backdrop", type: "level", hint: "darkening behind big panels" }
    ]
}
