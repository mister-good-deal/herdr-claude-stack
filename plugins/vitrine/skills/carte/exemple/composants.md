# Les composants

Le client prend un jeton avant chaque appel ; le seau est partagé par tous les tableaux de bord du processus.

```carte
couloir entree Entrée
couloir traitement Traitement
couloir sortie Sortie
bande cote À côté
env entree 1 fichier ajouté @config LANTERNE_QUOTA | variable d'environnement
tab entree 2 écran @client Tableaux de bord | dix, rafraîchis ensemble
config traitement 1 modifié @config Config::lire | quota, 60 par défaut > config-diff
client traitement 2 modifié @client Client::prevision | attend son jeton, hors du verrou > client-diff
seau traitement 3 stockage ajouté @limiteur Seau | partagé, Arc<Mutex<Seau>> > limiteur-seau
api sortie 2 API météo | /prevision
tests cote 2 ajouté @limiteur Tests du seau | 3 tests > limiteur-tests
env -> config lit
tab -> client appelle
config -> client règle le quota
client -> seau prend un jeton
client -> api appelle
tests -> seau vérifient
```
