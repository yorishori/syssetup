#!/usr/bin/env bash
# Check the shell's structure (see README.md). Prints each problem; exits 1
# if there are any.
#
#   Layers   core imports no other layer; services and components only core;
#            modules anything but themes. Themes draw: they import core,
#            components and modules (for types), never services.
#   Skins    every theme has a skin for every skinned widget (each
#            `skin: "Name"` in components/ and modules/), its own or shared
#            (themes/glyphs).
#   Styling  components/ and modules/ hold no raw styling: no shapes, effects
#            or hex colors, no plain Rectangles, no style config, no hand-made
#            casing or letter spacing, no theme motion constants.
#   Keys     skins decide no keys: they forward their field's keys to the
#            panel (Keys.onPressed → control.fieldKey), nothing else.
#   Lists    every theme folder is in Theme.names and imported in shell.qml;
#            every panel in Panels.names is a row in Bar.qml's `panels` or a
#            module of its own, and every bar panel has its <Name>Panel.qml.
#   Plain    the plain stand-ins (modules/**/Plain*.qml) import only QtQuick
#            and services, so nothing a theme breaks can reach them. They're
#            exempt from the styling rules.
#
#     scripts/check.sh
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
status=0

fail() {
    echo "$1"
    status=1
}

# Layers: <dir> <tab> imports it may not use
while IFS=$'\t' read -r dir banned; do
    hits=$(grep -rnE "^import qs\.($banned)\b" "$dir" --include='*.qml')
    [[ -n "$hits" ]] && fail "$(echo "$hits" | sed "s#\$#    <- $dir/ may not import qs.($banned)#")"
done <<'EOF'
core	services|components|modules|themes
services	components|modules|themes
components	services|modules|themes
modules	themes
themes	services
EOF

# Skins
skins=$(grep -rhoE '^\s*skin: "[A-Za-z]+"' components modules | grep -oE '"[A-Za-z]+"' | tr -d '"' | sort -u)
for spec in themes/*/Spec.qml; do
    theme=$(dirname "$spec")
    for skin in $skins; do
        [[ -f "$theme/$skin.qml" || -f "themes/glyphs/$skin.qml" ]] || fail "$theme: no skin $skin.qml (nor themes/glyphs/$skin.qml)"
    done
done

# Styling: pattern <TAB> why
while IFS=$'\t' read -r pattern why; do
    # StyledText implements tracking and glow; it's the one allowed place.
    hits=$(grep -rnE "$pattern" components modules --include='*.qml' | grep -v '^components/StyledText.qml:' \
        | grep -vE '^[^:]+/Plain[A-Za-z]*\.qml:' | grep -vE '^[^:]+:[0-9]+:\s*//')
    [[ -n "$hits" ]] && fail "$(echo "$hits" | sed "s|\$|    <- $why|")"
done <<'EOF'
Config\.(colors|font|shape|effects)	style lives in the theme (Theme.palette, Theme.font, …)
\b(Chamfer|Scanlines|Shape|ShapePath|MultiEffect)\b	drawing belongs in a skin
"#[0-9a-fA-F]{3,8}"	use a palette role
^\s*Rectangle \{	drawing belongs in a skin (Divider, Marker, …)
Easing\.(OutBack|InBack)	use Theme.motion
font\.letterSpacing	use StyledText's tracking
text:.*toUpperCase\(\)	use StyledText's caps (or Theme.caps)
EOF

# Keys
hits=$(grep -rnE 'Keys\.on[A-Z][A-Za-z]*Pressed' themes --include='*.qml' | grep -vE 'Keys\.onPressed: event => event\.accepted = root\.control\.fieldKey\(')
[[ -n "$hits" ]] && fail "$(echo "$hits" | sed 's|$|    <- a skin forwards keys to control.fieldKey, the panel decides|')"

# Plain stand-ins
for f in $(find modules -name 'Plain*.qml'); do
    hits=$(grep -nE '^import ' "$f" | grep -vE '^[0-9]+:import (QtQuick|qs\.services)$')
    [[ -n "$hits" ]] && fail "$(echo "$hits" | sed "s|^|$f:|; s|\$|    <- a plain stand-in uses QtQuick and services only|")"
done

# Lists: themes
names=$(grep -oE 'names: \[[^]]*\]' core/Theme.qml | grep -oE '"[a-z]+"' | tr -d '"' | sort)
folders=$(for spec in themes/*/Spec.qml; do basename "$(dirname "$spec")"; done | sort)
[[ "$names" == "$folders" ]] || fail "core/Theme.qml: names ($(echo $names)) differ from the theme folders ($(echo $folders))"
for theme in $folders glyphs; do
    grep -qE "^import qs\.themes\.$theme\b" shell.qml || fail "shell.qml: no import qs.themes.$theme (the folder isn't known without it)"
done

# Lists: panels
ipc=$(tr '\n' ' ' < services/Panels.qml | grep -oE 'names: \[[^]]*\]' | grep -oE '"[a-z]+"' | tr -d '"' | sort)
bar=$(sed -n '/property var panels: \[/,/^    \]/p' modules/bar/Bar.qml | grep -oE '\{ name: "[a-z]+"' | grep -oE '"[a-z]+"' | tr -d '"' | sort)
for panel in $ipc; do
    grep -qx "$panel" <<<"$bar" \
        || grep -qE "path: \"modules/$panel/" shell.qml \
        || fail "services/Panels.qml: \"$panel\" is neither in Bar.qml's panels nor a module in shell.qml"
done
for panel in $bar; do
    [[ "$panel" == tray ]] || grep -qx "$panel" <<<"$ipc" || fail "modules/bar/Bar.qml: panel \"$panel\" is missing from Panels.names (IPC can't open it)"
    file="modules/$panel/${panel^}Panel.qml"
    [[ -f "$file" ]] || fail "modules/bar/Bar.qml: panel \"$panel\" has no $file"
done

[[ $status -eq 0 ]] && echo "ok: $(ls themes/*/Spec.qml | wc -l) themes, $(echo "$skins" | wc -l) skins each"
exit $status
