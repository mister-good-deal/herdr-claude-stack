---
name: lire
description: "Montrer un document markdown à l'humain, mis en page en thème sombre Nord, dans le navigateur à droite de son terminal (Ghostty + herdr + terminal-browser) : brouillon à relire (post, fiche, note de version), page de doc, rapport. Utiliser au lieu de coller un long texte dans la conversation."
---

# Faire lire un document markdown à l'humain

L'humain relit mieux un document mis en page qu'un long texte collé dans la conversation. Cette skill rend un fichier
markdown en page sombre, au thème Nord, et l'ouvre dans le navigateur de
[terminal-browser](https://github.com/zenbu-labs/terminal-browser), dans le pane à droite du sien. C'est le même
navigateur que celui de la skill `montrer`, avec un onglet par appel.

Le script `lire.sh` est à côté de ce fichier, dans le dossier de base de la skill que Claude Code indique au
chargement :

```bash
"<dossier de la skill>/lire.sh" brouillon.md "Post forum — brouillon"
```

- Le titre est facultatif ; sans titre, c'est le nom du fichier.
- La page est écrite dans `/tmp/claude-<uid>/montrer/`, et le script affiche son chemin.
- **Le thème** est Nord (Polar Night), dans `nord.css` à côté du script, inliné dans la page, sur les polices système
  (Adwaita Sans, Adwaita Mono). Le code est coloré quand le bloc nomme son langage ; un tableau large défile dans son
  propre cadre.
- **Le texte ne quitte pas la machine.** La page est locale. Seuls `marked` (jsdelivr) et `highlight.js` (cdnjs)
  viennent d'un CDN, en versions figées. Jamais de viewer markdown en ligne : le document partirait chez un tiers.

## Schémas, ancres et liens relatifs

- Un bloc ` ```mermaid ` se rend en schéma (mermaid 10.9.1, thème sombre). Un schéma plus large que la page tient
  dans un cadre calé sur sa largeur (85vh au plus) : molette pour zoomer, glisser pour se déplacer, + − RESET, ⛶ plein écran (svg-pan-zoom 3.6.1).
- Les titres portent leurs ancres à la GitLab : minuscules, ponctuation retirée, espaces en tirets, tirets réduits.
- Un lien relatif (`./page.md#ancre`) se résout contre `LIRE_BASE`, sans le `.md`. Pour un brouillon de page du wiki
  GitLab : `LIRE_BASE=https://<gitlab>/<groupe>/<projet>/-/wikis/<section>/`. Sans `LIRE_BASE`, il se résout contre
  le dossier du fichier.

## Liens vers les issues

Chaque `#123` du texte devient un lien vers l'issue, dans un nouvel onglet. L'URL vient du `origin` du dépôt git du
fichier, sinon de celui du dossier courant : GitLab (`…/-/issues/`) ou GitHub (`…/issues/`). Pour un autre préfixe,
définis `LIRE_ISSUES`. Le code et les liens déjà écrits ne sont pas touchés.

## Pages de validation

Une gate humaine (validation d'une spec, d'une liste de lots, d'un diagnostic de bug, d'une fiche de MR) se montre en
page plutôt qu'en texte dans le terminal. Le markdown porte un peu de HTML, et la feuille de style est déjà dans la page :

```html
<div class="pipe"><span class="ok">specify ✔</span><span class="here">◉ GATE 2</span><span>execute</span></div>

<div class="ask"><b>Ce qu'on attend de toi :</b> le go sur la liste des lots, et le point R1.</div>

<div class="gantt" style="--slots:6">
<div></div><div class="h">1</div><div class="h">2</div>…
<div class="lot">#832 Socle <span class="warn-tag">⚠ données</span></div>
<div class="bar warn" style="grid-column:2/4">Stockage · Backend 7</div>
</div>
```

- `.pipe` : les étapes du workflow (`.ok` fait, `.here` la gate en cours, `.ko` bloqué).
- `.ask` : ce qu'on attend de l'humain, en tête de page, en deux ou trois lignes.
- `.gantt` : l'ordre des lots en barres. `--slots` donne le nombre de cases. `.lot` prend la colonne 1. La barre se
  place par `grid-column` (case n = colonne n+1). Variantes : `.warn`, `.you` (une étape pour l'humain) et `.done`.
- `.warn-tag` : une pastille ⚠ (données, contrat, sécurité). `.note` : une légende discrète.

La question reste posée dans le terminal. Les artefacts cités (spec, plan, tâches, prototypes) s'ouvrent dans les
onglets voisins. Une fois la réponse donnée, on ferme les onglets : `terminal-browser action -- tab close <n>`.

## Règles

- Écris d'abord le document dans un fichier `.md` du scratchpad, puis montre-le. Dans la conversation, donne seulement
  ce qu'on attend de l'humain : une relecture, un choix.
- Pour relire dans le terminal plutôt que dans le navigateur : `mdcat --columns 120 -p fichier.md` dans un pane herdr à
  droite (`herdr pane split <pane> --direction right`, puis `herdr pane run <nouveau pane> "…"`).
- Agent dans un autre workspace herdr que l'humain (un lieutenant) : envoie plutôt le chemin du fichier au
  coordinateur, qui le montre.
- Pour des images : skill `montrer`. Pour un écran vivant de l'app : skill `apercu`.

La seule dépendance est terminal-browser, qui trouve le pane herdr à droite ou le crée.
