# Le seau à jetons

Un seau partagé : 60 jetons par minute, remplis au fil de l'eau, jamais au-delà de la capacité.

```carte
couloir entree Entrée
couloir traitement Traitement
bande cote À côté
client entree 2 Client::prevision | prend un jeton
seau traitement 2 stockage ajouté @limiteur Seau | partagé, Arc<Mutex<Seau>> > limiteur-seau
quota entree 3 fichier LANTERNE_QUOTA | 60 par défaut
tests cote 2 ajouté @limiteur Tests du seau | 3 tests > limiteur-tests
client -> seau prend
quota ..> seau règle
tests -> seau vérifient
```
