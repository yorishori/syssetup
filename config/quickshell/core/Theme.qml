pragma Singleton

import QtQml
import QtQuick
import Quickshell
import "merge.js" as Merge

// The active theme: how the shell looks, never what it does.
//
// A theme is a folder, themes/<name>/:
//   Spec.qml     its tokens (palette, font, glow, motion, swatches and anything
//                of its own), and `fonts`: font files in its folder, loaded
//                while it's active (nothing is installed)
//   <Skin>.qml   one skin per themed widget, drawing it from its `control`
//                (see components/Skinned.qml)
// A skin the theme has no file for comes from themes/glyphs (the shared
// layouts: the bar drawn as glyphs, the panels); so does one whose file is
// broken, which Health is told about. scripts/check.sh lists skins
// found in neither.
//
// Which theme is active is a setting (Config.theme; switching applies live);
// your tweaks to each one's tokens are part of the setup (Setup.themes:
// { cyber: { palette: { accent: … } }, … }).
Singleton {
    id: root

    // Known themes, in the order Settings offers them.
    readonly property var names: ["cyber", "bubble", "hifi", "oneshot"]
    readonly property string name: names.includes(Config.theme) ? Config.theme : names[0]

    readonly property var specs: {
        const out = {};
        for (const n of names)
            out[n] = loadSpec(n);
        return out;
    }
    readonly property QtObject spec: specs[name] ?? specs[names[0]]

    // The theme's tokens with your tweaks (Setup.themes.<name>) over them.
    readonly property var values: Merge.merge(spec?.defaults ?? {}, Setup.themes[name] ?? {})

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

    // Where skins come from when the theme has none of its own.
    readonly property string shared: "glyphs"
    // { "<theme>/<skin>": url }, resolved once each.
    property var skinUrls: ({})

    function skinUrl(skin: string): url {
        const key = `${name}/${skin}`;
        if (key in skinUrls)
            return skinUrls[key];
        let url = Qt.resolvedUrl(`../themes/${name}/${skin}.qml`);
        const comp = Qt.createComponent(url, Component.PreferSynchronous);
        if (comp.status === Component.Error) {
            const error = comp.errorString().trim();
            if (!error.endsWith("File not found"))
                Qt.callLater(() => Health.report("theme", `${key}.qml is broken, using the shared skin: ${error}`));
            url = Qt.resolvedUrl(`../themes/${shared}/${skin}.qml`);
        }
        skinUrls[key] = url;
        return url;
    }

    // Whether the theme draws this skin itself (a working file of its own),
    // for the few places that do something else when it doesn't: the
    // wallpaper shows your image unless the theme paints a scene.
    function owns(skin: string): bool {
        return !String(skinUrl(skin)).endsWith(`/themes/${shared}/${skin}.qml`);
    }

    // The theme's own font files (its Spec's `fonts`, paths in its folder).
    // Families stay registered after a switch; that's harmless.
    Instantiator {
        model: root.spec?.fonts ?? []

        delegate: FontLoader {
            required property string modelData

            source: Qt.resolvedUrl(`../themes/${root.name}/${modelData}`)
            onStatusChanged: {
                if (status === FontLoader.Error)
                    Health.report("theme", `${root.name}: can't load the font ${modelData}`);
            }
        }
    }

    onNameChanged: Health.resolve("theme")
}
