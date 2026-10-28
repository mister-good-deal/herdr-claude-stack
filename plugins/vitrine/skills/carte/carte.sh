#!/usr/bin/env bash
# Montre une carte à zoom sémantique dans le navigateur du pane de droite (terminal-browser) : une bulle par fichier
# markdown du dossier, index.md pour la racine. Une bulle à bloc ```carte est un schéma en couloirs ; un clic sur un
# nœud zoome dans la bulle qu'il vise. Une bulle sans schéma est une feuille. Thème Nord de ../lire/nord.css.
#   carte.sh <dossier> ["Titre"]
set -euo pipefail
[ $# -ge 1 ] || { sed -n '5p' "$0" >&2; exit 2; }
[ -f "$1/index.md" ] || { echo "✗ pas de index.md dans : $1" >&2; exit 4; }
command -v terminal-browser > /dev/null || { echo "✗ terminal-browser absent du PATH" >&2; exit 3; }

esc() { local s=${1//&/&amp;}; s=${s//</&lt;}; s=${s//\"/&quot;}; printf '%s' "${s//>/&gt;}"; }
for f in "$1"/*.md; do
    for k in $(sed -n '/^```carte/,/^```$/{/ > /s/.* > //p}' "$f"); do
        [[ $k != */* && -f $1/$k.md ]] || { echo "✗ $(basename "$f") : cible introuvable : $k.md" >&2; exit 5; }
    done
done
k=$(sed -n '/^```carte/,/^```$/{/ > /s/.* > //p}' "$1"/*.md | tr ' ' '\n' | sort | uniq -d | head -1)
[[ -z $k ]] || { echo "✗ cible partagée : $k.md a plusieurs parents, une vue par case" >&2; exit 5; }
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
#stage, #back { position: fixed; inset: 0; transform-origin: 0 0; box-sizing: border-box; display: flex;
  flex-direction: column; gap: 10px; padding: 14px 18px; background: var(--bg); }
#back { filter: blur(3px) brightness(.6); }
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
.frame.markdown-body pre { overflow: hidden; font-size: 13px; line-height: 1.4; padding: 10px 12px;
  white-space: pre-wrap; overflow-wrap: anywhere; }
.frame.head { flex: none; padding: 10px 18px; font-size: 14.5px; }
.frame.head h1 { font-size: 1.25em; margin: 0 0 .25em; padding: 0; border: 0; }
.frame.head p { margin: 0; }
.frame.leaf { flex: 1 1 auto; min-height: 0; }
.schema { flex: 1 1 0; min-height: 0; }
.schema svg { display: block; width: 100%; height: 100%; }
.legende { flex: none; display: flex; gap: 18px; justify-content: center; font-size: 13px; color: var(--muted); }
.legende i { font-style: normal; font-weight: 700; }
.frame.over, .node.over > path { border-color: var(--nord11); stroke: var(--nord11) !important; stroke-width: 3; }
.frame.over { box-shadow: inset 0 0 0 1px var(--nord11); }
.frame.over::after { content: attr(data-over); position: absolute; bottom: 6px; left: 50%; translate: -50%;
  padding: 2px 10px; border-radius: 6px; background: var(--nord11); color: var(--nord6);
  font: 700 13px var(--font-text); }
svg text { fill: var(--text); font: 15px var(--font-text); }
.node > path { fill: var(--surface); stroke: var(--nord3); stroke-width: 2; }
.node .label { font-weight: 700; fill: var(--strong); }
.node .fact { font-size: 13px; fill: var(--muted); }
.s-add > path { stroke: var(--nord14); }
.s-mod > path { stroke: var(--nord13); }
.s-del > path { stroke: var(--nord11); stroke-dasharray: 7 5; }
.link path { stroke: var(--nord9); stroke-width: 1.8; fill: none; }
.link.faible path { stroke-dasharray: 5 5; }
.verbe text { font-size: 13px; font-style: italic; fill: var(--nord8); }
.verbe rect { fill: var(--bg); }
.lane rect { fill: color-mix(in srgb, var(--nord1) 18%, transparent); stroke: var(--line); }
.lane text { fill: var(--muted); font-size: 13px; letter-spacing: .1em; }
.node[data-k] { cursor: zoom-in; outline: none; }
.node[data-k]:hover > path, .node[data-k]:focus > path { stroke-width: 3.5; }
.node.hl > path { stroke: var(--nord8) !important; stroke-width: 4; }
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
const NAT = { __proto__: null, traitement: "▢", stockage: "⛁", fichier: "▯",
    "règle": "⬡", "écran": "▭", valeur: "⬭", entonnoir: "▽" };
const STAT = { __proto__: null, "ajouté": "add", "modifié": "mod", "retiré": "del" };
const TEINTE = [, "--nord8", "--nord15", "--nord7", "--nord10", "--nord12", "--nord4"];
const G = 56, P = 16, T = 34; // gouttière entre couloirs, marge dans un couloir, hauteur de son titre
const B = Object.create(null);
marked.use({ renderer: { html: h => h.replace(/</g, "&lt;") } });
// Un schéma : « couloir clé Titre », « bande clé Titre », des nœuds et des liens « a b -> c verbe » (..> : pointillé).
function parse(src) {
    const S = { lanes: { __proto__: null }, nodes: [], links: [], errs: [], N: { __proto__: null } };
    for (const l of src.split("\n").map(l => l.trim())) {
        if (!l || l.startsWith("//")) continue;
        let m = l.match(/^(couloir|bande)\s+(\S+)\s+(.+)$/);
        if (m) { S.lanes[m[2]] = { band: m[1] === "bande", titre: m[3] }; continue; }
        m = l.match(/^(.+?)\s+(-|\.\.)>\s+(\S+)\s*(.*)$/);
        if (m) {
            for (const f of m[1].split(/\s+/)) S.links.push({ f, t: m[3], verbe: m[4], faible: m[2] === ".." });
            continue;
        }
        const [txt, cible = ""] = l.split(/\s+>\s+/), tok = txt.split(/\s+/);
        const pos = tok[2]?.match(/^(\d+)(?:-(\d+))?$/);
        if (!S.lanes[tok[1]] || !pos || +pos[1] < 1 || +(pos[2] ?? pos[1]) < +pos[1])
            { S.errs.push(`ligne illisible : ${l}`); continue; }
        const n = { id: tok[0], L: S.lanes[tok[1]], r1: +pos[1], r2: +(pos[2] ?? pos[1]), nature: "traitement",
            statut: "", tags: [], kids: cible.split(/\s+/).filter(Boolean) };
        let i = 3;
        for (const t of tok.slice(3)) {
            if (NAT[t]) n.nature = t;
            else if (STAT[t]) n.statut = t;
            else if (/^~[1-6]$/.test(t)) n.teinte = TEINTE[t[1]];
            else if (t[0] === "@") n.tags.push(t.slice(1));
            else break;
            i++;
        }
        [n.label, ...n.fact] = tok.slice(i).join(" ").split(/\s*\|\s*/);
        if (S.N[n.id]) S.errs.push(`nœud en double : ${n.id}`);
        const o = S.nodes.find(m => m.L === n.L && m.r1 <= n.r2 && n.r1 <= m.r2);
        if (o) S.errs.push(`nœuds superposés : ${o.id} et ${n.id}`);
        S.nodes.push(S.N[n.id] = n);
    }
    for (const k of S.links) if (!S.N[k.f] || !S.N[k.t]) S.errs.push(`lien vers un nœud inconnu : ${k.f} -> ${k.t}`);
    return S;
}
for (const s of document.querySelectorAll("script[data-id]")) {
    let txt = s.textContent.replace(/<\\\//g, "</").replace(/<\\!--/g, "<!--").trim();
    const m = txt.match(/^```carte\n([\s\S]*?)^```$/m), schema = m && parse(m[1]);
    if (m) txt = txt.replace(m[0], "");
    const lines = txt.split("\n"), t = lines.findIndex(l => l.startsWith("# "));
    const titre = marked.parseInline(t < 0 ? s.dataset.id : lines.splice(t, 1)[0].slice(2));
    B[s.dataset.id] = { titre, texte: lines.join("\n").trim(), schema,
        kids: [...new Set(schema?.nodes.flatMap(n => n.kids) ?? [])] };
}
const NS = "http://www.w3.org/2000/svg";
function el(tag, attrs, parent) {
    const e = document.createElementNS(NS, tag);
    for (const k in attrs) e.setAttribute(k, attrs[k]);
    parent?.append(e);
    return e;
}
const SHAPE = {
    traitement: (w, h) => `M12 0H${w - 12}Q${w} 0 ${w} 12V${h - 12}Q${w} ${h} ${w - 12} ${h}H12Q0 ${h} 0 ${h - 12}V12`
        + `Q0 0 12 0Z`,
    stockage: (w, h) => `M0 12A${w / 2} 12 0 0 1 ${w} 12V${h - 12}A${w / 2} 12 0 0 1 0 ${h - 12}Z`
        + `M0 12A${w / 2} 12 0 0 0 ${w} 12`,
    fichier: (w, h) => `M0 0H${w - 20}L${w} 20V${h}H0Z M${w - 20} 0V20H${w}`,
    "règle": (w, h) => `M18 0H${w - 18}L${w} ${h / 2}L${w - 18} ${h}H18L0 ${h / 2}Z`,
    "écran": (w, h) => `M0 0H${w}V${h}H0Z M0 34H${w}`,
    entonnoir: (w, h) => `M0 0L${w} ${h * .25}V${h * .75}L0 ${h}Z`,
    valeur: (w, h) => `M${h / 2} 0H${w - h / 2}A${h / 2} ${h / 2} 0 0 1 ${w - h / 2} ${h}H${h / 2}`
        + `A${h / 2} ${h / 2} 0 0 1 ${h / 2} 0Z`,
};
const size = n => n.nature === "valeur" ? 28 : n.nature === "écran" ? 58 + 16 * n.fact.length
    : 45 + 16 * n.fact.length + (n.nature === "stockage" ? 24 : 0);
// La grille : les couloirs en colonnes, leurs rangées alignées d'un couloir à l'autre ; les bandes en bas.
function layout(S, W, H) {
    const lanes = Object.values(S.lanes), cols = lanes.filter(l => !l.band), of = l => S.nodes.filter(n => n.L === l);
    let y = H;
    for (const b of lanes.filter(l => l.band).reverse()) {
        const h = Math.max(...of(b).map(size), 40) + T + P, nc = Math.max(...of(b).map(n => n.r2), cols.length);
        const cw = (W - (nc - 1) * G) / nc;
        y -= h;
        Object.assign(b, { x: 0, y, w: W, h });
        for (const n of of(b)) Object.assign(n, { x: (n.r1 - 1) * (cw + G) + P, h: size(n),
            w: (n.r2 - n.r1 + 1) * cw + (n.r2 - n.r1) * G - 2 * P, y: y + T + (h - T - P - size(n)) / 2 });
        y -= G / 2;
    }
    const nr = Math.max(...cols.flatMap(of).map(n => n.r2), 1), cell = (y - T - P) / nr;
    const lw = (W - (cols.length - 1) * G) / cols.length;
    cols.forEach((l, i) => Object.assign(l, { x: i * (lw + G), y: 0, w: lw, h: y }));
    for (const l of cols) for (const n of of(l)) {
        const span = (n.r2 - n.r1 + 1) * cell - 12;
        n.h = n.r2 > n.r1 || n.nature === "entonnoir" ? span : Math.min(size(n), span);
        n.serre = n.h < size(n);
        Object.assign(n, { x: l.x + P, w: lw - 2 * P, y: T + (n.r1 - 1) * cell + 6 + (span - n.h) / 2 });
    }
}
// Les flèches restent droites ou à angles droits : elles tournent dans la gouttière avant le couloir visé, ou dans
// l'espace au-dessus d'une bande.
const range = (n, s) => "lr".includes(s) ? (n.nature === "entonnoir" && s === "r"
    ? [n.y + n.h * .25, n.y + n.h * .75] : [n.y, n.y + n.h]) : [n.x, n.x + n.w];
function at(n, s, v) {
    const k = n.nature === "règle" ? 18 * Math.abs(v - n.y - n.h / 2) / (n.h / 2) : 0;
    const f = n.nature === "entonnoir" ? n.h * .25 * (v - n.x) / n.w : 0;
    return { l: [n.x + k, v], r: [n.x + n.w - k, v], t: [v, n.y + f], b: [v, n.y + n.h - f] }[s];
}
function route(a, b) {
    const R = b.x >= a.x + a.w, L = b.x + b.w <= a.x, D = b.y >= a.y + a.h, U = b.y + b.h <= a.y;
    const straight = (s, e) => {
        const lo = Math.max(range(a, s)[0], range(b, e)[0]), hi = Math.min(range(a, s)[1], range(b, e)[1]);
        return hi - lo >= 16 && [at(a, s, (lo + hi) / 2), at(b, e, (lo + hi) / 2)];
    };
    const line = (R ? straight("r", "l") : L && straight("l", "r"))
        || (D ? straight("b", "t") : U && straight("t", "b"));
    if (line) return line;
    const bend = (s, e, g, swap) => {
        const v0 = (range(a, s)[0] + range(a, s)[1]) / 2, [lo, hi] = range(b, e);
        const v1 = Math.min(Math.max(v0, lo + 12), hi - 12), p = (u, v) => swap ? [v, u] : [u, v];
        return [at(a, s, v0), p(g, v0), p(g, v1), at(b, e, v1)];
    };
    if ((R || L) && !a.L.band && !b.L.band)
        return R ? bend("r", "l", b.L.x - G / 2, false) : bend("l", "r", b.L.x + b.L.w + G / 2, false);
    if (D) return bend("b", "t", b.L.y - G / 4, true);
    if (U) return bend("t", "b", a.L.y - G / 4, true);
}
function node(svg, n) {
    const g = el("g", { class: `node s-${STAT[n.statut] ?? "same"}`, transform: `translate(${n.x} ${n.y})` }, svg);
    g.dataset.tags = n.tags.join(" ");
    if (n.kids.length) g.dataset.k = n.kids[0], g.dataset.kids = n.kids.join(" "), g.tabIndex = 0;
    const p = el("path", { d: SHAPE[n.nature](n.w, n.h) }, g);
    if (n.teinte) p.style.fill = `color-mix(in srgb, var(${n.teinte}) 22%, var(--bg))`;
    if (n.teinte && !n.statut) p.style.stroke = `var(${n.teinte})`;
    const F = n.nature === "valeur" ? [] : n.fact, screen = n.nature === "écran";
    const top = screen ? 23 : n.h / 2 - (19 + F.length * 16) / 2 + (n.nature === "stockage" ? 20 : 14);
    const text = (s, y, cls) => (el("text", { x: n.w / 2, y, "text-anchor": "middle", class: cls }, g).textContent = s);
    text(n.label, top, "label");
    F.forEach((f, i) => text(f, top + (screen ? 35 : 21) + i * 16, "fact"));
    const marge = { "règle": 44, entonnoir: 8 }[n.nature] ?? 16;
    const large = Math.max(...[...g.querySelectorAll("text")].map(t => t.getBBox().width));
    if (n.serre || large > n.w - marge) g.classList.add("over");
}
function dessine(box, S, leg) {
    if (S.errs.length) return (box.innerHTML = `<section class="frame markdown-body over" data-over="schéma illisible">
        <pre>${S.errs.join("\n").replace(/</g, "&lt;")}</pre></section>`);
    const W = box.clientWidth, H = box.clientHeight, svg = el("svg", { viewBox: `0 0 ${W} ${H}` }, box);
    layout(S, W, H);
    const m = el("marker", { id: "fleche", viewBox: "0 0 10 10", refX: 9, refY: 5, markerWidth: 8, markerHeight: 8,
        orient: "auto-start-reverse" }, el("defs", {}, svg));
    el("path", { d: "M0 0L10 5L0 10Z", fill: "var(--nord9)" }, m);
    for (const l of Object.values(S.lanes)) {
        const g = el("g", { class: "lane" }, svg);
        el("rect", { x: l.x, y: l.y, width: l.w, height: l.h, rx: 14 }, g);
        el("text", { x: l.x + 16, y: l.y + 24 }, g).textContent = l.titre.toUpperCase();
    }
    const links = el("g", {}, svg);
    for (const n of S.nodes) node(svg, n);
    const verbes = el("g", { class: "verbe" }, svg);
    for (const k of S.links) {
        const pts = route(S.N[k.f], S.N[k.t]);
        if (!pts) continue;
        el("path", { d: "M" + pts.join("L"), "marker-end": "url(#fleche)" },
            el("g", { class: `link${k.faible ? " faible" : ""}` }, links));
        if (!k.verbe) continue;
        const d = i => Math.hypot(pts[i + 1][0] - pts[i][0], pts[i + 1][1] - pts[i][1]);
        const i = pts.slice(1).reduce((best, _, j) => d(j) > d(best) ? j : best, 0);
        const tx = el("text", { x: (pts[i][0] + pts[i + 1][0]) / 2, y: (pts[i][1] + pts[i + 1][1]) / 2 + 4,
            "text-anchor": "middle" }, verbes);
        tx.textContent = k.verbe;
        const bb = tx.getBBox();
        verbes.insertBefore(el("rect", { x: bb.x - 5, y: bb.y - 2, width: bb.width + 10, height: bb.height + 4,
            rx: 4 }), tx);
    }
    const nat = new Set(S.nodes.map(n => n.nature)), st = new Set(S.nodes.map(n => n.statut).filter(Boolean));
    const coul = { "ajouté": "var(--nord14)", "modifié": "var(--nord13)", "retiré": "var(--nord11)" };
    leg.innerHTML = Object.keys(NAT).filter(k => nat.has(k)).map(k => `<span>${NAT[k]} ${k}</span>`).join("")
        + Object.keys(STAT).filter(k => st.has(k)).map(k => `<span><i style="color:${coul[k]}">▬</i> ${k}</span>`)
            .join("") + "<span>clic : zoomer · Échap : remonter</span>";
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
let shown = [];
const via = {}, hl = {}; // pour chaque bulle : le nœud d'où l'on y est entré, et les étiquettes à surligner
function paint(el, p) {
    const b = B[p.at(-1)];
    const crumbs = p.map((id, i) => i === p.length - 1 ? `<span>${B[id].titre}</span>`
        : `<a data-to="${p.slice(0, i + 1).join("/")}">${B[id].titre}</a> ›`).join(" ");
    el.innerHTML = `<nav>${crumbs}<span class="count"></span></nav>` + (b.schema
        ? `<section class="frame head markdown-body"><h1>${b.titre}</h1>${md(b.texte)}</section>
            <div class="schema"></div><div class="legende"></div>`
        : `<section class="frame leaf markdown-body"><h1>${b.titre}</h1>${md(b.texte)}</section>`);
    if (b.schema) dessine(el.querySelector(".schema"), b.schema, el.querySelector(".legende"));
    const tags = hl[p.at(-1)] ?? [];
    for (const n of el.querySelectorAll(".node"))
        n.classList.toggle("hl", n.dataset.tags.split(" ").some(t => tags.includes(t)));
    if (window.hljs) for (const c of el.querySelectorAll('pre code[class*="language-"]:not(.language-mermaid)'))
        hljs.highlightElement(c);
}
const from = (el, k) => {
    const n = el.querySelectorAll(`.node[data-kids~="${CSS.escape(k)}"]`);
    return n[via[k]] ?? n[0];
};
function render() {
    const p = path();
    paint(stage, p);
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
// Comme Zumly : la vue parente reste derrière, floutée, cadrée sur le nœud d'où l'on vient.
function backdrop(p) {
    back.classList.remove("anim");
    back.style.transform = "";
    if (p.length < 2) return (back.innerHTML = "", "");
    paint(back, p.slice(0, -1));
    const q = from(back, p.at(-1)).getBoundingClientRect(), s = innerWidth / q.width;
    return `translate(${innerWidth / 2}px, ${innerHeight / 2}px) scale(${s}) `
        + `translate(${-(q.left + q.width / 2)}px, ${-(q.top + q.height / 2)}px)`;
}
function animate(el, a, b) {
    el.classList.remove("anim");
    Object.assign(el.style, a);
    el.offsetWidth;
    el.classList.add("anim");
    Object.assign(el.style, b);
}
// La règle de l'écran : un cadre qui déborde ou un nœud trop serré se marque en rouge. Jamais de scroll.
function check() {
    let ko = stage.querySelectorAll(".node.over").length;
    for (const f of stage.querySelectorAll(".frame")) {
        const h = f.scrollHeight - f.clientHeight, w = f.scrollWidth - f.clientWidth;
        if (h > 1 || w > 1) ko++;
        f.classList.toggle("over", h > 1 || w > 1 || f.dataset.over === "schéma illisible");
        if (f.dataset.over !== "schéma illisible")
            f.dataset.over = [h > 1 && `+${h} px ↓`, w > 1 && `+${w} px →`].filter(Boolean).join(" · ");
        else ko++;
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
// Zoom : la nouvelle vue part du cadre du nœud (entrée) ou y retourne (sortie), puis se pose à l'écran.
function go() {
    const before = shown, after = path();
    const into = after.length === before.length + 1 && before.every((id, i) => id === after[i]);
    const out = before.length === after.length + 1 && after.every((id, i) => id === before[i]);
    const side = before.length === after.length && after.length > 1
        && before.slice(0, -1).join("/") === after.slice(0, -1).join("/") && before.at(-1) !== after.at(-1);
    stage.classList.remove("anim");
    stage.style.transform = "";
    const r = into && from(stage, after.at(-1))?.getBoundingClientRect();
    shown = render();
    const W = innerWidth, H = innerHeight, kids = B[after.at(-2)]?.kids ?? [];
    const behind = backdrop(after);
    let t0 = "";
    if (r) t0 = `translate(${r.left}px, ${r.top}px) scale(${r.width / W}, ${r.height / H})`;
    const t = out && from(stage, before.at(-1));
    if (t) {
        const q = t.getBoundingClientRect();
        t0 = `scale(${W / q.width}, ${H / q.height}) translate(${-q.left}px, ${-q.top}px)`;
    }
    if (side) t0 = `translateX(${Math.sign(kids.indexOf(after.at(-1)) - kids.indexOf(before.at(-1))) * W / 3}px)`;
    if (t0) animate(stage, { transform: t0, opacity: 0.2 }, { transform: "", opacity: 1 });
    if (r) animate(back, { transform: "", filter: "none", opacity: 1 }, { transform: behind, filter: "", opacity: 1 });
    else if (t0) animate(back, { transform: behind, opacity: 0 }, { transform: behind, opacity: 1 });
    else back.style.transform = behind;
    (t || stage.querySelector(".node[data-k]"))?.focus({ preventScroll: true });
}
function zoom(n) {
    const k = n.dataset.k;
    via[k] = [...stage.querySelectorAll(`.node[data-kids~="${CSS.escape(k)}"]`)].indexOf(n);
    hl[k] = n.dataset.tags.split(" ").filter(Boolean);
    location.hash = [...shown, k].join("/");
}
const up = () => shown.length > 1 && (location.hash = shown.slice(0, -1).join("/"));
stage.addEventListener("click", e => {
    const a = e.target.closest("a[data-to]"), n = e.target.closest(".node[data-k]");
    if (a) location.hash = a.dataset.to;
    else if (n) zoom(n);
    else if (!e.target.closest(".node, .frame, nav")) up();
});
const sibling = d => { const k = B[shown.at(-2)]?.kids ?? [], j = k.indexOf(shown.at(-1)) + d;
    if (k[j]) location.hash = [...shown.slice(0, -1), k[j]].join("/"); };
addEventListener("keydown", e => {
    if (e.ctrlKey || e.altKey || e.metaKey) return;
    const n = document.activeElement?.closest?.(".node[data-k]"), leaf = !B[shown.at(-1)].schema;
    if (e.key === "Escape" || e.key === "Backspace") up();
    else if ((e.key === "Enter" || e.key === " ") && n) zoom(n);
    else if (leaf && (e.key === "ArrowRight" || e.key === "ArrowLeft")) sibling(e.key === "ArrowRight" ? 1 : -1);
    else return;
    e.preventDefault();
});
addEventListener("hashchange", go);
addEventListener("resize", () => { shown = render(); back.style.transform = backdrop(shown); });
document.fonts.ready.then(() => { shown = render(); back.style.transform = backdrop(shown); });
go();
</script>
JS
} > "$page"
terminal-browser open "$page" --split right > /dev/null
echo "montré : $page"
