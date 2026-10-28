#!/bin/bash
# Tree of every installed package, grouped by the categories in .pkgs:
#   Category > listed package > its dependencies (recursive)
# Packages not reached from any list go under "Others".
#   bold = listed   red = listed but not installed   (+N) = packages it brought in
#   blue = already pulled in further up (deps get listed by name, not as a tree)
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
declare -A VER REPO SYNC PROV DEPS SEEN
NSEEN=0

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
# First come, first served: a package is drawn (with its own deps) under the
# first package that needs it. Later on it only shows up by name, in the blue
# comma-separated line under whoever else depends on it.
L_PRE=() L_PKG=() L_KIND=() L_INFO=()

add() { # prefix pkg kind [info]
    L_PRE+=("$1") L_PKG+=("$2") L_KIND+=("$3") L_INFO+=("${4:-}")
}

walk() { # pkg prefix
    local d new=() rep=() i n con nxt
    for d in ${DEPS[$1]:-}; do
        if [[ -n ${SEEN[$d]:-} ]]; then rep+=("$d"); else SEEN[$d]=1; (( ++NSEEN )); new+=("$d"); fi
    done
    n=${#new[@]}
    if (( ${#rep[@]} )); then
        if (( n )); then con=$G_BAR; else con=$G_GAP; fi
        printf -v d '%s, ' "${rep[@]}"
        add "$2$con" "${d%, }" rep
    fi
    for (( i = 0; i < n; i++ )); do
        if (( i == n - 1 )); then con=$G_END nxt=$G_GAP; else con=$G_TEE nxt=$G_BAR; fi
        add "$2$con" "${new[i]}" dep
        walk "${new[i]}" "$2$nxt"
    done
}

root() { # pkg
    local kind=root at before
    if [[ -n ${SEEN[$1]:-} ]]; then kind=seenroot; else SEEN[$1]=1; (( ++NSEEN )); fi
    at=${#L_PKG[@]} before=$NSEEN
    add " " "$1" "$kind"
    walk "$1" " "
    L_INFO[at]=$(( $NSEEN - before ))
}

source "$PKGFILE"
mapfile -t CATS < <(grep -o '^PKGS_[A-Za-z0-9_]*' "$PKGFILE")

for c in "${CATS[@]}"; do
    list=(${!c})
    missing=0 before=$NSEEN hdr=${#L_PKG[@]}
    add "" "${c#PKGS_}" cat
    for p in "${list[@]}"; do
        resolve "$p"
        if [[ -n $REPLY ]]; then
            root "$REPLY"
        else
            add " " "$p" missing
            (( missing++ ))
        fi
    done
    L_INFO[hdr]="${#list[@]} listed"
    (( missing )) && L_INFO[hdr]+=", $missing missing"
    L_INFO[hdr]+=", $(( $NSEEN - before )) pkgs"
done

# Others: explicitly installed first, then whatever is left (orphans and their deps)
hdr=${#L_PKG[@]} before=$NSEEN
add "" "OTHERS" cat
for p in $(pacman -Qqe | sort) $(printf '%s\n' "${!VER[@]}" | sort); do
    [[ -n ${SEEN[$p]:-} ]] || root "$p"
done
L_INFO[hdr]="$(( $NSEEN - before )) pkgs"

# --- Paint ------------------------------------------------------------------
printf '%s%s packages installed%s\n' "$BOLD" "${#VER[@]}" "$RS"
(( COLOR )) && printf '%slisted%s  %salready above%s  %smissing%s  |  %score%s %sextra%s %smultilib%s %syay%s\n' \
    "$BOLD" "$RS" "$BLUE" "$RS" "$RED" "$RS" \
    "${ORIGIN_C[core]:-}" "$RS" "${ORIGIN_C[extra]:-}" "$RS" \
    "${ORIGIN_C[multilib]:-}" "$RS" "${ORIGIN_C[yay]:-}" "$RS"

for (( i = 0; i < ${#L_PKG[@]}; i++ )); do
    p=${L_PKG[i]} pre="$DIM${L_PRE[i]}$RS"
    case ${L_KIND[i]} in
        cat)
            printf '\n%s %s %s %s(%s)%s\n' "$HEAD" "$p" "$RS" "$DIM" "${L_INFO[i]}" "$RS"
            ;;
        missing)
            o=${SYNC[$p]:-}
            printf '%s%s%s%s  %snot installed%s%s\n' "$pre" "$RED" "$p" "$RS" \
                "$DIM" "$RS" "${o:+ ${ORIGIN_C[$o]:-}[$o]$RS}"
            ;;
        rep)
            printf '%s%s%s%s\n' "$pre" "$BLUE" "$p" "$RS"
            ;;
        *)
            o=${REPO[$p]:-yay}
            col= info=
            case ${L_KIND[i]} in
                root)     col=$BOLD ;;
                seenroot) col=$BLUE ;;
            esac
            [[ ${L_KIND[i]} != dep ]] && (( L_INFO[i] )) && info=" $DIM(+${L_INFO[i]})$RS"
            printf '%s%s%s%s %s%s%s %s[%s]%s%s\n' "$pre" "$col" "$p" "$RS" \
                "$DIM" "${VER[$p]}" "$RS" "${ORIGIN_C[$o]:-}" "$o" "$RS" "$info"
            ;;
    esac
done
