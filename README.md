# usage-limits

Mod Claude Code : affiche dans le footer le compte actif (au centre) et l'utilisation des limites d'abonnement (à droite).

```
? for shortcuts            ☺ you@example.com                   ⁵ʰ◑ 42% ↻ 2h13 │ ⁷ʲ◔ 18%
```

- `☺` : email du compte connecté, lu dans `~/.claude.json` (`oauthAccount`), relu après chaque réponse
- `⁵ʰ` : fenêtre de 5h, % utilisé + temps avant reset
- `⁷ʲ` : fenêtre hebdomadaire, % utilisé
- jauge `○◔◑◕●` colorée selon le thème : vert < 50 %, orange < 80 %, rouge au-delà

Les % viennent de la dernière réponse de l'API (mis à jour à chaque réponse) ; le compte à rebours avance toutes les 30 s. Rien ne s'affiche avec une clé API (ni compte, ni limites d'abonnement). Le centrage suppose 2 colonnes de marge à droite du footer (`RIGHT_PAD` dans `hooks/register.tsx`).

## Installation

Dans une session Claude Code (terminal) :

```
/plugin install usage-limits --marketplace mister-good-deal/claude-usage-limits
```

puis `y` pour ajouter la marketplace, et le scope **user**.
