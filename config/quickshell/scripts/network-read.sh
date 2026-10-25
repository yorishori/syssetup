#!/bin/sh
# Prints "objects <json>" (iwd's objects), "ordered <json>" (the first
# station's networks, best first) and "links <json>" (networkd's links), each
# only if its daemon answers.
o=$(busctl --system --json=short call net.connman.iwd / org.freedesktop.DBus.ObjectManager GetManagedObjects 2>/dev/null) \
    && echo "objects $o"
for p in $(busctl --system tree --list net.connman.iwd 2>/dev/null | grep -E '^/net/connman/iwd/[0-9]+/[0-9]+$'); do
    r=$(busctl --system --json=short call net.connman.iwd "$p" net.connman.iwd.Station GetOrderedNetworks 2>/dev/null) \
        && echo "ordered $r" && break
done
l=$(networkctl --json=short list 2>/dev/null) && echo "links $l"
true
