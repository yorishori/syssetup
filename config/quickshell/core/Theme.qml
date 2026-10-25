pragma Singleton

import QtQuick
import Quickshell

// The active theme: how the shell looks, never what it does.
//
// A theme is a folder, themes/<name>/:
//   Spec.qml     its tokens (palette, font, glow, motion, swatches and anything
//                of its own)
//   <Skin>.qml   one skin per themed widget, drawing it from its `control`
//                (see components/Skinned.qml)
// Every theme provides every skin (scripts/check-theme.sh lists gaps). Skins
// shared by several themes live in a folder without a Spec.qml (themes/glyphs:
// the bar drawn as glyphs), and a theme's own skin file just points there.
//
// Which theme is active is a setting (Config.theme; switching applies live);
// your tweaks to each one's tokens are part of the setup (Setup.themes:
// { cyber: { palette: { accent: … } }, … }).
Singleton {
    id: root

    // Known themes, in the order Settings offers them.
    readonly property var names: ["cyber", "bubble", "hifi"]
    readonly property string name: names.includes(Config.theme) ? Config.theme : names[0]

    readonly property var specs: {
        const out = {};
        for (const n of names)
            out[n] = loadSpec(n);
        return out;
    }
    readonly property QtObject spec: specs[name] ?? specs[names[0]]

    // The theme's tokens with your tweaks (Setup.themes.<name>) over them.
    readonly property var values: Config.merge(spec?.defaults ?? {}, Setup.themes[name] ?? {})

    readonly property var palette: values.palette
    readonly property var font: values.font
    readonly property var glow: values.glow
    readonly property var motion: values.motion
    readonly property var swatches: values.swatches

    // The bar's height: yours (Setup.bar.height), but at least what the
    // theme needs for its parts (its Spec's bar.height).
    readonly property int barHeight: Math.max(Setup.bar.height, values.bar?.height ?? 0)

    // The session menu over the whole screen (modules/session/SessionScreen)
    // instead of as a drop from the bar (its Spec's layout.sessionScreen).
    readonly property bool sessionScreen: values.layout?.sessionScreen ?? false

    function loadSpec(n: string): QtObject {
        const comp = Qt.createComponent(Qt.resolvedUrl(`../themes/${n}/Spec.qml`));
        const obj = comp.status === Component.Ready ? comp.createObject(root) : null;
        if (!obj) {
            const error = comp.errorString().trim();
            Qt.callLater(() => Health.report("theme", `themes/${n}/Spec.qml failed to load: ${error}`));
        }
        return obj;
    }

    // A token at a dotted path inside the theme, e.g. get("palette.accent").
    function get(path: string): var {
        return path.split(".").reduce((o, k) => o?.[k], values);
    }

    // Label text as the theme sets labels (stencil capitals in cyber).
    function caps(text: string): string {
        return font.caps ? text.toUpperCase() : text;
    }

    function skinUrl(skin: string): url {
        return Qt.resolvedUrl(`../themes/${name}/${skin}.qml`);
    }

    onNameChanged: Health.resolve("theme")
}
