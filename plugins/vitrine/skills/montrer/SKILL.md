---
name: montrer
description: "Montrer une ou plusieurs images à l'humain dans un navigateur à droite de son terminal (Ghostty + herdr + terminal-browser) : capture d'écran, variantes à comparer côte à côte, graphique, extrait d'image. Utiliser dès qu'une image dit mieux qu'une description, et pour toute comparaison visuelle qu'on lui demande de trancher."
---

# Montrer une image à l'humain

L'humain travaille dans Ghostty, avec herdr et Claude Code. Il voit mieux ce qu'on lui montre que ce qu'on lui décrit.
Cette skill ouvre les images dans le navigateur de [terminal-browser](https://github.com/zenbu-labs/terminal-browser),
dans un pane à droite du sien. C'est le même navigateur d'un appel à l'autre, avec un onglet par appel.

Le script `montrer.sh` est à côté de ce fichier, dans le dossier de base de la skill que Claude Code indique au
chargement :

```bash
"<dossier de la skill>/montrer.sh" --titre "Trois variantes" \
  a.png="A · liste et fiche" b.png="B · vue table" c.png="C · recherche"
```

- `image=légende` : la légende s'affiche sous l'image ; sans `=…`, c'est le nom du fichier.
- Les images sont posées côte à côte et passent à la ligne quand le pane est étroit.
- La page est écrite dans `/tmp/claude-<uid>/montrer/`, et le script affiche son chemin.

## Règles

- **Une page par question.** Quand on demande à l'humain de choisir, les légendes portent les lettres des options de la
  question posée (A, B, C), dans le même ordre.
- Montrer, puis demander : la question suit dans la conversation, et l'image ne la remplace pas.
- Pour une page HTML qu'on a construite (rapport, schéma), on l'ouvre directement avec
  `terminal-browser open page.html --split right` (skill `terminal-browser`).
- Pour un écran vivant de l'app, à cliquer ou à piloter : skill `apercu`.
- Agent dans un autre workspace herdr que l'humain (un lieutenant) : envoie plutôt les chemins des images au
  coordinateur, qui les montre.
- Sous Codex : lance `terminal-browser` avec des permissions élevées, comme le dit la skill `terminal-browser` de Codex.

La seule dépendance est terminal-browser, qui trouve le pane herdr à droite ou le crée.
