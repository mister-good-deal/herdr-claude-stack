# L'appel attend son jeton

Sans jeton, `Client::prevision` attend, hors du verrou : les autres appels ne restent pas bloqués derrière lui.

```carte
couloir entree Entrée
couloir traitement Traitement
couloir sortie Sortie
tab entree 2 écran @client Tableaux de bord | dix, rafraîchis ensemble
client traitement 2 modifié @client Client::prevision | attend son jeton, hors du verrou > client-diff
seau traitement 3 stockage Seau | partagé
api sortie 2 API météo | /prevision
tab -> client appelle
client -> seau prend un jeton
client -> api appelle
```
