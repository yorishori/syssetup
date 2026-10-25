#!/bin/sh
# Prints "<pid> <command>" of the notification daemon (the owner of
# org.freedesktop.Notifications), or nothing if there is none.
#   notifs-owner.sh [takeover]   takeover: stop dunst first, if it's the owner
owner() {
    pid=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus \
        GetConnectionUnixProcessID s org.freedesktop.Notifications 2>/dev/null | cut -d' ' -f2)
    [ -n "$pid" ] && echo "$pid $(cat "/proc/$pid/comm")"
}
if [ "${1:-}" = takeover ] && owner | grep -q ' dunst$'; then
    pkill -x dunst
    for _ in $(seq 20); do [ -z "$(owner)" ] && break; sleep 0.1; done
fi
owner
