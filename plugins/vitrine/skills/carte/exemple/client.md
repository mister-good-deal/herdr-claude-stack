# Le client météo

Chaque appel prend un jeton avant de partir, et dort s'il le faut.

Le client garde un `Arc<Mutex<Seau>>` : tous les tableaux de bord du processus partagent le même seau.

enfants: client-diff
