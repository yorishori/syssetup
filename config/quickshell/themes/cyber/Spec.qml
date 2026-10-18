import QtQuick

// Cyber: a retro-futurist console. Dark crust, hairlines, 45-degree corner
// cuts, stencilled capitals, phosphor glow on lit things, faint CRT
// scanlines, springy motion. Catppuccin Mocha colors.
QtObject {
    readonly property string label: "Cyber"

    readonly property var defaults: ({
        // Catppuccin Mocha, by role.
        palette: {
            bg: "#11111b",       // crust: the console (bar and drops)
            bgAlt: "#181825",    // mantle: recessed wells (meters, inputs)
            shadow: "#11111b",   // crust: text on lit surfaces
            surface: "#313244",  // surface0: hover, unlit segments
            border: "#45475a",   // surface1: hairlines
            fg: "#cdd6f4",       // text: primary content
            dim: "#a6adc8",      // subtext0: calm state (bar default)
            muted: "#6c7086",    // overlay0: empty, secondary
            off: "#99eba0ac",    // maroon at 60%: switched off by you (mute, DND, radio off)
            accent: "#94e2d5",   // teal: lit / active / in use
            ok: "#a6e3a1",       // green: up / healthy (lamps)
            warn: "#fab387",     // peach: needs attention
            error: "#f38ba8"     // red: broken
        },
        font: {
            family: "JetBrainsMono Nerd Font",
            size: 13,
            caps: true,          // labels in stencil capitals
            tracking: 1          // letter spacing scale for labels
        },
        // What `glow` on text means: a phosphor halo in the text's own color.
        glow: {
            opacity: 0.6,        // 0 = off
            blur: 0.8,
            blurMax: 12,
            offset: 0,
            tint: ""             // "" = the text's color
        },
        motion: {
            spring: Easing.OutBack,  // things settling into place
            springIn: Easing.InBack, // things leaving
            bounce: 1.70158          // how far springs overshoot (Qt's default)
        },
        // What the color pickers offer, so nothing off-theme can be picked:
        // Mocha's accents, and backgrounds (crust, mantle and base, then the
        // accents at 12% over crust: mauve, red, peach, yellow, green, teal,
        // blue, pink).
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
        // Cyber's own: geometry and effects.
        shape: {
            cut: 6,              // size of the 45-degree corner cuts, px
            border: 1            // hairline width, px
        },
        effects: {
            scanlines: 0.25,     // scanline strength on panels, 0 = off
            backdrop: 0.45       // darkening behind big panels, 0 = off
        }
    })

    // Settings → Appearance, for this theme (paths inside theme.cyber).
    readonly property var settings: [
        { label: "Accent", path: "palette.accent", type: "color", hint: "lit, active, in use" },
        { label: "Warning", path: "palette.warn", type: "color", hint: "needs attention" },
        { label: "Font size", path: "font.size", type: "int", min: 10, max: 18, suffix: "px" },
        { label: "Corner cut", path: "shape.cut", type: "int", min: 0, max: 14, suffix: "px" },
        { label: "Glow", path: "glow.opacity", type: "level", hint: "halo on lit things" },
        { label: "Scanlines", path: "effects.scanlines", type: "level" },
        { label: "Backdrop", path: "effects.backdrop", type: "level", hint: "darkening behind big panels" }
    ]
}
