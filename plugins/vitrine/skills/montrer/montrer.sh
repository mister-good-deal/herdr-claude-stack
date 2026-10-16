#!/usr/bin/env bash
# Montre des images à Romain dans le navigateur du pane de droite (terminal-browser) : une page, les images côte à côte,
# chacune avec sa légende. Le même navigateur sert à chaque appel, une page = un onglet.
#   montrer.sh [--titre "Titre"] image[=légende] [image[=légende] ...]
set -euo pipefail
titre="Aperçu"
if [ "${1:-}" = --titre ]; then titre=$2; shift 2; fi
[ $# -ge 1 ] || { sed -n '4p' "$0" >&2; exit 2; }
command -v terminal-browser > /dev/null || { echo "✗ terminal-browser absent du PATH" >&2; exit 3; }

esc() { local s=${1//&/&amp;}; s=${s//</&lt;}; s=${s//>/&gt;}; printf '%s' "${s//\"/&quot;}"; }
dir=/tmp/claude-$(id -u)/montrer
mkdir -p "$dir"
page=$dir/$(date +%Y%m%d-%H%M%S)-$$.html
{
    printf '<!doctype html><meta charset="utf-8"><title>%s</title>\n' "$(esc "$titre")"
    printf '<style>body{margin:0;padding:16px;background:#14161a;color:#e8e6e1;font:15px system-ui,sans-serif}'
    printf 'h1{font-size:18px;margin:0 0 12px}main{display:grid;gap:16px;'
    printf 'grid-template-columns:repeat(auto-fit,minmax(320px,1fr))}figure{margin:0}'
    printf 'img{width:100%%;height:auto;border:1px solid #3a3d44;background:#000}'
    printf 'figcaption{margin-top:6px;color:#b9b5ad}</style>\n<h1>%s</h1><main>\n' "$(esc "$titre")"
    for arg in "$@"; do
        img=${arg%%=*}
        legende=$([ "$arg" = "$img" ] && basename "$img" || printf '%s' "${arg#*=}")
        [ -f "$img" ] || { echo "✗ image introuvable : $img" >&2; exit 4; }
        abs=$(realpath "$img")
        printf '<figure><img src="file://%s" alt="%s"><figcaption>%s</figcaption></figure>\n' \
            "$(esc "$abs")" "$(esc "$legende")" "$(esc "$legende")"
    done
    printf '</main>\n'
} > "$page"
terminal-browser open "$page" --split right > /dev/null
echo "montré : $page"
