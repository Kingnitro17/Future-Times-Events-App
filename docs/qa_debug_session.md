# Debug-only QA session

The Flutter app supports a local authenticated UI session for browser and
widget verification without creating or mutating a production Supabase user.

Enable it only in a debug run:

```text
flutter run -d chrome --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<public-key> --dart-define=QA_MOCK_AUTH=true
```

The override:

- is gated by both `kDebugMode` and the compile-time `QA_MOCK_AUTH` flag;
- does not write a password, access token, refresh token, or production user;
- provides a deterministic attendee profile for UI navigation;
- cannot activate in profile or release builds, even if the flag is supplied;
- leaves normal production authentication as the default.

This verifies authenticated UI behavior only. It does not replace controlled
integration testing of real password login, session refresh, RLS, or the
`get_my_profile` RPC with a legitimate QA account.
