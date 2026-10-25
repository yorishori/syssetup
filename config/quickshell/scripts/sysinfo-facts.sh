#!/bin/sh
# Facts that don't change while running: "os", "kernel", "cpu", "gpu" and
# "board" lines, and "reboot" if the running kernel's modules are gone (it was
# upgraded).
# shellcheck disable=SC1091
. /etc/os-release 2>/dev/null; echo "os $PRETTY_NAME"
echo "kernel $(uname -r)"
[ -d "/usr/lib/modules/$(uname -r)" ] || echo "reboot"
echo "cpu $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/ with .*//')"
if command -v nvidia-smi >/dev/null; then
    echo "gpu $(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)"
else
    echo "gpu $(lspci -mm 2>/dev/null | grep -m1 -E '"(VGA|3D|Display)' | awk -F'"' '{print $6}')"
fi
echo "board $(cut -d' ' -f1 /sys/class/dmi/id/board_vendor 2>/dev/null) $(cat /sys/class/dmi/id/board_name 2>/dev/null)"
