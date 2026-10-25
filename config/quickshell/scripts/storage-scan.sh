#!/bin/sh
# Drives, USB devices and network shares, one per line:
#   lsblk <lsblk -J on one line>
#   usb <lsusb line>
#   net <TAB> where what type state result automount "size used avail" description
#
# Shares come from systemd units. Only unit state is read, never the path, so
# looking can't trigger an automount; capacity is only asked for when already
# mounted, with a timeout for dead servers.
echo "lsblk $(lsblk -J -b -o PATH,NAME,SIZE,FSUSED,FSAVAIL,MOUNTPOINT,FSTYPE,LABEL,RM,HOTPLUG,TYPE 2>/dev/null | tr -d '\n')"
lsusb 2>/dev/null | sed 's/^/usb /'
seen=""
for unit in $(systemctl list-units --all --plain --no-legend --type=automount,mount | awk '{print $1}'); do
    case "$unit" in *.automount) m="${unit%.automount}.mount" ;; *.mount) m="$unit" ;; esac
    case "$m" in -*) continue ;; esac  # "-.mount" is / (and looks like an option)
    echo "$seen" | grep -qx "$m" && continue
    seen="$seen
$m"
    info=$(systemctl show "$m" -p Type -p Where -p What -p ActiveState -p Result -p Description)
    field() { echo "$info" | sed -n "s/^$1=//p"; }
    type=$(field Type)
    case "$type" in nfs|nfs4|cifs|smb3|fuse.sshfs|davfs|9p) ;; *) continue ;; esac
    where=$(field Where)
    state=$(field ActiveState)
    sizes=""
    [ "$state" = active ] && sizes=$(timeout 2 df -B1 --output=size,used,avail "$where" 2>/dev/null | tail -1)
    auto=$(systemctl is-active "${m%.mount}.automount" 2>/dev/null)
    printf 'net\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$where" "$(field What)" "$type" "$state" \
        "$(field Result)" "$auto" "$sizes" "$(field Description)"
done
