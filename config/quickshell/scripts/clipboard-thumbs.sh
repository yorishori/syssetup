#!/bin/sh
# Decodes image entries to files, once each, and prints the ids it has.
#   clipboard-thumbs.sh DIR ID…
dir="$1"; shift
mkdir -p "$dir" && chmod 700 "$dir"
for id in "$@"; do
    f="$dir/$id"
    [ -s "$f" ] || printf "%s\t" "$id" | cliphist decode > "$f" 2>/dev/null
    [ -s "$f" ] && echo "$id"
done
