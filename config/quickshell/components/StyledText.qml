import QtQuick
import QtQuick.Effects
import qs.core

// All text goes through here. `glow` gives it a phosphor halo in its own color.
Text {
    id: root

    property bool glow: false

    color: Config.colors.fg
    font.family: Config.font.family
    font.pixelSize: Config.font.size
    verticalAlignment: Text.AlignVCenter

    layer.enabled: glow && Config.effects.glow > 0
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: root.color
        shadowOpacity: Config.effects.glow
        shadowBlur: 0.8
        blurMax: 12
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
    }
}
