# Known issues

## Resolved Android build environment issue

The stale Flutter JDK path was repaired on 2026-08-15 by installing Microsoft
OpenJDK 17 and configuring Flutter to use it. The official Android command-line
tools were installed with their published SHA-256 checksum verified, and all
SDK licenses were accepted. `flutter doctor -v` now reports no issues and the
ARM64 debug APK builds successfully.

## Controlled authentication proof

The production auth endpoint and invalid-login behavior are verified. A valid
login, persisted-session restart, and authenticated profile RPC still require a
legitimate non-destructive QA account; none is stored in either repository.
