# ChatNU

ChatNU is now a Flutter-first application.

The legacy Android/Compose client and its tracked Gradle project have been removed. Flutter source lives at the repository root. The Android host is generated when needed by `tool/bootstrap_android.sh`, which also installs the ChatNU launcher icon and app label.

## App

- Flutter 3.44+
- Riverpod state management
- go_router navigation
- responsive phone/tablet/desktop layout
- English/Persian and RTL/LTR foundations
- Liquid Glass visual system

## Android build

```bash
./tool/bootstrap_android.sh
flutter test
flutter build apk --release
```

The generated `android/` directory is intentionally ignored so no legacy Android Gradle project is kept in source control.

GitHub Actions builds `ChatNU-release.apk` on pushes to `main` and uploads it as the `ChatNU-Android-APK` artifact.

## Backend

The existing production backend remains under `server/`. Its API/security contracts are preserved in `API_CONTRACT.md` and `SECURITY_MODEL.md` for the next Flutter integration phases.
