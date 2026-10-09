# usage-limits

Mod Claude Code : affiche dans le footer le compte actif et son forfait (au centre), puis à droite les messages envoyés, le contexte et l'utilisation des limites d'abonnement.

```
☺  you@example.com / Claude Max x20          ❯  12 │ ⛁  84k/200k │ ⁵ʰ◑ 42% ↻ 2h13 │ ⁷ʲ◔ 18%
```

- `☺` : email du compte connecté et son forfait (`Claude Pro`, `Claude Max x5`, `Claude Max x20`…), lus dans `~/.claude.json` (`oauthAccount`), relus après chaque réponse
- `❯` : messages envoyés dans la session (tapés ou via Remote Control) ; remis à zéro par `/clear`
- `⛁` : tokens du contexte actuel / taille de la fenêtre
- `⁵ʰ` : fenêtre de 5h, % utilisé + temps avant reset
- `⁷ʲ` : fenêtre hebdomadaire, % utilisé
- couleurs selon le thème : vert < 50 %, orange < 80 %, rouge au-delà (jauges `○◔◑◕●` et contexte)

Les % viennent de la dernière réponse de l'API (mis à jour à chaque réponse) ; le compte à rebours avance toutes les 30 s. Avec une clé API, ni compte ni limites d'abonnement.

Réglages en tête de `hooks/register.tsx` : `RIGHT_PAD` (marge droite du footer, pour le centrage) et `ICON_GAP` (deux espaces après une icône, car Ghostty ≥ 1.2 fait déborder les symboles sur la case vide suivante ; un seul ailleurs).

## Installation

Dans une session Claude Code (terminal) :

```
/plugin install usage-limits --marketplace mister-good-deal/claude-usage-limits
```

puis `y` pour ajouter la marketplace, et le scope **user**.
