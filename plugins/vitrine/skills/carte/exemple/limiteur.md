# Le limiteur

Un seau à jetons partagé : 60 jetons par minute, et un appel sans jeton attend le prochain.

Pourquoi un seau plutôt qu'une fenêtre fixe : il lisse les rafales du rafraîchissement synchronisé. Le seau vit dans
un `Mutex`, ce qui suffit pour 60 appels par minute.

enfants: limiteur-seau limiteur-tests
