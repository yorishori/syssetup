pragma Singleton

import QtQuick
import Quickshell

// Resolves an icon reference to something an Image can load: a theme icon
// name, an absolute path (some desktop entries use those, e.g. kitty) or a
// URL. "" when there's nothing to show.
Singleton {
    function url(icon: string): string {
        if (!icon)
            return "";
        if (icon.startsWith("file:") || icon.startsWith("image:") || icon.startsWith("qrc:"))
            return icon;
        if (icon.startsWith("/"))
            return "file://" + icon;
        return Quickshell.iconPath(icon, true);
    }
}
