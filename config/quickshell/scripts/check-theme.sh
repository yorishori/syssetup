#!/usr/bin/env bash
# Check the theme split (core/Theme.qml):
#   - every theme (themes/<name>/Spec.qml) has a skin for every skinned widget
#     (each `skin: "Name"` in components/ and modules/)
#   - components/ and modules/ hold no raw styling: no shapes, effects or
#     hex colors, no plain Rectangles, no style config, no hand-made casing or
#     letter spacing, no theme motion constants. That belongs in the skins.
#
#     scripts/check-theme.sh
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
status=0

skins=$(grep -rhoE '^\s*skin: "[A-Za-z]+"' components modules | grep -oE '"[A-Za-z]+"' | tr -d '"' | sort -u)
for spec in themes/*/Spec.qml; do
    theme=$(dirname "$spec")
    for skin in $skins; do
        if [[ ! -f "$theme/$skin.qml" ]]; then
            echo "$theme: missing skin $skin.qml"
            status=1
        fi
    done
done

# pattern <TAB> why
rules=$(cat <<'EOF'
Config\.(colors|font|shape|effects)	style lives in the theme (Theme.palette, Theme.font, …)
\b(Chamfer|Scanlines|Shape|ShapePath|MultiEffect)\b	drawing belongs in a skin
"#[0-9a-fA-F]{3,8}"	use a palette role
^\s*Rectangle \{	drawing belongs in a skin (Divider, Marker, …)
Easing\.(OutBack|InBack)	use Theme.motion
font\.letterSpacing	use StyledText's tracking
text:.*toUpperCase\(\)	use StyledText's caps (or Theme.caps)
EOF
)
while IFS=$'\t' read -r pattern why; do
    # StyledText implements tracking and glow; it's the one allowed place.
    hits=$(grep -rnE "$pattern" components modules --include='*.qml' | grep -v '^components/StyledText.qml:' | grep -vE '^[^:]+:[0-9]+:\s*//')
    if [[ -n "$hits" ]]; then
        echo "$hits" | sed "s|\$|    <- $why|"
        status=1
    fi
done <<< "$rules"

[[ $status -eq 0 ]] && echo "themes ok: $(ls themes/*/Spec.qml | wc -l) themes, $(echo "$skins" | wc -l) skins each"
exit $status
