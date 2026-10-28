# Le quota

`LANTERNE_QUOTA` règle le seau : 60 appels par minute si la variable manque.

```carte
couloir entree Entrée
couloir traitement Traitement
couloir sortie Sortie
env entree 2 fichier ajouté @config LANTERNE_QUOTA | variable d'environnement
config traitement 2 modifié @config Config::lire | quota, 60 par défaut > config-diff
seau sortie 2 stockage Seau | capacité = quota
env -> config lit
config -> seau règle
```
