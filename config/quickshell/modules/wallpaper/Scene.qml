import QtQuick
import Quickshell
import qs.components
import qs.services

// The wallpaper a theme paints itself (its Wallpaper skin), on one screen.
// The skin gets the screen, so a scene can tell monitors apart, and
// `covered` while a fullscreen window hides it, so an animated scene can
// hold still meanwhile.
Skinned {
    skin: "Wallpaper"

    required property ShellScreen screen

    readonly property bool covered: {
        if (!Wm.fullscreen)
            return false;
        // On this screen (if it says which; if not, assume so).
        const on = Array.from(Wm.activeWindow?.toplevel?.screens ?? []);
        return on.length === 0 || on.some(s => s?.name === screen?.name);
    }
}
