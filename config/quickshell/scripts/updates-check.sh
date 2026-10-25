#!/bin/sh
# Pending updates, one fact per line:
#   missing          checkupdates isn't installed (nothing else follows)
#   helper <name>    the AUR helper found (yay, paru)
#   code <n>         checkupdates' exit status (2: nothing to update)
#   repo <name>      one per update: the repository it comes from (aur too)
#   last <date>      when the last full upgrade started (pacman.log)
command -v checkupdates >/dev/null || { echo "missing"; exit; }
for h in yay paru; do command -v $h >/dev/null && { echo "helper $h"; break; }; done
out=$(checkupdates 2>/dev/null); code=$?
echo "code $code"
# Which repo each update comes from, using checkupdates' fresh database.
db="${CHECKUPDATES_DB:-${TMPDIR:-/tmp}/checkup-db-$(id -u)/}"
names=$(echo "$out" | awk '{print $1}')
[ -n "$out" ] && NAMES="$names" pacman -Sl --dbpath "$db" 2>/dev/null | NAMES="$names" awk '
    BEGIN { n = split(ENVIRON["NAMES"], a, "\n"); for (i = 1; i <= n; i++) want[a[i]] = 1 }
    ($2 in want) { print "repo " $1 }'
for h in yay paru; do command -v $h >/dev/null && { $h -Qua 2>/dev/null | sed 's/^.*/repo aur/'; break; }; done
grep 'starting full system upgrade' /var/log/pacman.log | tail -1 | cut -c2-25 | sed 's/^/last /'
