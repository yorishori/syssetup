#!/usr/bin/env bash
# Build assets/symbols.tsv from upstream data (needs curl and awk).
#
# Each line: category <TAB> symbol <TAB> name <TAB> keywords
# Categories and sources:
#   emoji    Unicode emoji-test.txt (names) + CLDR annotations (keywords)
#   nerd     nerd-fonts glyphnames.json
#   symbol   Unicode UnicodeData.txt, limited to the blocks below
#   kaomoji  assets/kaomoji.json, a local copy of codingstark-dev's gist; edit
#            it freely, or redownload it with:
#     curl -fsSL -o assets/kaomoji.json https://gist.githubusercontent.com/codingstark-dev/f0e254ba09e8f4fb7d72f4b13160f002/raw/kaomoji.json
#
# Run again to refresh the data:
#     scripts/gen-symbols.sh
set -euo pipefail

assets="$(cd "$(dirname "$0")/.." && pwd)/assets"
dest="$assets/symbols.tsv"
tmp=$(mktemp -d)
# Built next to symbols.tsv so the final mv is an atomic rename: the shell
# watches the file and must never see it half written.
out=$(mktemp "$assets/.symbols.XXXXXX")
trap 'rm -rf "$tmp" "$out"' EXIT

fetch() {
    curl -fsSL --retry 2 -o "$tmp/$1" "$2" || { echo "failed to download $2" >&2; exit 1; }
}
fetch emoji-test.txt  https://unicode.org/Public/emoji/latest/emoji-test.txt
fetch annotations.xml https://raw.githubusercontent.com/unicode-org/cldr/main/common/annotations/en.xml
fetch glyphnames.json https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json
fetch UnicodeData.txt https://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt
fetch Blocks.txt      https://www.unicode.org/Public/UCD/latest/ucd/Blocks.txt

# Symbol blocks worth browsing (skip scripts/alphabets of other languages),
# in output order, as named in Blocks.txt.
blocks="Arrows;Supplemental Arrows-A;Supplemental Arrows-B;Supplemental Arrows-C;\
Mathematical Operators;Supplemental Mathematical Operators;Letterlike Symbols;\
Number Forms;Superscripts and Subscripts;Currency Symbols;General Punctuation;\
Latin-1 Supplement;Greek and Coptic;Box Drawing;Block Elements;Geometric Shapes;\
Geometric Shapes Extended;Miscellaneous Symbols;Miscellaneous Technical;Dingbats;\
Enclosed Alphanumerics;Control Pictures;Braille Patterns;Musical Symbols;\
Playing Cards;Chess Symbols"

# Byte-wise so any awk can build UTF-8 and match the variation selector.
export LC_ALL=C

# ── Emoji ────────────────────────────────────────────────────────────────────
# Fully-qualified, without skin tones or components. CLDR keys its keywords
# by the emoji without U+FE0F.
awk '
    FNR == NR {
        if (match($0, /<annotation cp="[^"]*">/) && $0 !~ /type="tts"/) {
            cp = substr($0, RSTART + 16, RLENGTH - 18)
            kw = substr($0, RSTART + RLENGTH)
            sub(/<\/annotation>.*/, "", kw)
            gsub(/ \| /, ", ", kw)
            keywords[cp] = kw
        }
        next
    }
    /^# group: / { group = substr($0, 10); next }
    /^#/ || group == "Component" || !/; fully-qualified/ { next }
    /1F3F[B-F]/ { next }
    {
        split(substr($0, index($0, "# ") + 2), f, " ")
        ch = f[1]
        name = substr($0, index($0, "# ") + 2 + length(f[1]) + 1 + length(f[2]) + 1)
        key = ch
        gsub(/\357\270\217/, "", key)
        printf "emoji\t%s\t%s\t%s\n", ch, name, keywords[key]
    }
' "$tmp/annotations.xml" "$tmp/emoji-test.txt" > "$out"

# ── Nerd Font glyphs ─────────────────────────────────────────────────────────
# One line of JSON: {"METADATA":{…},"cod-account":{"char":"…","code":"eb99"},…}
grep -o '"[^"]*":{"char":"[^"]*","code":"[^"]*"}' "$tmp/glyphnames.json" |
    awk -F'"' '{ printf "nerd\t%s\t%s\t\n", $6, $2 }' >> "$out"

# ── Symbols ──────────────────────────────────────────────────────────────────
# Names Title Cased ("Leftwards Arrow With Hook", "N-Ary Product").
awk -v blocks="$blocks" '
    function hex(s,    i, n) {
        n = 0
        for (i = 1; i <= length(s); i++)
            n = n * 16 + index("0123456789ABCDEF", substr(s, i, 1)) - 1
        return n
    }
    function utf8(n) {
        if (n < 128) return sprintf("%c", n)
        if (n < 2048) return sprintf("%c%c", 192 + int(n / 64), 128 + n % 64)
        if (n < 65536) return sprintf("%c%c%c", 224 + int(n / 4096), 128 + int(n / 64) % 64, 128 + n % 64)
        return sprintf("%c%c%c%c", 240 + int(n / 262144), 128 + int(n / 4096) % 64, 128 + int(n / 64) % 64, 128 + n % 64)
    }
    function title(s,    out, i, c, up) {
        s = tolower(s); out = ""; up = 1
        for (i = 1; i <= length(s); i++) {
            c = substr(s, i, 1)
            out = out (up ? toupper(c) : c)
            up = c == " " || c == "-"
        }
        return out
    }
    BEGIN {
        n = split(blocks, want, ";")
        for (i = 1; i <= n; i++) order[want[i]] = i
    }
    # Blocks.txt: "2190..21FF; Arrows"
    FNR == NR {
        if (/^[0-9A-F]+\.\.[0-9A-F]+; /) {
            name = substr($0, index($0, "; ") + 2)
            if (name in order) {
                split(substr($0, 1, index($0, ";") - 1), r, ".")
                b++; lo[b] = hex(r[1]); hi[b] = hex(r[3]); idx[b] = order[name]
            }
        }
        next
    }
    # UnicodeData.txt: "2190;LEFTWARDS ARROW;Sm;…"; "<control>" and ranges skipped
    {
        split($0, f, ";")
        if (substr(f[2], 1, 1) == "<")
            next
        cp = hex(f[1])
        for (i = 1; i <= b; i++)
            if (cp >= lo[i] && cp <= hi[i]) {
                k = idx[i]
                rows[k] = rows[k] sprintf("symbol\t%s\t%s\t\n", utf8(cp), title(f[2]))
                break
            }
    }
    END {
        for (i = 1; i <= n; i++)
            printf "%s", rows[i]
    }
' "$tmp/Blocks.txt" "$tmp/UnicodeData.txt" >> "$out"

# ── Kaomoji ──────────────────────────────────────────────────────────────────
# kaomoji.json, pretty-printed: { "group": { "category": [ "face", … ] } }.
# A face in several categories is listed once, named after the first
# ("flip-table" -> "flip table") and keyworded with the rest and its group.
# Multi-line art is skipped.
awk '
    function hex(s,    i, n) {
        s = toupper(s); n = 0
        for (i = 1; i <= length(s); i++)
            n = n * 16 + index("0123456789ABCDEF", substr(s, i, 1)) - 1
        return n
    }
    function utf8(n) {
        if (n < 128) return sprintf("%c", n)
        if (n < 2048) return sprintf("%c%c", 192 + int(n / 64), 128 + n % 64)
        return sprintf("%c%c%c", 224 + int(n / 4096), 128 + int(n / 64) % 64, 128 + n % 64)
    }
    # JSON string body -> text; "" for multi-line art.
    function unescape(s,    out, c, n) {
        out = ""
        while ((n = index(s, "\\")) > 0) {
            out = out substr(s, 1, n - 1)
            c = substr(s, n + 1, 1)
            if (c == "n")
                return ""
            if (c == "u") {
                n += 4  # control characters are dropped
                if (hex(substr(s, n - 2, 4)) >= 32)
                    out = out utf8(hex(substr(s, n - 2, 4)))
            } else
                out = out (c == "t" ? " " : c)
            s = substr(s, n + 2)
        }
        out = out s
        gsub(/^[ \t]+|[ \t]+$/, "", out)
        return out
    }
    function add(face, word) {
        if (index(", " kw[face] ", ", ", " word ", ") == 0)
            kw[face] = (kw[face] == "" ? "" : kw[face] ", ") word
    }
    /": \{$/ { split($0, f, "\""); group = f[2]; next }
    /": \[$/ { split($0, f, "\""); cat = f[2]; gsub(/-/, " ", cat); next }
    /^ *"/ {
        face = $0
        sub(/^ *"/, "", face); sub(/",?$/, "", face)
        face = unescape(face)
        if (face == "")
            next
        if (!(face in name)) {
            order[++n] = face; name[face] = cat
        } else if (name[face] != cat)
            add(face, cat)
        if (group != "")
            add(face, group)
    }
    END {
        for (i = 1; i <= n; i++)
            printf "kaomoji\t%s\t%s\t%s\n", order[i], name[order[i]], kw[order[i]]
    }
' "$assets/kaomoji.json" >> "$out"

chmod 644 "$out"
mv "$out" "$dest"
echo "wrote $(wc -l < "$dest") symbols to assets/symbols.tsv: $(cut -f1 "$dest" | uniq -c | awk '{ printf "%s%s %s", sep, $2, $1; sep = ", " }')"
