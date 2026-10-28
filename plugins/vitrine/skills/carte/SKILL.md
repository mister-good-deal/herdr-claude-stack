---
name: carte
description: "Faire relire à l'humain un sujet trop gros pour une page (une MR, une architecture) sur une carte à zoom sémantique, dans le navigateur à droite de son terminal : des schémas en couloirs (avant, pendant, après ; puis une vue par case), un clic sur un nœud zoome jusqu'aux feuilles de diff, et chaque étage tient dans un écran. Utiliser pour qu'il relise une MR entière sans jamais scroller."
---

# Faire relire une carte à zoom sémantique

Une page longue se lit en scrollant, et l'on s'y perd. Une carte se lit en zoomant : chaque étage est un schéma qui
tient dans un écran, et l'humain clique sur le nœud où descendre. Le rendu et les transitions suivent ceux de
[Zumly](https://github.com/zumerlab/zumly), réécrits à la main : la vue parente reste derrière, floutée, cadrée sur le
nœud d'où l'on vient.

```bash
"<dossier de la skill>/carte.sh" <dossier> "MR !42 · le limiteur"
```

- Le dossier contient une bulle par fichier `.md`, et `index.md` pour la racine. `exemple/` montre une MR inventée.
- La page est écrite dans `/tmp/claude-<uid>/montrer/`, et le script affiche son chemin. Thème Nord de
  `../lire/nord.css`.
- Seuls `marked`, `highlight.js` et `mermaid` (pour un bloc ` ```mermaid ` dans une feuille) viennent d'un CDN, en
  versions figées.
- Lieutenant dans un autre workspace que l'humain : écris la page, puis envoie son chemin au coordinateur, qui l'ouvre.

## Une bulle

Une bulle qui contient un bloc ` ```carte ` est un **schéma** : son titre et son texte font un bandeau de deux lignes
au plus, et le schéma prend le reste de l'écran. Une bulle sans ce bloc est une **feuille** : son markdown prend tout
l'écran.

````markdown
# MR !42 · Lanterne : limiter les appels à l'API météo

Une phrase : ce qui change pour la personne. Les écarts et les preuves, en une ligne.

```carte
couloir avant Avant
couloir pendant Ce que la MR ajoute
couloir apres Après
tab avant 2-3 écran 10 tableaux de bord | rafraîchis en même temps
seau pendant 2-4 entonnoir ajouté @limiteur Seau à jetons | 60 jetons par minute > seau
prev apres 2-3 écran ajouté Prévisions servies | attente < 2 s au 95ᵉ centile
tab -> seau appellent
seau -> prev laisse passer
```
````

Une ligne par élément ; `//` ouvre un commentaire.

- **Couloir** : `couloir <clé> <Titre>`. Les couloirs sont des colonnes de même largeur, dans l'ordre des lignes.
- **Bande** : `bande <clé> <Titre>`. Une bande court en bas, sous toutes les colonnes ; ses positions suivent les
  colonnes du dessus.
- **Nœud** : `<id> <clé> <rangée> [nature] [statut] [~teinte] [@étiquette…] <libellé> [| fait | fait] [> cible…]`.
  - La rangée est `3`, ou `2-4` pour un nœud qui couvre plusieurs rangées. Les rangées s'alignent d'un couloir à
    l'autre : deux nœuds de même rangée se font face, et la flèche qui les relie reste droite.
  - Les mots-clés (nature, statut, teinte, étiquettes) viennent avant le libellé. `->`, `..>`, ` > ` et `|` sont
    réservés : pas dans un libellé ni dans un fait.
  - Natures : `traitement` (par défaut), `stockage`, `fichier`, `règle`, `écran`, `valeur`, `entonnoir`.
  - Statuts : `ajouté`, `modifié`, `retiré` ; sans statut, le nœud ne change pas.
  - `~1` à `~6` teinte le fond, pour grouper des nœuds d'une même famille.
  - Un fait se met après `|` : une ligne courte sous le libellé.
  - `> cible` : le clic zoome dans `cible.md`. D'autres cibles après la première prennent place juste après elle dans
    l'ordre de lecture (← →). Les enfants d'une bulle sont ses cibles, dans l'ordre des lignes. Une bulle n'a qu'un
    parent : `carte.sh` refuse une cible nommée deux fois (« cible partagée »).
  - `@étiquette` : en zoomant depuis ce nœud, les nœuds de l'étage suivant qui portent la même étiquette se surlignent.
- **Lien** : `a -> b verbe` en trait plein, `a ..> b verbe` en pointillé, pour une contrainte ou une mesure.
  `a c -> b verbe` relie plusieurs sources. Le verbe est court : il se lit sur la flèche.

Les flèches restent droites ou à angles droits. Elles tournent dans la gouttière avant le couloir visé, ou au-dessus
d'une bande. Pour qu'elles ne se croisent pas, place les nœuds liés sur la même rangée, ou dans des couloirs voisins.

## Naviguer

- **Clic** sur un nœud qui a une cible, ou **Tab** puis **Entrée** : zoomer.
- **Échap** ou **Retour arrière** : remonter. Un clic sur le fil d'Ariane, ou hors des nœuds et des cadres, aussi.
- **← →** sur une feuille : la feuille voisine du même parent, sans remonter. On relit une MR feuille après feuille.
- Le hash garde l'étage (`#index/attente/client-diff`) : un rechargement y revient.

## La règle de l'écran

Jamais de scroll. Un cadre qui déborde passe en rouge et dit de combien (`+48 px ↓`). Un nœud trop serré, ou dont le
texte dépasse, a un bord rouge. Un schéma illisible (ligne inconnue, nœud en double, nœuds superposés, lien vers un nœud
absent) devient un cadre rouge qui liste ses erreurs. Le fil d'Ariane compte les débordements, ou affiche « ✓ tout
tient ». Il ne voit pas une flèche qui traverse un nœud : regarde chaque étage.

Corrige dans le contenu, jamais dans la page : un libellé plus court, un fait de moins, moins de rangées. Le compteur ne
juge que l'étage affiché : avant d'envoyer la carte, ouvre chaque étage par son hash, à la taille du pane de l'humain
(1200x900 par défaut).

Les budgets, à 1200x900 :
- un schéma : 3 couloirs et une bande, 5 rangées, 12 nœuds environ ;
- un libellé : 30 caractères environ, et 2 faits au plus ;
- une feuille de diff : environ 30 lignes de diff, à 120 colonnes. Une ligne plus longue se replie et coûte une ligne.

## Dessiner une MR en couloirs

1. **L'étage 0** (`index.md`) dit l'avant et l'après, comme on les verrait sans lire le code. Trois couloirs :
   - **avant** : ce que la personne voyait, et ce qui n'allait pas, en `retiré` ;
   - **pendant** : ce que la MR ajoute ou change, souvent un `entonnoir` ou un `traitement`, et les `règle`s qui le
     contraignent, en pointillé ;
   - **après** : ce que la personne voit désormais, et la preuve (essai, mesure) en pointillé vers lui.
   Chaque case zoome dans **sa propre** vue, jamais dans une vue commune : deux cases, deux cibles. Une case sans
   détail à elle n'a pas de cible, et ne se clique pas.
2. **L'étage 1** : une vue par case, cadrée sur le composant qu'elle touche. Couloirs **Entrée**, **Traitement**,
   **Sortie** : le composant au centre, ses voisins de part et d'autre, sans cible. Une bande **À côté**, s'il y a
   lieu, pour ses tests, sa doc et ses retouches mécaniques (renommages), que l'humain survole. Un nœud par sujet,
   pas par fichier ; chacun zoome dans ses feuilles.
3. **L'étage 2** : les feuilles, le diff coloré en blocs ` ```diff `. Une ligne `=== chemin/du/fichier` ouvre chaque
   fichier. La phrase sous le titre dit ce que montre le morceau.

Un composant trop gros pour un étage reçoit son propre schéma (même forme que l'étage 1), qui zoome dans ses feuilles.

**Couper le diff.** Une feuille ne coupe qu'entre deux hunks, ou, dans un long hunk, à une ligne vide : jamais au milieu
d'une fonction. Remplis une feuille avant d'en ouvrir une autre. Chaque ligne du diff est sur une feuille, et sur une
seule : l'humain doit pouvoir relire toute la MR depuis la carte.

## Règles

- La carte vit dans le scratchpad. Le code d'un projet privé n'entre jamais dans un dépôt public.
- Pour un seul document : skill `lire`. Pour des images : skill `montrer`.
