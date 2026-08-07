# Known issues

## Android build environment

`flutter build apk --debug` is currently blocked before compilation because the
machine-level Flutter setting `jdk-dir` points to the nonexistent
`C:\Program Files\Java\jdk-17`. The Oracle Java launcher found on PATH also exits
abnormally, so it cannot serve as a fallback Gradle runtime.

Install or select a valid JDK 17, then run:

```text
flutter config --jdk-dir "<valid-jdk-17-directory>"
flutter build apk --debug --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<public-key>
```

This is a workstation tooling blocker, not a reported application compile
error. `flutter analyze` reports zero errors and `flutter test` passes.

## Controlled authentication proof

The production auth endpoint and invalid-login behavior are verified. A valid
login, persisted-session restart, and authenticated profile RPC still require a
legitimate non-destructive QA account; none is stored in either repository.
