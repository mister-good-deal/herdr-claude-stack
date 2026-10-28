# `src/limiteur.rs` · les tests

Trois tests : le seau plein sert sans attendre, le seau vide fait attendre, et le remplissage plafonne à la capacité.

```diff
+#[test]
+fn seau_plein_sert_sans_attendre() {
+    let mut s = Seau::new(60);
+    assert_eq!(s.prendre(), Duration::ZERO);
+}
+
+#[test]
+fn seau_vide_fait_attendre() {
+    let mut s = Seau::new(60);
+    for _ in 0..60 { s.prendre(); }
+    assert!(s.prendre() > Duration::from_millis(900));
+}
+
+#[test]
+fn remplissage_plafonne() {
+    let mut s = Seau::new(60);
+    s.dernier -= Duration::from_secs(3600);
+    s.remplir();
+    assert_eq!(s.jetons, 60.0);
+}
```
