# L'environnement : Ghostty + herdr + Claude Code + terminal-browser

Les plugins de ce dépôt supposent un poste où :
- l'humain travaille dans **Ghostty** ;
- **herdr** multiplexe les sessions : un pane par agent, un workspace par worktree ;
- les agents sont des sessions **Claude Code**, plus éventuellement Codex ;
- **terminal-browser** affiche des pages web dans un pane.

Tout tourne en local. Une seconde machine peut héberger des lieutenants.

## Ghostty

Rien à configurer. Ghostty parle le protocole graphique Kitty, que terminal-browser et les images des mods Claude Code
utilisent.

## herdr

- **Images dans les panes.** Dans `~/.config/herdr/config.toml`, active la transmission des images au terminal
  extérieur :

  ```toml
  kitty_graphics = true
  ```

- **Seconde machine** (par exemple un portable qui héberge des lieutenants) : enregistre un profil avec
  `herdr machine add`. `herdr --machine <profil> agent list|prompt|start` pilote alors ses sessions depuis le poste
  principal.
- **Ce que la flotte utilise de herdr** :
  - `herdr worktree create` : un worktree et son workspace par lieutenant ;
  - `herdr agent start` et `herdr agent prompt` : lancer un lieutenant et lui écrire ;
  - `herdr agent list` : l'état de la flotte ;
  - `herdr pane split` : le pane de droite, que terminal-browser sait créer seul.

## Claude Code

- **Canal entre sessions.** `SendMessage` relie les sessions Claude Code d'une même machine. Un message arrive dans la
  conversation sans toucher à la saisie de l'humain. C'est par ce canal que les lieutenants rendent compte au
  coordinateur.
- **Mode auto.** Le classifieur de permissions ne connaît pas votre façon de travailler : décris-la-lui dans
  `~/.claude/settings.json`, section `autoMode` (`environment` et `allow`).
  - Écris-y la flotte : qui pilote qui, depuis quels dossiers.
  - Écris-y les gestes routiniers : le push d'une branche de lot avec l'accord du projet, la MR, l'édition des docs de
    protocole.
  - Sans ces règles, un lieutenant peut se voir refuser un push dont l'accord arrive par un pair, ou l'édition d'un
    `AGENTS.md` qui décrit la flotte.

  Exemple :

  ```json
  "autoMode": {
    "environment": ["$defaults", "**Flotte d'agents**: une session coordinateur pilote des lieutenants Claude Code dans des worktrees herdr ; ils se parlent par herdr agent prompt et SendMessage."],
    "allow": ["$defaults", "Dans un worktree de la flotte, pousser sa branche de lot et ouvrir sa MR vers la release courante est routinier."]
  }
  ```

- **Images dans un mod.** Sous herdr, Claude Code ne reconnaît pas Ghostty, puisque `TERM_PROGRAM=herdr`. Un élément
  `Image` de mod s'affiche alors en texte de remplacement. Lance la session avec `CLAUDE_CODE_FORCE_TERMINAL_IMAGES=1`
  pour forcer le protocole Kitty, que herdr transmet bien.

## terminal-browser

Un vrai Chromium (Electron, rendu hors écran) affiché par le protocole Kitty. Il se pilote par la souris, le clavier et
la molette, et un agent le pilote par `terminal-browser action`.
[zenbu-labs/terminal-browser](https://github.com/zenbu-labs/terminal-browser), sous licence MIT.

```bash
curl -fsSL https://terminal-browser.sh/install -o install.sh   # lis-le avant de le lancer
bash install.sh
terminal-browser config set telemetry.usage off
terminal-browser config set telemetry.crashReports off
terminal-browser config set updates.check off
```

- Le script d'installation vérifie le sha256 de l'archive. Il installe dans `~/.local/share/terminal-browser/app`, avec
  le lanceur `~/.local/bin/terminal-browser`.
- Au premier lancement, il lie ses propres skills (`~/.claude/skills/terminal-browser`, `~/.codex/skills/terminal-browser`).
  Celles de ce dépôt s'appuient dessus.
- `terminal-browser open <url|fichier.html> --split right` ouvre la page dans un pane herdr à droite, ou dans un nouvel
  onglet du navigateur voisin.

## Codex

Codex lit ses skills dans `~/.codex/skills/`. `./install-codex.sh` y lie celles de ce dépôt. `SendMessage` n'existe pas
pour Codex : un lieutenant Codex rend compte par la boîte aux lettres (skill `lieutenant`).
