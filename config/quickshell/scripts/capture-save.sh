#!/bin/sh
# Moves a capture to where it's kept; with "copy", also puts it (a PNG) on the
# clipboard. Exits 1 if it couldn't be moved.
#   capture-save.sh TARGET SOURCE [copy]
target="$1"; src="$2"
mkdir -p "$(dirname "$target")" && mv -f "$src" "$target" || exit 1
[ "${3:-}" = copy ] && wl-copy --type image/png < "$target"
exit 0
