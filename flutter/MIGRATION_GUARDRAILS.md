# ChatNU Flutter migration guardrails

The Kotlin/Compose Android client and the Node/TypeScript server remain the product source of truth until verified Flutter parity.

## Non-destructive migration rules

- Never delete `app/`, Android Gradle files, server code, Prisma migrations, API/security documentation, or production resources as part of routine Flutter work.
- Do not replace the repository `main` branch with a clean Flutter template.
- Flutter coexists under `flutter/` while migration is in progress.
- Legacy Android compatibility code, especially crypto/history compatibility, stays available until an equivalent Flutter path is implemented, interoperability-tested, and explicitly approved for removal.
- A visual redesign may replace Compose presentation, but it must not invent server capabilities.
- Unsupported product concepts such as channels, archived chats, persistent reactions, message pinning, delivered receipts, read receipts, or group calling must remain absent or clearly unavailable until the backend contract supports them.
- Do not claim Signal Protocol, Double Ratchet, audited E2EE, anonymous metadata, or other guarantees that the current security model does not provide.

## Compatibility sources of truth

When Flutter behavior is ambiguous, inspect these before implementation:

- `API_CONTRACT.md`
- `SECURITY_MODEL.md`
- `PROJECT_STATUS.md`
- `docs/CHATNU_2026_UI_BACKEND_GAPS.md`
- `app/src/main/java/com/example/ProductionMainActivity.kt`
- `app/src/main/java/com/example/remote/`
- `app/src/main/java/com/example/crypto/DeviceE2ee.kt`
- `server/src/index.ts`
- `server/prisma/schema.prisma`

Every migration phase should keep formatter, analyzer, tests, and Android APK build green.