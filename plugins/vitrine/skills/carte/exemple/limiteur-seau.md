# `src/limiteur.rs` · le seau

Nouveau fichier : le seau, son remplissage et l'attente d'un jeton.

```diff
+pub struct Seau {
+    jetons: f64,
+    capacite: f64,
+    debit: f64, // jetons par seconde
+    dernier: Instant,
+}
+
+impl Seau {
+    pub fn new(par_minute: u32) -> Self {
+        let c = par_minute as f64;
+        Seau { jetons: c, capacite: c, debit: c / 60.0, dernier: Instant::now() }
+    }
+
+    fn remplir(&mut self) {
+        let dt = self.dernier.elapsed().as_secs_f64();
+        self.jetons = (self.jetons + dt * self.debit).min(self.capacite);
+        self.dernier = Instant::now();
+    }
+
+    /// Durée à attendre avant d'avoir un jeton ; zéro s'il y en a un, qui est alors pris.
+    pub fn prendre(&mut self) -> Duration {
+        self.remplir();
+        if self.jetons >= 1.0 {
+            self.jetons -= 1.0;
+            return Duration::ZERO;
+        }
+        Duration::from_secs_f64((1.0 - self.jetons) / self.debit)
+    }
+}
```
