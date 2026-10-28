# `src/config.rs`

```diff
 pub struct Config {
     pub api_cle: String,
+    pub quota: u32,
 }

 pub fn lire() -> Result<Config> {
     Ok(Config {
         api_cle: env::var("LANTERNE_CLE")?,
+        quota: env::var("LANTERNE_QUOTA").ok().and_then(|q| q.parse().ok()).unwrap_or(60),
     })
 }
```
