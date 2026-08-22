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

## Run locally on Android

With an emulator or device available, run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_android.ps1
```

Choose a specific device with `-Device <device-id>`. Both launch helpers pass
the ignored local configuration through `--dart-define-from-file`; running
plain `flutter run` does not load that file.

For a configured Android build, use:

```powershell
powershell -ExecutionPolicy Bypass -File tools/build_android.ps1 -Release
```
