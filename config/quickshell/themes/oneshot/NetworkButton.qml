import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// Ethernet when wired, Wi-Fi bars by signal strength. Dim when online, peach
// (pulsing while connecting) when not, dim red when Wi-Fi is off.
Glyph {
    id: root

    required property W.NetworkButton control

    text: {
        if (control.wired)
            return "\u{F0200}";
        if (!control.wifiEnabled)
            return "\u{F092E}";
        const s = control.strength;
        return s >= 75 ? "\u{F0928}"
            : s >= 50 ? "\u{F0925}"
            : s >= 25 ? "\u{F0922}"
            : s >= 0 ? "\u{F091F}"
            : "\u{F092F}";
    }
    color: control.online ? Theme.palette.dim
        : !control.wifiEnabled ? Theme.palette.off
        : Theme.palette.warn

    Behavior on color {
        ColorAnimation { duration: 250 }
    }

    SequentialAnimation on opacity {
        running: root.control.connecting
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
    }
}
