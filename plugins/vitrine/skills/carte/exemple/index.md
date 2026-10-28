# MR !42 · Lanterne : limiter les appels à l'API météo

Un tableau de bord qui dépasse 60 appels par minute attend son tour au lieu d'afficher « service indisponible ».
Écart : le quota se règle par `LANTERNE_QUOTA`.
Preuves : `cargo test` vert (3 tests nouveaux), essai de charge sans 429.

```carte
couloir avant Avant
couloir pendant Ce que la MR ajoute
couloir apres Après
tab avant 2-3 écran @client 10 tableaux de bord | rafraîchis en même temps > composants
err avant 5 écran retiré « service indisponible » | erreur 429 au-delà de 60 appels/min > composants
regle pendant 1 règle @limiteur sans jeton, l'appel attend > composants
seau pendant 2-4 entonnoir ajouté @limiteur Seau à jetons | 60 jetons par minute > composants
quota pendant 5 fichier ajouté @config LANTERNE_QUOTA | 60 par défaut > composants
prev apres 2-3 écran ajouté @client Prévisions servies | attente < 2 s au 95ᵉ centile > composants
zero apres 5 ajouté @limiteur Essai de charge | 600 appels en 10 min, 0 × 429 > composants
tab -> err affichaient
tab -> seau appellent
regle ..> seau contraint
quota ..> seau règle
seau -> prev laisse passer
zero ..> prev mesure
```
