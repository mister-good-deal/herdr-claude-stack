#!/usr/bin/env bash
# Montre une carte à zoom sémantique dans le navigateur du pane de droite (terminal-browser) : une bulle par fichier
# markdown du dossier, index.md pour la racine. Chaque étage tient dans un écran ; un clic zoome dans une bulle.
#   carte.sh <dossier> ["Titre"]
# Une bulle : « # Titre », un premier paragraphe (le résumé, vu sur la tuile), le corps (vu quand on zoome), puis une
# dernière ligne « enfants: a b c » (ids = noms de fichiers sans .md, 7 au plus). Thème Nord de ../lire/nord.css.
set -euo pipefail
[ $# -ge 1 ] || { sed -n '4p' "$0" >&2; exit 2; }
[ -f "$1/index.md" ] || { echo "✗ pas de index.md dans : $1" >&2; exit 4; }
command -v terminal-browser > /dev/null || { echo "✗ terminal-browser absent du PATH" >&2; exit 3; }

esc() { local s=${1//&/&amp;}; s=${s//</&lt;}; s=${s//\"/&quot;}; printf '%s' "${s//>/&gt;}"; }
for f in "$1"/*.md; do
    read -ra kids <<< "$(sed -n 's/^enfants:[[:space:]]*//p' "$f" | tail -1 | tr -d '\r')"
    [ ${#kids[@]} -le 7 ] || { echo "✗ $(basename "$f") : ${#kids[@]} enfants, 7 au plus" >&2; exit 5; }
    for k in "${kids[@]}"; do
        [[ $k != */* && -f $1/$k.md ]] || { echo "✗ $(basename "$f") : enfant introuvable : $k.md" >&2; exit 5; }
    done
done
titre=${2:-$(basename "$(cd "$1" && pwd)")}
dir=/tmp/claude-$(id -u)/montrer
mkdir -p "$dir"
page=$dir/$(date +%Y%m%d-%H%M%S)-$$-carte.html
{
    printf '<!doctype html><html lang="fr"><meta charset="utf-8"><title>%s</title>\n' "$(esc "$titre")"
    printf '<meta name="viewport" content="width=device-width, initial-scale=1">\n<style>\n'
    cat "$(dirname "$0")/../lire/nord.css"
    cat << 'CSS'
html, body { height: 100%; overflow: hidden; }
#stage, #back { position: fixed; inset: 0; transform-origin: 0 0; }
#back { filter: blur(3px) brightness(.6); }
#stage { box-sizing: border-box; display: flex; flex-direction: column; gap: 14px; padding: 14px 18px; }
.anim { transition: transform .7s cubic-bezier(.2, .8, .2, 1), opacity .7s, filter .7s; }
@media (prefers-reduced-motion: reduce) { .anim { transition: none; } }
nav { display: flex; gap: 6px; align-items: center; font-size: 14px; color: var(--muted); flex: none; }
nav a { color: var(--nord8); cursor: pointer; text-decoration: none; }
nav a:hover { text-decoration: underline; }
nav .count { margin-left: auto; color: var(--nord14); }
nav .count.ko { color: var(--red-text); font-weight: 700; }
.frame.markdown-body { position: relative; max-width: none; margin: 0; padding: 18px 22px; overflow: hidden;
  border: 1px solid var(--line); border-radius: 10px; background: var(--surface);
  font-size: 15.5px; line-height: 1.55; }
.frame.markdown-body h1 { font-size: 1.6em; margin-bottom: .6em; }
.frame.markdown-body h2 { font-size: 1.15em; margin: 0 0 .5em; padding: 0; border: 0; }
.frame.markdown-body pre { overflow: hidden; font-size: 13px; line-height: 1.4; padding: 10px 12px;
  white-space: pre-wrap; overflow-wrap: anywhere; }
.focus { flex: 0 1 auto; min-height: 0; }
.focus.leaf { flex: 1 1 auto; }
.tiles { flex: 1 1 0; min-height: 0; display: grid; gap: 14px; grid-template-columns: repeat(var(--cols), 1fr);
  grid-auto-rows: 1fr; }
.tile { cursor: zoom-in; font-size: 14.5px; transition: border-color .15s; }
.tile:hover, .tile:focus { outline: none; border-color: var(--nord8); }
.tile .n { position: absolute; top: 8px; right: 12px; font: 12px var(--font-code); color: var(--muted); }
.tile .more { position: absolute; bottom: 8px; right: 12px; font-size: 12px; color: var(--nord9); }
.frame.over { border-color: var(--nord11); box-shadow: inset 0 0 0 1px var(--nord11); }
.frame.over::after { content: attr(data-over); position: absolute; bottom: 6px; left: 50%; translate: -50%;
  padding: 2px 10px; border-radius: 6px; background: var(--nord11); color: var(--nord6);
  font: 700 13px var(--font-text); }
CSS
    printf '</style>\n<base target="_blank">\n<div id="back" inert></div><div id="stage"></div>\n'
    for f in "$1"/*.md; do
        printf '<script type="text/markdown" data-id="%s">\n' "$(esc "$(basename "$f" .md)")"
        sed 's#</#<\\/#g;s#<!--#<\\!--#g' "$f"
        printf '</script>\n'
    done
    printf '<script src="https://cdn.jsdelivr.net/npm/marked@12.0.2/marked.min.js"></script>\n'
    printf '<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>\n'
    cat << 'JS'
<script>
const B = Object.create(null);
marked.use({ renderer: { html: h => h.replace(/</g, "&lt;") } });
for (const s of document.querySelectorAll("script[data-id]")) {
    const lines = s.textContent.replace(/<\\\//g, "</").replace(/<\\!--/g, "<!--").trim().split("\n");
    const kids = (lines.findLast(l => l.startsWith("enfants:")) ?? "enfants:").slice(8).trim()
        .split(/\s+/).filter(Boolean);
    const rest = lines.filter(l => !l.startsWith("enfants:"));
    const t = rest.findIndex(l => l.startsWith("# "));
    const titre = marked.parseInline(t < 0 ? s.dataset.id : rest.splice(t, 1)[0].slice(2));
    const [resume, ...corps] = rest.join("\n").trim().split(/\n\s*\n/);
    B[s.dataset.id] = { titre, resume: resume ?? "", corps: corps.join("\n\n"), kids };
}
const md = s => marked.parse(s);
// Le hash ne garde qu'une descente réelle depuis index : un id inconnu ou hors de son parent coupe le chemin.
function path() {
    let h = "";
    try { h = decodeURIComponent(location.hash.slice(1)); } catch {}
    const [root, ...ids] = h.split("/"), p = ["index"];
    if (root === "index") for (const id of ids) { if (!B[p.at(-1)].kids.includes(id)) break; p.push(id); }
    return p;
}
let shown = [], cols = 1;

function paint(el, p) {
    const b = B[p.at(-1)], leaf = !b.kids.length;
    const n = b.kids.length, cols = n <= 3 ? n : n === 4 ? 2 : n <= 6 ? 3 : 4;
    const crumbs = p.map((id, i) => i === p.length - 1 ? `<span>${B[id].titre}</span>`
        : `<a data-to="${p.slice(0, i + 1).join("/")}">${B[id].titre}</a> ›`).join(" ");
    const tile = (k, i) => `<article class="frame tile markdown-body" tabindex="0" data-k="${k}">
        <span class="n">${i + 1}</span><h2>${B[k].titre}</h2>${md(B[k].resume)}
        ${B[k].kids.length ? `<span class="more">${B[k].kids.length} ⊕</span>` : ""}</article>`;
    el.innerHTML = `<nav>${crumbs}<span class="count"></span></nav>
        <section class="frame focus markdown-body${leaf ? " leaf" : ""}">
        <h1>${b.titre}</h1>${md(b.resume)}${md(b.corps)}</section>
        ${leaf ? "" : `<div class="tiles" style="--cols:${cols}">${b.kids.map(tile).join("")}</div>`}`;
    if (window.hljs) for (const c of el.querySelectorAll('pre code[class*="language-"]:not(.language-mermaid)'))
        hljs.highlightElement(c);
    return cols;
}
function render() {
    const p = path();
    cols = paint(stage, p);
    for (const c of stage.querySelectorAll("pre code.language-mermaid")) {
        const pre = document.createElement("pre");
        pre.className = "mermaid";
        pre.textContent = c.textContent;
        c.parentElement.replaceWith(pre);
    }
    if (stage.querySelector("pre.mermaid")) mermaidRun();
    check();
    return p;
}
// Comme Zumly : la vue parente reste derrière, floutée, cadrée sur la tuile d'où l'on vient.
function backdrop(p) {
    back.classList.remove("anim");
    back.style.transform = "";
    if (p.length < 2) return (back.innerHTML = "", "");
    paint(back, p.slice(0, -1));
    const q = back.querySelector(`.tile[data-k="${CSS.escape(p.at(-1))}"]`).getBoundingClientRect();
    const s = innerWidth / q.width;
    return `translate(${innerWidth / 2}px, ${innerHeight / 2}px) scale(${s}) `
        + `translate(${-(q.left + q.width / 2)}px, ${-(q.top + q.height / 2)}px)`;
}
function animate(el, from, to) {
    el.classList.remove("anim");
    Object.assign(el.style, from);
    el.offsetWidth;
    el.classList.add("anim");
    Object.assign(el.style, to);
}
// La règle de l'écran : un cadre qui déborde se marque en rouge, avec son débordement. Jamais de scroll.
function check() {
    let ko = 0;
    for (const f of stage.querySelectorAll(".frame")) {
        const h = f.scrollHeight - f.clientHeight, w = f.scrollWidth - f.clientWidth;
        f.classList.toggle("over", h > 1 || w > 1);
        if (h > 1 || w > 1) ko++;
        f.dataset.over = [h > 1 && `+${h} px ↓`, w > 1 && `+${w} px →`].filter(Boolean).join(" · ");
    }
    const c = stage.querySelector(".count");
    c.textContent = ko ? `✗ ${ko} cadre${ko > 1 ? "s" : ""} déborde${ko > 1 ? "nt" : ""}` : "✓ tout tient";
    c.classList.toggle("ko", ko > 0);
}
let mermaidLoad;
function mermaidRun() {
    mermaidLoad ??= new Promise((ok, ko) => {
        const s = document.createElement("script");
        s.src = "https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js";
        s.onload = ok;
        s.onerror = ko;
        document.head.append(s);
    }).then(() => mermaid.initialize({ startOnLoad: false, theme: "dark" }));
    mermaidLoad.then(() => mermaid.run({ nodes: stage.querySelectorAll("pre.mermaid") })).then(check, () => {});
}
// Zoom : la nouvelle vue part du cadre de la tuile (entrée) ou y retourne (sortie), puis se pose à l'écran.
function go() {
    const before = shown, after = path();
    const into = after.length === before.length + 1 && before.every((id, i) => id === after[i]);
    const out = before.length === after.length + 1 && after.every((id, i) => id === before[i]);
    const side = before.length === after.length && after.length > 1
        && before.slice(0, -1).join("/") === after.slice(0, -1).join("/") && before.at(-1) !== after.at(-1);
    stage.classList.remove("anim");
    stage.style.transform = "";
    const r = into && stage.querySelector(`.tile[data-k="${CSS.escape(after.at(-1))}"]`)?.getBoundingClientRect();
    shown = render();
    const W = innerWidth, H = innerHeight, kids = B[after.at(-2)]?.kids ?? [];
    const behind = backdrop(after);
    let from = "";
    if (r) from = `translate(${r.left}px, ${r.top}px) scale(${r.width / W}, ${r.height / H})`;
    const t = out && stage.querySelector(`.tile[data-k="${CSS.escape(before.at(-1))}"]`);
    if (t) {
        const q = t.getBoundingClientRect();
        from = `scale(${W / q.width}, ${H / q.height}) translate(${-q.left}px, ${-q.top}px)`;
    }
    if (side) from = `translateX(${Math.sign(kids.indexOf(after.at(-1)) - kids.indexOf(before.at(-1))) * W / 3}px)`;
    if (from) animate(stage, { transform: from, opacity: 0.2 }, { transform: "", opacity: 1 });
    if (r) animate(back, { transform: "", filter: "none", opacity: 1 }, { transform: behind, filter: "", opacity: 1 });
    else if (from) animate(back, { transform: behind, opacity: 0 }, { transform: behind, opacity: 1 });
    else back.style.transform = behind;
    (t || stage.querySelector(".tile"))?.focus();
}
const zoom = k => (location.hash = [...shown, k].join("/"));
const up = () => shown.length > 1 && (location.hash = shown.slice(0, -1).join("/"));
stage.addEventListener("click", e => {
    const a = e.target.closest("a[data-to]"), t = e.target.closest(".tile");
    if (a) location.hash = a.dataset.to;
    else if (t && !e.target.closest("a[href]")) zoom(t.dataset.k);
    else if (e.target === stage || e.target.classList.contains("tiles")) up();
});
const sibling = d => { const k = B[shown.at(-2)]?.kids ?? [], j = k.indexOf(shown.at(-1)) + d;
    if (k[j]) location.hash = [...shown.slice(0, -1), k[j]].join("/"); };
addEventListener("keydown", e => {
    if (e.ctrlKey || e.altKey || e.metaKey) return;
    const tiles = [...stage.querySelectorAll(".tile")], i = tiles.indexOf(document.activeElement);
    const move = { ArrowRight: 1, ArrowLeft: -1, ArrowDown: cols, ArrowUp: -cols }[e.key];
    if (e.key === "Escape" || e.key === "Backspace") up();
    else if (e.key === "Enter" && i >= 0) zoom(tiles[i].dataset.k);
    else if (/^[1-7]$/.test(e.key) && tiles[e.key - 1]) zoom(tiles[e.key - 1].dataset.k);
    else if (!tiles.length && Math.abs(move) === 1) sibling(move);
    else if (move && tiles.length) tiles[Math.min(Math.max(i < 0 ? 0 : i + move, 0), tiles.length - 1)].focus();
    else return;
    e.preventDefault();
});
addEventListener("hashchange", go);
addEventListener("resize", () => { back.style.transform = backdrop(shown); check(); });
document.fonts.ready.then(check);
go();
</script>
JS
} > "$page"
terminal-browser open "$page" --split right > /dev/null
echo "montré : $page"
