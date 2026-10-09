# usage-limits

Mod Claude Code : affiche à droite du footer l'utilisation des limites d'abonnement.

```
⁵ʰ◑ 42% ↻ 2h13 │ ⁷ʲ◔ 18%
```

- `⁵ʰ` : fenêtre de 5h, % utilisé + temps avant reset
- `⁷ʲ` : fenêtre hebdomadaire, % utilisé
- jauge `○◔◑◕●` colorée selon le thème : vert < 50 %, orange < 80 %, rouge au-delà

Les % viennent de la dernière réponse de l'API (mis à jour à chaque réponse) ; le compte à rebours avance toutes les 30 s. Rien ne s'affiche avec une clé API (pas de limites d'abonnement).

## Installation

Dans une session Claude Code (terminal) :

```
/plugin install usage-limits --marketplace mister-good-deal/claude-usage-limits
```

puis `y` pour ajouter la marketplace, et le scope **user**.
