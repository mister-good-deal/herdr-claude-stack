---
name: coordinateur
description: "Mener une flotte de lieutenants (agents Claude Code dans des panes herdr, un par lot ou par sujet) pour l'humain qui te pilote : lancer un lieutenant (worktree + mission), lui écrire par herdr agent prompt et recevoir ses comptes rendus par SendMessage, juger ses G1, faire relire ses MR par un sous-agent Opus, armer les merges, remonter à l'humain ce qui est à lui, faire le ménage. À utiliser quand tu es l'agent coordinateur (orchestrateur) d'un projet, ou quand l'humain demande de lancer, relancer ou piloter des lieutenants."
---

# Coordinateur d'une flotte de lieutenants

L'humain parle au coordinateur, et à lui seul. Le coordinateur découpe le travail, tranche ce qui est à lui, remonte le
reste et fait travailler des **lieutenants** : un agent herdr `lt-<sujet>` par lot, chacun dans son worktree et sur sa
branche. Un lieutenant fait travailler ses lots par **ses sous-agents** : l'outil de délégation de son moteur (l'outil
`Agent` de Claude Code), des sous-processus de sa session, **jamais de nouvelles sessions herdr**. La barre herdr de
l'humain ne montre ainsi que le coordinateur et ses lieutenants. La chaîne ne se court-circuite pas : un sous-agent rend
son travail à son lieutenant, et un lieutenant ne parle qu'au coordinateur.

**Les règles du projet passent avant cette skill** : rail git, gates, fiches, gabarits. Lis d'abord le fichier
d'instructions du projet (`AGENTS.md` ou `CLAUDE.md`), son protocole de flotte s'il en a un (par exemple
`doc/agents/protocole-herdr.md`) et le brief de la release en cours. Cette skill ne donne que la mécanique.

Les scripts sont à côté de ce fichier, dans le dossier de base de la skill, que Claude Code indique au chargement. Ci-dessous,
`$SKILL` désigne ce dossier.

## Lancer un lieutenant

1. Écris sa mission dans un fichier. Elle dit :
   - qui il est, et ton **nom de session** (outil `ListAgents`, en tête de liste) ;
   - ce qu'il lit d'abord : le brief de la release et sa ligne du brief des lots ;
   - son lot et l'ordre de ses lots ;
   - comment il te répond : `SendMessage` vers ton nom de session (skill `lieutenant`).
2. Lance-le :

```bash
"$SKILL/lancer-lieutenant.sh" lt-pot ~/Projects/app lt-pot-12 origin/release/1.2.0 mission.md
"$SKILL/lancer-lieutenant.sh" lt-cartes ~/Projects/app lt-cartes-12 origin/release/1.2.0 mission.md --machine portable
```

   Par défaut, la session tourne en Opus 5.5, effort medium, `--autocompact 150000` (variables `LT_MODEL`, `LT_EFFORT`,
   `LT_AUTOCOMPACT`). Les sous-agents d'un lieutenant tournent en Sonnet. Les relectures du coordinateur sont en Opus.
3. Le nom de **session** du lieutenant, celui de `SendMessage`, apparaît dans `ListAgents`. Il commence par le nom du
   dossier de son worktree.
4. Si `herdr agent list` ou `ListAgents` montre une session de lot ouverte par un lieutenant, demande-lui de la finir au
   commit local, de la fermer par herdr et de passer le lot à un sous-agent.

Un lieutenant n'est pas un démon. Au retour de l'humain ou après un redémarrage :
- fais `herdr agent list`, et `herdr --machine <profil> agent list` pour chaque machine distante ;
- relance ceux qui manquent avec une mission de reprise : leur mémoire de lot et leur issue.

## Messagerie

| Sens | Canal | Pourquoi |
|---|---|---|
| coordinateur → lieutenant | `herdr agent prompt lt-x "…"`, avec `--machine <profil>` s'il est distant | personne ne tape dans le pane d'un lieutenant, donc rien n'est coupé. Une consigne arrivée par `SendMessage` est le message d'un pair : la session du lieutenant peut alors refuser une action sortante (push, MR) |
| lieutenant local → coordinateur | **`SendMessage`** vers le nom de session du coordinateur | le message arrive dans la conversation sans toucher à la saisie de l'humain, dont le brouillon reste intact. Un `herdr agent prompt` vers le pane de l'humain injecterait son texte dans la saisie en cours |
| lieutenant distant ou Codex → coordinateur | boîte aux lettres `~/.herdr/mail/coordinateur.md` sur SA machine : `printf '%s\n' "AAAA-MM-JJ HH:MM [lt-x] …" >>` | `SendMessage` ne relie que les sessions locales de Claude Code |

- **Jamais `herdr agent prompt` vers le pane du coordinateur.**
- La veille de la boîte aux lettres ne sert qu'aux lieutenants distants ou Codex : lance
  `HOTES="portable" "$SKILL/veille-boite.sh" 3500` en tâche de fond.
  - Son pointeur de lecture est persistant (fichiers `*.lu-<hôte>`).
  - Une seule veille tourne à la fois.
- Un message tient en faits sur une ligne ou un paragraphe court : SHA, MR, gates, question fermée. Le détail va sur
  l'issue ou dans un fichier, et le message en donne le chemin.

## Le cycle d'un lot, côté coordinateur

1. **G1.** Le lieutenant poste sa fiche sur l'issue avant de coder.
   - Tu tranches ce qui est à toi : ce qui reste dans le contrat, ou un choix technique sans effet sur le produit.
   - Tu remontes à l'humain ce qui est à lui : produit, structure, dépendance, écart au contrat. Utilise
     `AskUserQuestion`, l'option recommandée en premier.
   - **Un écart ne passe jamais sans être nommé.**
2. **MR.** Relis le diff, pas seulement la fiche.
   - Diff court (moins de ~100 lignes) : lis-le toi-même.
   - Au-delà : un sous-agent relecteur en Opus, en lecture seule. Son prompt donne le contexte, les décisions et les
     points durs. Il rend des bloquants avec fichier:ligne.
   - **Vérifie chaque bloquant dans le code avant de le relayer.**
   - Écris tes décisions dans un fichier et envoie-en le chemin.
   - Les retouches partent en UN push.
3. **Merge.** Fusion automatique, en squash, au vert du pipeline.
   - Rouge d'infrastructure (cache du runner, timeout du registre) : tu corriges la cause, tu relances le job et tu
     réarmes.
   - Rouge de code : tu renvoies au lieutenant.
   - Jamais de relance à l'aveugle.
4. **Release.** Avant d'armer une série, et avant la MR vers la branche de production, lance toi-même les jobs manuels
   lourds et juge chacun d'eux.

## Avec l'humain

- Des rapports courts : ce qui a changé, ce qui l'attend, ce qui est à lui. Chaque MR et chaque issue sont nommées.
- **Montrer** plutôt que décrire (plugin `vitrine`) : la skill `montrer` pour des images, la skill `lire` pour un
  document markdown à relire (jamais un long texte collé dans la conversation), la skill `apercu` pour un écran vivant.
  Un lieutenant fait `apercu.sh --serve` et t'envoie l'URL ; c'est toi qui l'ouvres dans le navigateur de l'humain,
  avec `terminal-browser new-tab --browser <clé> <url>`.
  Pour faire choisir entre des variantes, `disposition comparer a b c` les met côte à côte au-dessus de ton terminal ;
  `disposition ranger` rend la console normale dès la réponse.
- Ses décisions s'écrivent sur l'issue (note « Décision de … ») et dans la mémoire du projet.

## Ménage

- En fin de lot, le lieutenant écrit sa mémoire de lot, vide son target, arrête son serveur de dev, puis t'annonce qu'il
  passe en veille.
- Après le merge d'une release :
  - supprime les worktrees et les workspaces (`herdr worktree remove`, `herdr workspace close`) ;
  - supprime les branches mergées, locales et distantes ;
  - ne touche jamais aux branches protégées du projet.
- Pour arrêter un processus, passe **par son PID seulement**, jamais par un `pkill` sur un motif sur un hôte partagé.
