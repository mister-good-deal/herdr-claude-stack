# herdr-claude-stack

Des skills et des mods Claude Code pour travailler avec **une flotte d'agents** dans **herdr**, et pour **montrer** à
l'humain ce qu'on fait, dans un pane à droite de son terminal.

Les plugins sont écrits en français et tirés d'un vrai projet. Ils supposent l'environnement Ghostty + herdr + Claude Code
+ terminal-browser, décrit dans [docs/environnement.md](docs/environnement.md).

## Les plugins

| Plugin | Contenu | Pour |
|---|---|---|
| **`flotte`** | skills `coordinateur` et `lieutenant`, scripts `lancer-lieutenant.sh` et `veille-boite.sh`, garde-fous (mod) | mener des lieutenants : un par lot, chacun dans son worktree herdr, avec une G1 avant le code, une relecture indépendante, un push et une MR par lot |
| **`vitrine`** | skills `montrer` et `apercu` | montrer à l'humain des images côte à côte, ou un écran vivant de l'app web qu'il peut cliquer, dans terminal-browser à droite |

## Installer

Dans une session Claude Code :

```
/plugin install flotte --marketplace mister-good-deal/herdr-claude-stack
/plugin install vitrine --marketplace mister-good-deal/herdr-claude-stack
```

Depuis un shell :

```bash
claude plugin install flotte --marketplace mister-good-deal/herdr-claude-stack
claude plugin install vitrine --marketplace mister-good-deal/herdr-claude-stack
```

- Réponds `y` pour ajouter la marketplace, puis choisis la portée : utilisateur pour tous tes projets, ou projet. Pour
  un projet, l'activation s'écrit dans son `.claude/settings.json` (`enabledPlugins`), et tout clone du projet en
  hérite.
- Dans une session, les skills s'appellent `flotte:coordinateur`, `flotte:lieutenant`, `vitrine:montrer` et
  `vitrine:apercu`.
- Pour Codex : `./install-codex.sh` lie les skills dans `~/.codex/skills/`.

## Ce que fait la flotte

```
humain ──► coordinateur ──herdr agent prompt──► lt-<sujet> (worktree, branche, une MR à la fois)
               ▲                                    │
               └─────────── SendMessage ────────────┘    (boîte aux lettres si autre machine ou Codex)
```

- **Le coordinateur** est la session où l'humain tape.
  - Il lance les lieutenants (`lancer-lieutenant.sh`) et juge leurs G1.
  - Il fait relire leurs MR par un sous-agent Opus et vérifie chaque bloquant dans le code.
  - Il arme les merges et remonte à l'humain ce qui est à lui.
- **Un lieutenant** travaille un lot dans son worktree.
  - Il poste sa G1 avant de coder, passe ses gates et fait UN push, puis rend compte par `SendMessage`.
  - Le message arrive sans toucher à la saisie de l'humain : c'est la raison de ce canal.
- **Le coordinateur écrit aux lieutenants par `herdr agent prompt`**, dans leur pane, où personne ne tape. Il n'écrit
  jamais par ce canal vers le pane de l'humain, et le mod `flotte` le refuse.
- **Les règles du projet passent avant les skills.** Les skills ne gardent que la mécanique et renvoient au fichier
  d'instructions du projet (`AGENTS.md` ou `CLAUDE.md`) pour le rail git, les gates et les fiches.

## Le mod de `flotte`

Deux garde-fous sur le shell :
- `herdr agent prompt` ne vise qu'un lieutenant (`lt-…`) ;
- `pkill` et `killall` sont refusés : un processus s'arrête par son PID.

## Licence

MIT, voir [LICENSE](LICENSE).
