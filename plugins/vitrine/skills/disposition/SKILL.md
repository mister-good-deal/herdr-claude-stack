---
name: disposition
description: "Disposer l'onglet herdr de l'agent pour une situation, comme une grille CSS : terminal et vue côte à côte pour faire lire, deux à quatre vues pour comparer des variantes (prototypes A/B/C, avant/après), une colonne de suivi (journal en tail -f, sortie d'un lieutenant, trace de CI), terminal seul, puis rangement. Utiliser dès qu'on veut montrer quelque chose, faire trancher entre des variantes ou surveiller des journaux ou des lieutenants à côté de la conversation."
---

# Disposer l'onglet du terminal

L'humain travaille dans Ghostty, avec herdr et Claude Code. Cette skill range l'onglet herdr de l'agent pour la
situation du moment : le terminal de l'agent, et à côté des vues (le navigateur de terminal-browser), des commandes ou
la sortie d'autres agents. Elle ne touche qu'à la pane de l'agent et aux panes qu'elle a créées pour lui, jamais aux
autres workspaces.

Le script `disposition.sh` est à côté de ce fichier, dans le dossier de base de la skill que Claude Code indique au
chargement :

```bash
"<dossier de la skill>/disposition.sh" lecture                    # terminal 45 %, navigateur à droite
"<dossier de la skill>/disposition.sh" lecture 35 rapport.html    # terminal 35 %, la page dans la vue
"<dossier de la skill>/disposition.sh" comparer a.png b.png c.png # trois vues côte à côte, terminal en bas
"<dossier de la skill>/disposition.sh" suivi app.log @lt-voix 'glab ci trace'   # colonne de suivi à droite
"<dossier de la skill>/disposition.sh" colonnes 40 30 30          # grille libre : la 1re part reste au terminal
"<dossier de la skill>/disposition.sh" lignes 70 30 'npm test'    # pareil, en lignes
"<dossier de la skill>/disposition.sh" focus                      # terminal seul (zoom), et retour au 2e appel
"<dossier de la skill>/disposition.sh" ranger                     # ferme les panes de la disposition
```

- **Cible.** Une URL (`http…`, `localhost:5173`), une page `.html`, une image ou un `.pdf` s'ouvrent dans un
  navigateur. Un autre fichier passe en `tail -F`. `@lt-voix` (nom d'agent) ou `@w2:p1` (pane) affiche sa sortie,
  rafraîchie toutes les 5 s. Tout le reste est une commande shell, lancée dans le dossier courant.
- **pct** : la part du terminal, en pour cent, facultative. Par défaut : 45 pour `lecture`, 40 pour `suivi`, 35 en
  hauteur pour `comparer` (25 en largeur sur un onglet large).
- `lecture` réutilise le navigateur déjà ouvert à droite (par `montrer`, `lire` ou `apercu`) : elle règle seulement le
  partage, et ouvre la cible dans un nouvel onglet. Ensuite, `montrer`, `lire` et `apercu` ouvrent leurs pages dans
  ce navigateur.
- Le script affiche les ids des panes créées. On y lance ensuite ce qu'on veut avec `herdr pane run <pane> "…"`.
- Relancer une disposition remplace la précédente : les panes créées par le script sont fermées, puis la nouvelle
  disposition est construite, sans empiler. Ces panes sont notées dans `/tmp/claude-<uid>/disposition/<pane>`.

## Selon la largeur de l'onglet

La console est souvent en demi-écran sur l'ultrawide (environ 240 colonnes), parfois en plein écran (430 environ).
Le script lit la largeur de l'onglet et choisit la variante. Une vue ou un terminal demande au moins 80 colonnes.

| Onglet    | lecture              | comparer                                    | suivi                            |
|-----------|----------------------|---------------------------------------------|----------------------------------|
| < 160 col | vue sous le terminal | vues empilées en haut, terminal en bas      | cibles empilées sous le terminal |
| 160–399   | vue à droite         | vues côte à côte en haut, terminal en bas   | cibles empilées à droite         |
| ≥ 400     | vue à droite         | terminal à gauche (25 %), vues côte à côte  | cibles côte à côte à droite      |

Quand la place manque (onglet étroit, ou plus de vues que de tranches de 80 colonnes), le script fait au mieux : les
vues passent en grille ou s'empilent. Il affiche alors une ligne : « Pour plus de place : console en plein écran
(Super+↑), puis relance. » Transmets-la à l'humain. Le script ne redimensionne jamais la fenêtre.

## Règles

- **Montrer, puis demander.** Pour faire choisir : `comparer` avec les variantes dans l'ordre des options de la
  question (A, B, C). La question suit dans la conversation.
- `ranger` à la fin, quand l'humain a répondu ou que le suivi n'a plus d'objet. `focus` sert pour une pause : les
  panes continuent de tourner derrière le zoom.
- Ne jamais lancer la skill pour la pane d'un autre agent. Le script agit sur la pane qui l'appelle (`herdr pane
  current --current`).
- Agent dans un autre workspace herdr que l'humain (un lieutenant) : l'humain ne regarde pas son onglet. Il envoie
  plutôt au coordinateur ce qu'il faut montrer, et le coordinateur dispose son propre onglet.
- Le coordinateur suit ses lieutenants avec `suivi @lt-a @lt-b`. C'est de la lecture seule : rien n'est tapé dans
  leurs panes.
- Pour une seule image ou un markdown sans changer la disposition : skills `montrer` et `lire`.

Les dépendances sont herdr, jq et terminal-browser pour les vues.
