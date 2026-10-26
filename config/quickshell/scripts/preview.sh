#!/usr/bin/env bash
# Run the shell headless and screenshot it: a headless sway, the shell from
# this checkout with throwaway settings, then grim. For checking how a theme
# looks without a desktop (scripts/dev-env.sh installs what it needs).
#
#     scripts/preview.sh [-t THEME] [-o OUT.png] [-w SECONDS] [-s WxH] [IPC …]
#
# Each IPC argument is one `qs ipc call` line, run in order before the shot,
# e.g.  scripts/preview.sh -t oneshot "panel open launcher"
# The shell's log is left next to the picture (OUT.log).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
theme=oneshot
out="$PWD/preview.png"
wait=4
size=1920x1080
while getopts "t:o:w:s:" opt; do
    case $opt in
        t) theme=$OPTARG ;;
        o) out=$(realpath -m "$OPTARG") ;;
        w) wait=$OPTARG ;;
        s) size=$OPTARG ;;
        *) exit 2 ;;
    esac
done
shift $((OPTIND - 1))

tmp=$(mktemp -d)
export XDG_RUNTIME_DIR=$tmp/run XDG_STATE_HOME=$tmp/state HOME=${HOME:-$tmp}
mkdir -p "$XDG_RUNTIME_DIR" "$XDG_STATE_HOME/quickshell"
chmod 700 "$XDG_RUNTIME_DIR"
printf '{ "theme": "%s", "screen": "" }\n' "$theme" >"$XDG_STATE_HOME/quickshell/settings.json"

cat >"$tmp/sway.conf" <<EOF
output HEADLESS-1 resolution $size
default_border pixel 2
gaps inner 8
EOF

pids=()
cleanup() {
    for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
    wait 2>/dev/null || true
    rm -rf "$tmp"
}
trap cleanup EXIT

WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 \
    sway -c "$tmp/sway.conf" >"$tmp/sway.log" 2>&1 &
pids+=($!)
for _ in $(seq 50); do
    sock=$(ls "$XDG_RUNTIME_DIR" 2>/dev/null | grep -m1 '^wayland-[0-9]*$' || true)
    [[ -n $sock ]] && break
    sleep 0.1
done
[[ -n ${sock:-} ]] || { cat "$tmp/sway.log"; echo "sway didn't start"; exit 1; }
export WAYLAND_DISPLAY=$sock QT_QPA_PLATFORM=wayland
export SWAYSOCK=$(ls "$XDG_RUNTIME_DIR"/sway-ipc.*.sock 2>/dev/null | head -1)

qs -p "$root/shell.qml" >"${out%.png}.log" 2>&1 &
pids+=($!)
sleep "$wait"
for call in "$@"; do
    # shellcheck disable=SC2086
    qs ipc -p "$root/shell.qml" call $call || true
    sleep 1
done
grim "$out"
echo "$out"
