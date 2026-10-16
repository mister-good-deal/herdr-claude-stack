---
name: apercu
description: "Ouvrir un écran vivant de l'app web du worktree courant (son serveur de dev, avec fixtures et rechargement à chaud) dans un navigateur à droite du terminal de l'humain, le lui montrer et le piloter : revue UI/UX, prototypes à comparer, preuve qu'un écran marche, reproduction d'un bug d'écran. L'humain clique dans le même navigateur que l'agent."
---

# Aperçu d'un écran de l'app

Cette skill sert le worktree courant avec son serveur de dev. Chaque worktree a son propre port, tiré de son chemin
(5400–5799), pour que deux agents ne se gênent pas. L'app s'ouvre dans le navigateur de terminal-browser, dans un pane
à droite. Chaque modification d'un fichier de l'app se voit aussitôt, par le rechargement à chaud.

Le script `apercu.sh` est à côté de ce fichier, dans le dossier de base de la skill que Claude Code indique au
chargement :

```bash
"<dossier de la skill>/apercu.sh"                 # ouvre l'app sur /
"<dossier de la skill>/apercu.sh" '/?proto=B'     # une variante, si l'écran en lit une dans l'URL
"<dossier de la skill>/apercu.sh" --serve '/?proto=A'  # serveur seul : affiche l'URL sans ouvrir de navigateur
"<dossier de la skill>/apercu.sh" --stop          # arrête le serveur de ce worktree, par son PID
```

**Quel serveur ?** Sans configuration, le script prend le premier dossier (la racine, `*/` ou `*/*/`) qui a un
`index.html` et `node_modules/vite`. Il y lance Vite sur le port du worktree. Pour un autre projet, écris à la racine un
fichier `.apercu`, que le script source :

```bash
APERCU_DIR=frontend                                    # relatif à la racine, optionnel
APERCU_CMD='npm run dev -- --port $PORT --strictPort'  # $PORT vaut le port du worktree
```

**Un agent hors du workspace de l'humain**, par exemple un lieutenant, utilise `--serve`. Il envoie ensuite au
coordinateur chaque URL, avec une ligne qui décrit la variante. Le coordinateur l'ouvre chez l'humain :
`terminal-browser new-tab --browser <clé> <url>`, la clé étant donnée par `terminal-browser ls --all`.

## Piloter l'écran

C'est le rôle de la skill `terminal-browser`. Le navigateur est partagé : l'humain voit chaque geste de l'agent, et
l'agent voit l'état que l'humain a laissé.

```bash
terminal-browser ls                              # navigateurs et onglets, avec leurs ids
terminal-browser action -- snapshot              # arbre d'accessibilité avec ses refs (@e13…)
terminal-browser action -- click @e13
terminal-browser action -- fill @e3 "texte"
terminal-browser action -- screenshot /tmp/claude-$(id -u)/ecran.png
terminal-browser action done                     # à la fin : efface l'indicateur « l'agent agit »
```

## Règles

- **Montrer, puis demander.** Pour faire choisir entre des variantes : un onglet par variante, ou leurs captures côte à
  côte avec la skill `montrer`. La question nomme ensuite les onglets ou les lettres.
- Ne pas cliquer pendant que l'humain manipule : lui dire ce qu'on va faire, ou attendre sa réponse.
- `terminal-browser action done` après la dernière action.
- L'aperçu montre les fixtures, pas les vraies données. La preuve sur le chemin réel reste celle des tests.
- Arrêter son serveur (`--stop`) en fin de lot.
- Sous Codex : lancer `terminal-browser` avec des permissions élevées, comme le dit la skill `terminal-browser` de Codex.
