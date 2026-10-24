#!/usr/bin/env bash
# Montre un document markdown à l'humain dans le navigateur du pane de droite (terminal-browser), mis en page en thème
# sombre Nord (nord.css, à côté). Le texte reste dans une page locale : seuls marked et highlight.js viennent du CDN,
# versions figées.
#   lire.sh fichier.md ["Titre"]
# Les « #123 » deviennent des liens vers les issues du dépôt git du fichier, sinon du dossier courant (GitLab ou GitHub,
# lu sur `origin`), ou vers LIRE_ISSUES (préfixe d'URL) s'il est défini.
# Les blocs mermaid se rendent en schémas (mermaid, CDN, versions figées). Les titres portent leurs ancres à la GitLab.
# Les liens relatifs se résolvent contre LIRE_BASE (préfixe d'URL, « .md » retiré, pour pointer vers un wiki), sinon
# contre le dossier du fichier.
set -euo pipefail
[ $# -ge 1 ] || { sed -n '5p' "$0" >&2; exit 2; }
[ -f "$1" ] || { echo "✗ fichier introuvable : $1" >&2; exit 4; }
command -v terminal-browser > /dev/null || { echo "✗ terminal-browser absent du PATH" >&2; exit 3; }

esc() { local s=${1//&/&amp;}; s=${s//</&lt;}; s=${s//\"/&quot;}; printf '%s' "${s//>/&gt;}"; }
issues_base() {
    local r
    r=$(git -C "$(dirname "$1")" remote get-url origin 2> /dev/null || git remote get-url origin 2> /dev/null) || return 0
    case $r in git@*) r=${r#git@}; r=https://${r/://} ;; esac
    r=${r%.git}
    case $r in https://github.com/*) echo "$r/issues/" ;; https://*) echo "$r/-/issues/" ;; esac
}
titre=${2:-$(basename "$1" .md)}
issues=${LIRE_ISSUES:-$(issues_base "$1")}
base=${LIRE_BASE:-file://$(cd "$(dirname "$1")" && pwd)/}
dir=/tmp/claude-$(id -u)/montrer
mkdir -p "$dir"
page=$dir/$(date +%Y%m%d-%H%M%S)-$$-lire.html
{
    printf '<!doctype html><html lang="fr"><meta charset="utf-8"><title>%s</title>\n' "$(esc "$titre")"
    printf '<meta name="viewport" content="width=device-width, initial-scale=1">\n<style>\n'
    cat "$(dirname "$0")/nord.css"
    printf '</style>\n'
    printf '<article class="markdown-body" id="out"></article>\n<script type="text/markdown" id="md">\n'
    sed 's#</#<\\/#g' "$1"
    printf '</script>\n<script src="https://cdn.jsdelivr.net/npm/marked@12.0.2/marked.min.js"></script>\n'
    printf '<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>\n'
    printf '<script>const ISSUES = "%s", BASE = "%s";\n' "$(esc "$issues")" "$(esc "$base")"
    cat << 'JS'
out.innerHTML = marked.parse(md.textContent.replace(/<\\\//g, "</"));
// Ancres à la GitLab : minuscules, ponctuation retirée, espaces en tirets, tirets consécutifs réduits, doublons -1, -2.
const ids = {};
for (const h of out.querySelectorAll("h1,h2,h3,h4,h5,h6")) {
    const id = h.textContent.toLowerCase().replace(/[^\p{L}\p{M}\p{N}_\- ]/gu, "").replace(/ /g, "-").replace(/-+/g, "-");
    h.id = id in ids ? `${id}-${++ids[id]}` : ((ids[id] = 0), id);
}
for (const a of out.querySelectorAll("a[href]")) {
    const href = a.getAttribute("href");
    if (!/^([a-z]+:|#)/i.test(href)) a.href = new URL(href.replace(/\.md(?=#|$)/, ""), BASE).href;
}
if (ISSUES) {
    const walk = document.createTreeWalker(out, NodeFilter.SHOW_TEXT), hits = [];
    while (walk.nextNode()) {
        const t = walk.currentNode;
        if (/#\d/.test(t.data) && !t.parentElement.closest("a,code,pre")) hits.push(t);
    }
    for (const t of hits) {
        const box = document.createElement("span");
        box.innerHTML = t.data.replace(/[&<>]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" })[c])
            .replace(/(^|[^\w&])#(\d{1,6})\b/g, `$1<a href="${ISSUES}$2" target="_blank">#$2</a>`);
        t.replaceWith(...box.childNodes);
    }
}
for (const t of out.querySelectorAll("table")) {
    const wrap = document.createElement("div");
    wrap.className = "table-wrap";
    t.replaceWith(wrap);
    wrap.append(t);
}
for (const c of out.querySelectorAll("pre code.language-mermaid")) {
    const pre = document.createElement("pre");
    pre.className = "mermaid";
    pre.textContent = c.textContent;
    c.parentElement.replaceWith(pre);
}
if (out.querySelector("pre.mermaid")) {
    const s = document.createElement("script");
    s.src = "https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js";
    s.onload = () => {
        mermaid.initialize({ startOnLoad: false, theme: "dark", maxTextSize: 100000, flowchart: { useMaxWidth: false } });
        mermaid.run();
    };
    document.head.append(s);
}
if (window.hljs) for (const c of out.querySelectorAll('pre code[class*="language-"]')) hljs.highlightElement(c);
</script>
JS
} > "$page"
terminal-browser open "$page" --split right > /dev/null
echo "montré : $page"
