#!/bin/sh
# Undoes clipboard-swap.sh: the previous clipboard back (if it was empty, it's
# left empty), and TEXT out of the history again (exact match only).
#   clipboard-restore.sh DIR TEXT
d="$1"
if [ -f "$d/saved" ]; then wl-copy --type "$(cat "$d/type")" < "$d/saved"; else wl-copy --clear; fi
rm -f "$d/saved" "$d/type"
sleep 0.3
cliphist list | awk -F '\t' -v t="$2" '$2 == t { print; exit }' | cliphist delete
