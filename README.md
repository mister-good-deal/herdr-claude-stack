# herdr-claude-stack

Des skills et des mods Claude Code pour travailler avec **une flotte d'agents** dans **herdr**, pour **montrer** à
l'humain ce qu'on fait, dans un pane à droite de son terminal, et pour mener le travail **de l'idée à la MR** sur Spec-Kit.

Les plugins sont écrits en français et tirés d'un vrai projet. Ils supposent l'environnement Ghostty + herdr + Claude Code
+ terminal-browser, décrit dans [docs/environnement.md](docs/environnement.md).

## Les plugins

| Plugin | Contenu | Pour |
|---|---|---|
| **`flotte`** | skills `coordinateur` et `lieutenant`, scripts `lancer-lieutenant.sh` et `veille-boite.sh`, garde-fous (mod) | mener des lieutenants : un par lot, chacun dans son worktree herdr, avec une G1 avant le code, une relecture indépendante, un push et une MR par lot |
| **`vitrine`** | skills `montrer`, `lire`, `apercu` et `disposition` | montrer à l'humain des images côte à côte, un document markdown en thème Nord (pages de validation comprises), ou un écran vivant de l'app web qu'il peut cliquer, dans terminal-browser à droite ; disposer l'onglet herdr pour lire, comparer des variantes ou suivre des journaux |
| **`chantier`** | skills `dev-workflow`, `bug-workflow` et `idea-workflow` | mener une feature, un bug ou une idée sur Spec-Kit 1.2+, de la description à la MR, avec des gates humaines montrées en page |

## Installer

Dans une session Claude Code :

```
/plugin install flotte --marketplace mister-good-deal/herdr-claude-stack
/plugin install vitrine --marketplace mister-good-deal/herdr-claude-stack
/plugin install chantier --marketplace mister-good-deal/herdr-claude-stack
```

Depuis un shell :

```bash
claude plugin install flotte --marketplace mister-good-deal/herdr-claude-stack
claude plugin install vitrine --marketplace mister-good-deal/herdr-claude-stack
claude plugin install chantier --marketplace mister-good-deal/herdr-claude-stack
```

- Réponds `y` pour ajouter la marketplace, puis choisis la portée : utilisateur pour tous tes projets, ou projet. Pour
  un projet, l'activation s'écrit dans son `.claude/settings.json` (`enabledPlugins`), et tout clone du projet en
  hérite.
- Dans une session, les skills s'appellent `flotte:coordinateur`, `flotte:lieutenant`, `vitrine:montrer`,
  `vitrine:lire`, `vitrine:apercu`, `vitrine:disposition`, `chantier:dev-workflow`, `chantier:bug-workflow` et
  `chantier:idea-workflow`.
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

## Ce que fait le chantier

- **`/dev-workflow`** : une feature. specify → clarify → plan → tasks → analyze → issues → assign → implement ⇄
  converge → verify → review, avec trois gates humaines.
- **`/bug-workflow`** : un bug, de l'issue ou du signalement jusqu'à la MR. Le diagnostic est validé avant le code, un
  test de régression échoue d'abord, et le verdict est vérifié, partiel ou échoué.
- **`/idea-workflow`** : une idée avant toute spec. intake → research → define → shape → decide ; un go devient une
  issue puis un `/dev-workflow`.
- **Prérequis** : Spec-Kit 1.2+, avec les extensions `bug` et `assess`, et un CLI de tracker.
- **Un fichier projet par dépôt** : `.specify/workflow-project.md` porte le rail git, les gates, le tracker et les pages
  de validation. Sans lui, les skills s'arrêtent ; un gabarit est en annexe de `dev-workflow`.
- **Les gates humaines** se montrent en page, par exemple avec `vitrine:lire`. La question reste dans le terminal.

## Le mod de `flotte`

Deux garde-fous sur le shell :
- `herdr agent prompt` ne vise qu'un lieutenant (`lt-…`) ;
- `pkill` et `killall` sont refusés : un processus s'arrête par son PID.

## Licence

MIT, voir [LICENSE](LICENSE).
