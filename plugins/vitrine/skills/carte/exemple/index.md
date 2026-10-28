# MR !42 · Lanterne : limiter les appels à l'API météo

Les prévisions ne tombent plus en erreur 429 quand dix tableaux de bord se rafraîchissent en même temps.

**Pour l'utilisateur.** Un tableau de bord qui dépasse 60 appels par minute attend son tour au lieu d'afficher
« service indisponible ». L'attente reste sous 2 s au 95ᵉ centile.

**Écarts.** Aucun avec l'issue. Le quota se règle par `LANTERNE_QUOTA`, que l'issue ne demandait pas.

**Preuves.** `cargo test` est vert (14 tests, dont 3 nouveaux). L'essai de charge passe 600 appels en 10 min, sans 429.

enfants: limiteur client config
