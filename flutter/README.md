# ChatNU Flutter migration

This directory is the staged Flutter replacement for the Android presentation layer. The existing Kotlin/Compose application and server remain intact and authoritative while Flutter reaches feature parity.

## Current migration scope

Phase 1 established the reusable Flutter foundation: Riverpod, go_router, theme tokens, responsive breakpoints, restrained Liquid Glass surfaces, dark/light themes and English/Persian locale support.

Phase 2 corrects the product layer so Flutter represents the real ChatNU messenger rather than an AI-chat prototype. The active Flutter shell now contains:

- Chats / Contacts / Settings messenger navigation
- responsive phone, tablet and desktop layouts
- direct and group conversation concepts
- avatars, unread counts, pinned/muted state and conversation filters
- messenger message bubbles with mixed Persian/English text direction handling
- truthful delivery-state rendering that does not fabricate delivered/read receipts
- a multiline messenger composer
- attachment and one-to-one call affordances that are explicitly local UI only until their production services are ported
- English/Persian localization seeds
- an explicit backend-capability boundary preventing unsupported features from appearing as real

Backend authentication, REST, E2EE, realtime, encrypted attachment transfer, FCM and WebRTC are intentionally **not connected to Flutter yet**. The Android implementation and backend contracts remain the source of truth for those phases.

See `MIGRATION_GUARDRAILS.md` before changing production Android/server code.

## Local bootstrap

With Flutter 3.44+ installed:

```bash
cd flutter
./tool/bootstrap_android.sh
flutter run
```

The bootstrap script generates only missing Android platform boilerplate in a temporary directory and copies it into this Flutter workspace. It does not overwrite the hand-authored Flutter project or the existing Kotlin application.
