import QtQuick
import Quickshell
import qs.components

// The wallpaper a theme paints itself (its Wallpaper skin), on one screen.
// The skin gets the screen, so a scene can tell monitors apart.
Skinned {
    skin: "Wallpaper"

    required property ShellScreen screen
}
