---
name: carte
description: "Faire relire à l'humain un sujet trop gros pour une page (une MR, une architecture, un dossier) sur une carte à zoom sémantique, dans le navigateur à droite de son terminal : une bulle par fichier markdown, chaque étage tient dans un écran, un clic zoome dans une bulle. Utiliser pour qu'il relise une MR entière sans jamais scroller."
---

# Faire relire une carte à zoom sémantique

Une page longue se lit en scrollant, et l'on s'y perd. Une carte se lit en zoomant : chaque étage tient dans un
écran, et l'humain choisit où descendre. Le rendu et les transitions suivent ceux de
[Zumly](https://github.com/zumerlab/zumly), réécrits à la main : la vue parente reste derrière, floutée, cadrée sur la
tuile d'où l'on vient.

```bash
"<dossier de la skill>/carte.sh" <dossier> "MR !42 · le limiteur"
```

- Le dossier contient une bulle par fichier `.md`, et `index.md` pour la racine. `exemple/` montre une MR inventée.
- La page est écrite dans `/tmp/claude-<uid>/montrer/`, et le script affiche son chemin.
  Thème Nord de `../lire/nord.css`.
- Seuls `marked`, `highlight.js` et `mermaid` (pour un bloc ` ```mermaid `) viennent d'un CDN, en versions figées.
- Lieutenant dans un autre workspace que l'humain : écris la page, puis envoie son chemin au coordinateur, qui l'ouvre.

## Une bulle

```markdown
# Le limiteur à seau

Le résumé : une phrase, vue sur la tuile du parent.

Le corps, vu quand on zoome : texte, liste, schéma ou bloc ```diff.

enfants: limiteur-seau limiteur-tests
```

Les enfants sont des noms de fichiers sans `.md`, 7 au plus. Une bulle sans enfants est une feuille : son corps prend
tout l'écran.

## Naviguer

- **1 à 7**, ou les flèches puis **Entrée** : zoomer dans une tuile. Un clic aussi.
- **Échap** ou **Retour arrière** : remonter. Un clic sur le fil d'Ariane, ou hors des cadres, aussi.
- **← →** sur une feuille : la bulle voisine du même parent, sans remonter. On relit une MR feuille après feuille.
- Le hash garde l'étage (`#index/limiteur/limiteur-seau`) : un rechargement y revient.

## La règle de l'écran

Jamais de scroll dans une bulle. Un cadre qui déborde passe en rouge et dit de combien (`+48 px ↓`) ; le fil d'Ariane
compte les cadres qui débordent, ou affiche « ✓ tout tient ». Un cadre rouge se corrige dans le contenu, en coupant
ou en raccourcissant, jamais dans la page. Le compteur ne juge que l'étage affiché : avant d'envoyer la carte, ouvre
chaque étage par son hash, à la taille du pane de l'humain (1200x900 par défaut).

Les budgets, à 1200x900 :
- une tuile : un titre court et un résumé de 3 lignes au plus (environ 80 caractères) ;
- un corps de nœud, résumé compris : 12 lignes au plus, moins quand il a 7 tuiles ;
- une feuille de diff : environ 30 lignes de diff, à 120 colonnes. Une ligne plus longue se replie et coûte une ligne.

## Une MR en trois étages

1. **La fiche** (`index.md`) : ce qui change pour la personne, les points délicats, les preuves (tests rejoués ou non).
   Ses enfants sont les composants.
2. **Les composants** : un par sujet, pas par fichier (le consentement, la migration, le contrat IPC, la doc). Ce qui
   n'est que renommage va dans un composant « retouches mécaniques », pour que l'humain le survole.
3. **Les feuilles** : le diff coloré, en blocs ` ```diff `. Une ligne `=== chemin/du/fichier` ouvre chaque fichier.
   Le résumé dit ce que montre le morceau, en une phrase.

**Couper le diff.** Une feuille ne coupe qu'entre deux hunks, ou, dans un long hunk, à une ligne vide : jamais au milieu
d'une fonction. Remplis une feuille avant d'en ouvrir une autre. Un composant qui a plus de 7 feuilles reçoit des nœuds
de groupe (tests repris, tests nouveaux), chacun avec ses 7 feuilles au plus. Chaque ligne du diff est sur une feuille,
et sur une seule : l'humain doit pouvoir relire toute la MR depuis la carte.

## Règles

- La carte vit dans le scratchpad. Le code d'un projet privé n'entre jamais dans un dépôt public.
- Pour un seul document : skill `lire`. Pour des images : skill `montrer`.
