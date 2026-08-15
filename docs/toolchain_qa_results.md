# Toolchain and Chrome QA results

Date: 2026-08-15

## Windows Android toolchain

- Installed Microsoft OpenJDK `17.0.20.8`.
- Configured Flutter JDK: `C:\Program Files\Microsoft\jdk-17.0.20.8-hotspot`.
- Installed official Android command-line tools `15859902`.
- Verified archive SHA-256:
  `90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a`.
- Accepted Android SDK licenses.
- `flutter doctor -v`: PASS, no issues.
- `flutter build apk --debug --target-platform android-arm64`: PASS.
- Artifact: `build/app/outputs/flutter-apk/app-debug.apk`.

## Flutter checks

- `flutter analyze`: PASS with zero errors; 28 existing warnings/info notices.
- `flutter test`: PASS, 1 test.
- Public production event feed rendered successfully in Flutter Chrome.

## Chrome DevTools verification

Flutter 3.41 no longer accepts `--web-renderer canvaskit`; the app was launched
with the current default renderer instead. Codex attached to Flutter's Chrome
instance over its local Chrome DevTools Protocol endpoint.

Verified:

- Home loaded a production Future Times event and image.
- Home and Profile navigation worked.
- Debug QA profile rendered as `Future Times QA`.
- Profile route and QA session survived a full browser reload.
- Browser console errors: none.
- Page exceptions: none after the responsive-card correction.
- Failed network requests: none.

The first narrow split-window pass exposed a 10-pixel event-card overflow at a
242-pixel viewport. Home now applies a taller card aspect ratio below 320 pixels;
the restarted Flutter runtime produced no rendering exceptions.

The `chrome-devtools-mcp` package was not installed or exposed as a connector.
Verification used the available Playwright client attached directly to Flutter's
Chrome DevTools endpoint, providing the same CDP console, network, navigation,
reload, viewport, and screenshot checks.
