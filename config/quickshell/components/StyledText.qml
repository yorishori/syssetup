import QtQuick
import QtQuick.Effects
import qs.core

// All text goes through here. Text isn't skinned (it's everywhere and carries
// layout); the theme styles it through tokens instead:
//
// Plain text unless asked otherwise: much of what's shown comes from outside
// (notifications, window titles, calendar events), and Qt would otherwise
// guess markup in it and load the images it names.
//
//   glow      emphasis for lit things (cyber: a phosphor halo in the text's color)
//   caps      a label: capitals when the theme sets labels that way
//   tracking  letter spacing for labels, scaled by the theme
Text {
    id: root

    property bool glow: false
    property bool caps: false
    property real tracking: 0

    textFormat: Text.PlainText
    color: Theme.palette.fg
    font.family: Theme.font.family
    font.pixelSize: Theme.font.size
    font.capitalization: caps && Theme.font.caps ? Font.AllUppercase : Font.MixedCase
    font.letterSpacing: tracking * Theme.font.tracking
    verticalAlignment: Text.AlignVCenter

    layer.enabled: glow && Theme.glow.opacity > 0
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.glow.tint || root.color
        shadowOpacity: Theme.glow.opacity
        shadowBlur: Theme.glow.blur
        blurMax: Theme.glow.blurMax
        shadowHorizontalOffset: 0
        shadowVerticalOffset: Theme.glow.offset
    }
}
