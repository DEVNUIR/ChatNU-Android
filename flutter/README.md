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

## Reference-led messenger UI architecture

The UI uses Riverpod, `go_router`, feature-first presentation code, and centralized theme/design tokens. Its visual direction is deliberately closer to a focused modern messenger than a showcase design system: quiet content surfaces, compact radii, restrained black/yellow emphasis, native-feeling sheets, and strong spacing with depth concentrated in navigation and conversation chrome.

- the primary conversation list uses lightweight flat rows with circular avatars, compact metadata and yellow unread badges
- recent direct conversations form a small horizontal people strip rather than decorative cards
- phone navigation keeps a central black New Chat action and minimal surrounding navigation
- outgoing messages use the ChatNU yellow accent while incoming messages remain neutral and quiet
- message and conversation context surfaces use simple bottom sheets rather than visually heavy cards
- registration is a true staged onboarding journey: welcome → display name → username → security → review → recovery-code handoff
- login and account recovery remain separate focused journeys instead of modes inside one overloaded form
- conversation rows and message bubbles do not use backdrop blur
- phone, tablet and desktop layouts are composed deliberately rather than stretching one layout
- English and Persian layouts use directional APIs and support LTR/RTL text flow
- reduced-motion preferences are respected by custom transitions and microinteractions

The current polish layer adds selective depth without returning to the earlier glass-everywhere presentation:

- frosted conversation headers and phone/desktop navigation chrome
- smooth eased fade/slide pane transitions with reduced-motion fallbacks
- an animated palette-aware chat wallpaper isolated behind a repaint boundary
- a richer real-user profile/settings hub with account/server context, chat/media information, privacy/security, Getting Started, FAQ and About
- persistent System/English/فارسی locale preference
- About explicitly credits `Developed by devnu.ir`
- a versioned, HTTPS-only `chatnu://server/add` provisioning parser suitable for future QR and app-link enrollment; secrets are forbidden from provisioning payloads

Reusable primitives remain centralized, but a component is used only where it improves product consistency; the interface should not expose the design system for its own sake.

## Rich media and location direction

The server and Flutter message mapper already support typed `IMAGE`, `VIDEO`, `VOICE`, `FILE`, `LOCATION` and `LIVE_LOCATION` messages, and attachment bytes are encrypted before upload. Capture, playback, gallery, map and location-session UX should extend that existing encrypted transport rather than introduce a plaintext or parallel media channel.

Group video calling is a separate protocol concern: current call signaling is one-to-one and targets a single user. A group-call UI must not ship until multiparty signaling/media semantics are defined.

Profile editing and true multi-account switching are also intentionally gated on production semantics. The database can represent avatar/bio, but the current public REST contract does not expose authenticated profile writes; the Flutter credential/session vault currently owns one active account. The client must not simulate those features with local-only state.

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
