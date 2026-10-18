pragma Singleton

import QtQuick
import Quickshell

// The active theme: how the shell looks, never what it does.
//
// A theme is a folder, themes/<name>/:
//   Spec.qml     its tokens (palette, font, glow, motion, swatches and anything
//                of its own) and the knobs it puts in Settings → Appearance
//   <Skin>.qml   one skin per themed widget, drawing it from its `control`
//                (see components/Skinned.qml)
// Every theme provides every skin (scripts/check-theme.sh lists gaps).
//
// Which theme is active, and your tweaks to each one, live in config.json
// under `theme`: { name: "cyber", cyber: { palette: { accent: … } }, … }.
// Switching applies live.
Singleton {
    id: root

    // Known themes, in the order Settings offers them.
    readonly property var names: ["cyber", "bubble", "hifi"]
    readonly property string name: names.includes(Config.theme.name) ? Config.theme.name : names[0]

    readonly property var specs: {
        const out = {};
        for (const n of names)
            out[n] = loadSpec(n);
        return out;
    }
    readonly property QtObject spec: specs[name] ?? specs[names[0]]

    // The theme's tokens with your tweaks (config.json theme.<name>) over them.
    readonly property var values: Config.merge(spec?.defaults ?? {}, Config.theme[name] ?? {})

    readonly property var palette: values.palette
    readonly property var font: values.font
    readonly property var glow: values.glow
    readonly property var motion: values.motion
    readonly property var swatches: values.swatches

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

    // The theme's own value for a path, before your tweaks.
    function defaultOf(path: string): var {
        return path.split(".").reduce((o, k) => o?.[k], spec?.defaults);
    }

    // Change a token of the active theme (kept in config.json).
    function set(path: string, value: var): void {
        Config.set(`theme.${name}.${path}`, value);
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
