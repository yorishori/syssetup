#!/bin/sh
# Puts TEXT on the clipboard, saving what was there to DIR first, for
# clipboard-restore.sh to put back.
#   clipboard-swap.sh DIR TEXT
d="$1"; mkdir -p "$d" && chmod 700 "$d"
t=$(wl-paste --list-types 2>/dev/null | head -1)
if [ -n "$t" ]; then
    wl-paste --no-newline --type "$t" > "$d/saved" 2>/dev/null
    printf "%s" "$t" > "$d/type"
else
    rm -f "$d/saved" "$d/type"
fi
printf "%s" "$2" | wl-copy
