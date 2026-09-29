#!/bin/sh
# This wrapper script is invoked by xdg-desktop-portal-termfilechooser.
#
# For more information about input/output arguments read `xdg-desktop-portal-termfilechooser(5)`

set -e

if [ "$6" -ge 4 ]; then
    set -x
fi

multiple="$1"
directory="$2"
save="$3"
path="$4"
out="$5"

args=()

if [ "$save" = "1" ]; then
    # save a file
    touch "$path"
    args+=(--chooser-file="$out" "$path")
elif [ "$directory" = "1" ]; then
    # upload files from a directory
    args+=(--chooser-file="$out" --cwd-file="$out"".1" "$path")
elif [ "$multiple" = "1" ]; then
    # upload multiple files
    args+=(--chooser-file="$out" "$path")
else
    # upload only 1 file
    args+=(--chooser-file="$out" "$path")
fi


kitty --class "nya-yazi-filechoose" --title "Choose File" -e yazi "${args[@]}"
if [ "$directory" = "1" ]; then
    if [ ! -s "$out" ] && [ -s "$out"".1" ]; then
        cat "$out"".1" > "$out"
        rm "$out"".1"
    else
        rm "$out"".1"
    fi
fi


