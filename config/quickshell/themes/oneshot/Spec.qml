import QtQuick

// OneShot: a rainy night in an enchanted pine forest, in pixel art. The
// wallpaper is the forest (a stone lantern, glowing mushrooms, fireflies,
// rain), and its top edge is a mossy bough the bar's applets hang from on
// twine. Panels are framed boxes, cream on plum, like an old RPG's menus,
// but every label says plainly what it is. A black cat with pumpkin eyes
// naps on the bar and wanders into panels. Motion is slow and stepped, a
// few frames a second, never tweened.
//
// The primitives (Box, Card, Chip, …) start from bubble's and are being
// redrawn; the fonts are bundled under fonts/ with their licenses (OFL 1.1).
QtObject {
    readonly property string label: "OneShot"

    // Loaded from this folder while the theme is active (core/Theme.qml).
    readonly property var fonts: ["fonts/PixelifySans.ttf", "fonts/Silkscreen-Regular.ttf"]

    readonly property var defaults: ({
        // Night plum and cream, lit by a lantern.
        palette: {
            bg: "#231e36",       // plum: panels and signs
            bgAlt: "#17142a",    // deep plum: wells, fields, tracks
            shadow: "#0e0c16",   // outline around frames; text on lit surfaces
            surface: "#2f2848",  // raised plum: keys, selected rows
            border: "#cdbf9f",   // the cream frame
            fg: "#ece3d2",       // cream text
            dim: "#b5a8e0",      // lavender: calm state, small labels
            muted: "#7a7299",    // empty, secondary
            off: "#99e8a0b4",    // rose at 60%: switched off by you
            accent: "#f2c46d",   // lantern amber: lit, active, current
            ok: "#8fd6b4",       // mushroom mint
            warn: "#ff9a2e",     // pumpkin
            error: "#ef6f7f"     // berry red
        },
        font: {
            family: "Pixelify Sans",
            size: 14,
            caps: false,
            tracking: 0,
            labels: "Silkscreen" // tiny capital labels (VOLUME, WI-FI, …)
        },
        // Pixels don't bloom.
        glow: {
            opacity: 0,
            blur: 0,
            blurMax: 0,
            offset: 0,
            tint: ""
        },
        // Calm: things ease in and settle, nothing overshoots.
        motion: {
            spring: Easing.OutCubic,
            springIn: Easing.InCubic,
            bounce: 0
        },
        swatches: {
            accents: [
                "#f2c46d", "#ff9a2e", "#ef6f7f", "#e8a0b4", "#b5a8e0", "#8f86ad", "#6f8fd6",
                "#7ab8d6", "#8fd6b4", "#b8d68f", "#e8dcc0", "#ece3d2", "#cdbf9f", "#d9b77a"
            ],
            dark: [
                "#0e0c16", "#15141f", "#17142a",
                "#1b1d3a", "#231e36", "#2f2848", "#2a2238", "#14152a", "#141224", "#3a2a24", "#2c4236"
            ]
        },
        // Square pixels: no rounding, framed edges.
        shape: {
            radius: 0,
            border: 2,
            outline: 3
        },
        effects: {
            shadow: 0,
            backdrop: 0.35
        },
        // The lock fades the forest in over the desktop and out again, in
        // four steps (see LockScreen), this long each way.
        layout: {
            lockClose: 400,
            lockOpen: 400
        },
        // OneShot's own.
        // The bar is the wallpaper's bough with signs hanging from it:
        // `bough` is where the bough's underside is (the wallpaper paints
        // it, 6 art pixels), `offset` how far below the middle the signs'
        // contents sit.
        bar: {
            height: 68,
            bough: 18,
            offset: 10
        },
        // Every panel's window has its name on top in lantern amber; the
        // launcher titles itself by its mode, the OSD and tray menus go
        // without.
        titles: {
            calendar: "Calendar",
            network: "Network",
            bluetooth: "Bluetooth",
            audio: "Audio",
            notifications: "Notifications",
            control: "Control center",
            session: "Session",
            settings: "Settings",
            keys: "Keys",
            clipboard: "Clipboard",
            compose: "Compose",
            capture: "Save"
        },
        // How the pixel art is drawn and moves: each art pixel is `scale`
        // screen pixels; idle loops step at `fps`. `animate: false` holds
        // every loop on its first frame.
        pixel: {
            scale: 3,
            fps: 4,
            animate: true
        }
    })
}
