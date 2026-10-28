#!/bin/bash
# Tree of every installed package, grouped by the categories in .pkgs:
#   Category > listed package > its dependencies (recursive)
# Packages not reached from any list go under "Others".
#   bold = listed   red = listed but not installed   blue = shows up in more than one place
#   "..." = its dependencies are already expanded elsewhere in the tree
# Usage: pkgtree.sh [-a] [-c]
#   -a  plain ASCII tree lines
#   -c  force colors (e.g. ./pkgtree.sh -c | less -R)
set -uo pipefail
set -f

DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
PKGFILE="$DIR/.pkgs"

ASCII=0; COLOR=0
[[ -t 1 ]] && COLOR=1
while getopts ac opt; do
    case $opt in
        a) ASCII=1 ;;
        c) COLOR=1 ;;
        *) echo "usage: ${0##*/} [-a] [-c]"; exit 1 ;;
    esac
done

if (( COLOR )); then
    RS=$'\e[0m' BOLD=$'\e[1m' DIM=$'\e[2m' HEAD=$'\e[1;7m'
    RED=$'\e[1;31m' BLUE=$'\e[1;34m'
    declare -A ORIGIN_C=([core]=$'\e[32m' [extra]=$'\e[36m' [multilib]=$'\e[35m' [yay]=$'\e[33m')
else
    RS= BOLD= DIM= HEAD= RED= BLUE=
    declare -A ORIGIN_C=()
fi

if (( ASCII )); then
    G_TEE='|- ' G_END='`- ' G_BAR='|  '
else
    G_TEE='├─ ' G_END='└─ ' G_BAR='│  '
fi
G_GAP='   '

# --- Load package data ------------------------------------------------------
declare -A VER REPO SYNC PROV DEPS SEEN ROOTED COUNT

while read -r n v; do VER[$n]=$v; done < <(pacman -Q)

# Origin: sync repo of the installed package; anything foreign came from yay
while read -r repo n _ inst; do
    [[ -z ${SYNC[$n]+x} ]] && SYNC[$n]=$repo
    [[ $inst == "[installed"* ]] && REPO[$n]=$repo
done < <(LC_ALL=C pacman -Sl 2>/dev/null)

# Provides and raw dependencies (version constraints stripped)
deplines=()
pkg= field=
while IFS= read -r line; do
    case $line in
        "Name "*)       pkg=${line#*: }; field=; continue ;;
        "Provides "*)   field=prov; line=${line#*: } ;;
        "Depends On "*) field=dep;  line=${line#*: } ;;
        " "*)           [[ -z $field ]] && continue ;;
        *)              field=; continue ;;
    esac
    for w in $line; do
        [[ $w == None ]] && continue
        w=${w%%[<>=]*}
        if [[ $field == prov ]]; then
            [[ -z ${PROV[$w]+x} ]] && PROV[$w]=$pkg
        else
            deplines+=("$pkg $w")
        fi
    done
done < <(LC_ALL=C pacman -Qi)

# Installed package satisfying a name (itself or a provider), empty if none
resolve() {
    REPLY=$1
    [[ -n ${VER[$REPLY]+x} ]] || REPLY=${PROV[$REPLY]:-}
}

# Resolve virtual deps to real packages, then dedupe and sort the children
pairs=()
for e in "${deplines[@]}"; do
    p=${e%% *}
    resolve "${e#* }"
    [[ -n $REPLY && $REPLY != "$p" ]] && pairs+=("$p $REPLY")
done
while read -r p d; do
    [[ -n $p ]] && DEPS[$p]+="$d "
done < <(printf '%s\n' "${pairs[@]}" | sort -u)

# --- Build the tree ---------------------------------------------------------
# Lines are collected first so the number of appearances is known when painting
L_PRE=() L_PKG=() L_KIND=() L_MORE=()

add() { # prefix pkg kind [more]
    L_PRE+=("$1") L_PKG+=("$2") L_KIND+=("$3") L_MORE+=("${4:-}")
    [[ $3 == cat ]] || COUNT[$2]=$(( ${COUNT[$2]:-0} + 1 ))
}

walk() { # pkg prefix
    local deps=(${DEPS[$1]:-}) i d con nxt
    local n=${#deps[@]}
    for (( i = 0; i < n; i++ )); do
        d=${deps[i]}
        if (( i == n - 1 )); then con=$G_END nxt=$G_GAP; else con=$G_TEE nxt=$G_BAR; fi
        if [[ -n ${SEEN[$d]:-} ]]; then
            add "$2$con" "$d" dep "${DEPS[$d]:+1}"
        else
            SEEN[$d]=1
            add "$2$con" "$d" dep
            walk "$d" "$2$nxt"
        fi
    done
}

root() { # pkg kind
    add " " "$1" "$2"
    [[ $2 == missing || -n ${ROOTED[$1]:-} ]] && return
    ROOTED[$1]=1
    walk "$1" " "
}

source "$PKGFILE"
mapfile -t CATS < <(grep -o '^PKGS_[A-Za-z0-9_]*' "$PKGFILE")

# Listed packages are only ever expanded at their own root
for c in "${CATS[@]}"; do
    for p in ${!c}; do
        resolve "$p"
        [[ -n $REPLY ]] && SEEN[$REPLY]=1
    done
done

for c in "${CATS[@]}"; do
    name=${c#PKGS_}
    list=(${!c})
    missing=0
    hdr=${#L_PKG[@]}
    add "" "$name" cat
    for p in "${list[@]}"; do
        resolve "$p"
        if [[ -n $REPLY ]]; then
            root "$REPLY" root
        else
            root "$p" missing
            (( missing++ ))
        fi
    done
    L_MORE[hdr]="${#list[@]} listed"
    (( missing )) && L_MORE[hdr]+=", $missing missing"
done

# Others: explicitly installed first, then whatever is left (orphans and their deps)
hdr=${#L_PKG[@]}
add "" "OTHERS" cat
others=0
for p in $(pacman -Qqe | sort) $(printf '%s\n' "${!VER[@]}" | sort); do
    [[ -n ${SEEN[$p]:-} ]] && continue
    SEEN[$p]=1
    root "$p" root
    (( others++ ))
done
L_MORE[hdr]="$others not from the lists"

# --- Paint ------------------------------------------------------------------
(( COLOR )) && printf '%s listed%s  %s several places%s  %s missing%s  |  %score%s %sextra%s %smultilib%s %syay%s\n' \
    "$BOLD" "$RS" "$BLUE" "$RS" "$RED" "$RS" \
    "${ORIGIN_C[core]:-}" "$RS" "${ORIGIN_C[extra]:-}" "$RS" \
    "${ORIGIN_C[multilib]:-}" "$RS" "${ORIGIN_C[yay]:-}" "$RS"

for (( i = 0; i < ${#L_PKG[@]}; i++ )); do
    p=${L_PKG[i]}
    case ${L_KIND[i]} in
        cat)
            printf '\n%s %s %s %s(%s)%s\n' "$HEAD" "$p" "$RS" "$DIM" "${L_MORE[i]}" "$RS"
            ;;
        missing)
            o=${SYNC[$p]:-}
            printf '%s%s%s%s  %snot installed%s%s\n' "$DIM" "${L_PRE[i]}" "$RS" \
                "$RED$p$RS" "$DIM" "$RS" "${o:+ ${ORIGIN_C[$o]:-}[$o]$RS}"
            ;;
        *)
            o=${REPO[$p]:-yay}
            col=
            [[ ${L_KIND[i]} == root ]] && col=$BOLD
            (( COUNT[$p] > 1 )) && col=$BLUE
            printf '%s%s%s%s%s%s %s%s%s %s[%s]%s%s\n' "$DIM" "${L_PRE[i]}" "$RS" \
                "$col" "$p" "$RS" "$DIM" "${VER[$p]}" "$RS" \
                "${ORIGIN_C[$o]:-}" "$o" "$RS" "${L_MORE[i]:+ $DIM...$RS}"
            ;;
    esac
done
