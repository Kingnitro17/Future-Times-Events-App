# Future Times Events

## Run locally in Chrome

Chrome is a QA target; Android remains the product target.

1. Copy `config/app_config.example.json` to
   `config/app_config.local.json`.
2. Put your Supabase project URL in `SUPABASE_URL`.
3. Put your public anonymous/publishable key in `SUPABASE_ANON_KEY`.
   Never use the Supabase service-role key in this app.
4. Run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File tools/run_chrome.ps1
   ```

The local file is ignored by Git. The runner uses a stable URL:
`http://localhost:7357`. It starts an optimized release-mode web build by
default, avoiding Flutter's slow debug module loader. For debugging only, run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_chrome.ps1 -Debug
```

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
