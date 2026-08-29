# ChatNU Flutter client

This directory contains the staged Flutter replacement for the ChatNU Android presentation layer. The existing Kotlin/Compose application, server implementation, `API_CONTRACT.md`, and `SECURITY_MODEL.md` remain intact and authoritative while Flutter reaches full product parity.

The Flutter client is a private messenger. It is not an AI-chat product and must not introduce model selectors, assistant personas, prompt-oriented UI, or fabricated backend capabilities.

## Current production integration

The production Flutter path is wired to the real ChatNU services and security model:

- bearer-authenticated REST with refresh-token rotation
- secure credential persistence
- per-device E2EE identity registration
- ChatNU Device Envelope v2 message encryption/decryption
- stable client IDs for optimistic sends and retry reconciliation
- authenticated realtime WebSocket events
- conversation pin, mute, read-state and ordering updates
- server-backed user search, direct chats and group creation
- encrypted attachment upload/download
- one-to-one WebRTC audio/video signaling and media
- offline-session handling without replacing server truth with mock repositories

Demo fixtures remain available only behind the explicit `ChatNuAppMode.demo` override used by widget tests and local visual development. Production is the default mode.

The Flutter transport intentionally refuses emergency custom-CA endpoints until native certificate-pin verification reaches parity with the Android reference client. This is a deliberate security boundary, not a UI limitation to bypass.

See `FEATURE_PARITY.md` for the audited capability matrix and unsupported features that must not be faked.

## 2026 Liquid Glass UI architecture

The UI rebuild uses Riverpod, `go_router`, feature-first presentation code, centralized theme/design tokens, and reusable glass primitives. The visual hierarchy is intentionally selective:

- blur is reserved for navigation chrome, headers, composer surfaces, sheets/dialogs and call controls
- conversation rows and message bubbles do not use backdrop blur
- scrolling rows use lightweight paint and repaint isolation where useful
- phone, tablet and desktop layouts are composed deliberately rather than stretching one layout
- English and Persian layouts use directional APIs and support LTR/RTL text flow
- appearance settings persist System/Light/Dark mode plus Full/Balanced/Reduced glass quality
- reduced-motion preferences are respected by custom transitions and microinteractions

Core shared UI lives under `lib/core/glass`, `lib/core/theme`, and focused feature widgets rather than repeated `BackdropFilter` decoration in individual screens.

## Product identity

The generated Flutter Android host must preserve:

- application ID: `ir.devnu.chatnu`
- application label: `ChatNU`
- official ChatNU launcher icon/mark

The migration CI verifies these before analysis, tests, or release packaging.

## Local bootstrap and verification

With Flutter 3.44+ installed:

```bash
cd flutter
./tool/bootstrap_android.sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
flutter build apk --release
```

The bootstrap script generates only missing Flutter Android host boilerplate in a temporary directory and copies it into this Flutter workspace. It does not overwrite the hand-authored Flutter project or delete/replace the existing Kotlin application.

The release workflow verifies the resulting APK signature. When production signing secrets are unavailable, the CI artifact is explicitly recorded as fallback-signed and must not be represented as a production-signed in-place upgrade build.
