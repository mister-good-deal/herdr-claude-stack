# `src/client.rs`

L'appel attend son jeton, hors du verrou.

```diff
 pub struct Client {
     http: reqwest::Client,
+    seau: Arc<Mutex<Seau>>,
 }

 impl Client {
     pub async fn prevision(&self, ville: &str) -> Result<Prevision> {
+        let attente = self.seau.lock().unwrap().prendre();
+        if !attente.is_zero() {
+            tokio::time::sleep(attente).await;
+        }
         let url = format!("{API}/prevision?ville={ville}");
         Ok(self.http.get(url).send().await?.json().await?)
     }
```
