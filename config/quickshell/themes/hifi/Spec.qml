import QtQuick

// Hi-Fi: the shell as a rack of dark hi-fi gear, built from real materials
// lit from above. The bar is a brushed-metal faceplate with its workspaces in
// a black-glass display; panels are chassis plates that slide out from under
// it, screwed at the corners. Keys are keycaps that travel when pressed and
// latch in when on, lamps are LEDs in bezels, levels are LED ladders and
// faders, inputs and readouts are recessed glass displays whose lit text
// glows like a vacuum fluorescent display. Labels are silk-screened capitals.
// Motion is mechanical: firm, damped, no bounce.
QtObject {
    readonly property string label: "Hi-Fi"

    readonly property var defaults: ({
        // Anodized gunmetal and black glass, lit by LEDs and a teal VFD.
        palette: {
            bg: "#2a2c31",       // faceplate: the anodized metal (bar, panels)
            bgAlt: "#111214",    // black glass: recessed displays and wells
            shadow: "#060607",   // deep shadow; text on lit surfaces
            surface: "#3b3e45",  // keycaps; unlit segments
            border: "#545862",   // bevel edges
            fg: "#e6e3da",       // silk-screen white: primary content
            dim: "#a9a79f",      // calm state (bar default)
            muted: "#6e6f74",    // empty, secondary
            off: "#99e57a6c",    // switched off by you (mute, DND, radio off)
            accent: "#4ff0cf",   // VFD teal: lit, active, in use
            ok: "#7fe26b",       // green LED: up, healthy
            warn: "#ffb347",     // amber LED: needs attention
            error: "#ff5d55"     // red LED: broken
        },
        font: {
            family: "JetBrainsMono Nerd Font",
            size: 13,
            caps: true,          // labels silk-screened in capitals
            tracking: 1          // letter spacing scale for labels
        },
        // What `glow` on text means: a display segment lit from behind, a
        // soft bloom in its own color.
        glow: {
            opacity: 0.75,       // 0 = off
            blur: 0.55,
            blurMax: 10,
            offset: 0,
            tint: ""
        },
        // Mechanical: things slide on rails and settle, they don't bounce.
        motion: {
            spring: Easing.OutBack,
            springIn: Easing.InBack,
            bounce: 0.5
        },
        // What the color pickers offer: LED and display colors for accents,
        // metal finishes and glass for backgrounds.
        swatches: {
            accents: [
                "#4ff0cf", "#5ad7ff", "#7aa8ff", "#a78bfa", "#e879f9", "#ff6fa5", "#ff5d55",
                "#ff8a3d", "#ffb347", "#ffd75e", "#d4f45a", "#7fe26b", "#9ef0e0", "#f2efe6"
            ],
            dark: [
                "#060607", "#111214", "#1a1b1e",
                "#2a2c31", "#33302b", "#2d2a26", "#262a2e", "#23292b", "#2b2630", "#1f2430", "#302624"
            ]
        },
        // Hi-Fi's own.
        shape: {
            radius: 4,           // corner rounding of plates, keycaps and wells, px
            border: 1            // bevel and ring width, px
        },
        effects: {
            texture: 0.45,       // brushed-metal grain on plates, 0 = smooth
            shadow: 0.6,         // shadows cast by plates and keys, 0 = flat
            screws: true,        // screw heads on the corners of plates
            backdrop: 0.5        // darkening behind big panels, 0 = off
        }
    })

    // Settings → Appearance, for this theme (paths inside theme.hifi).
    readonly property var settings: [
        { label: "Display", path: "palette.accent", type: "color", hint: "the glass displays and lit keys" },
        { label: "Warning", path: "palette.warn", type: "color", hint: "needs attention" },
        { label: "Font size", path: "font.size", type: "int", min: 10, max: 18, suffix: "px" },
        { label: "Roundness", path: "shape.radius", type: "int", min: 0, max: 10, suffix: "px", hint: "plates, keycaps and wells" },
        { label: "Grain", path: "effects.texture", type: "level", hint: "brushed metal on the plates" },
        { label: "Glow", path: "glow.opacity", type: "level", hint: "bloom of lit displays and LEDs" },
        { label: "Shadow", path: "effects.shadow", type: "level", hint: "depth of plates and keys" },
        { label: "Backdrop", path: "effects.backdrop", type: "level", hint: "darkening behind big panels" }
    ]
}
