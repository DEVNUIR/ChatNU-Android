# ChatNU project status

## Branch goal

`feat/production-ready-chatnu` turns the original mock-heavy Android prototype into a runnable self-hosted messenger while retaining legacy/demo source only for compatibility/reference. The production launcher uses the remote client/server stack.

## Implemented

### Server

- Node.js 22 + TypeScript + Express API.
- PostgreSQL 16 + Prisma schema and versioned migrations.
- Redis realtime fan-out.
- Argon2id passwords and recovery codes.
- Short-lived JWT access tokens, rotating refresh tokens and per-device revocation.
- Registration, login, logout and account recovery.
- User search, idempotent direct conversations and group creation.
- Message persistence, pagination, sync, read receipts and idempotent submission.
- Authorization-header WebSocket realtime delivery.
- Active device public-key registry and conversation-scoped E2EE key discovery.
- Device FCM token registration and optional routing-only FCM HTTP v1 push.
- Private persistent attachment storage with membership-authorized upload/download.
- Authenticated one-to-one WebRTC signaling with offer/answer/ICE/end/reject.
- Brief pending-call delivery for reconnecting peers.
- STUN configuration plus short-lived TURN REST credentials.
- Self-hosted Coturn service in Docker Compose.
- API bound to host loopback; PostgreSQL/Redis not exposed on host ports.
- `scripts/chatnu.sh` generates DB/JWT/TURN secrets and manages the stack.

### Android

- Standard Gradle `:app` module, SDK 36, Java 17.
- Production launcher separated from legacy demo UI.
- Redesigned auth/home/conversation/settings UX.
- Retrofit/OkHttp API client and automatic access-token refresh.
- AES-GCM protected session tokens in Android Keystore; application backup disabled.
- Device RSA-3072 identity key generated in Android Keystore.
- `ChatNU-DeviceEnvelope-v2`: fresh AES-256-GCM content key per message, wrapped independently for every active member device with RSA-OAEP/SHA-256.
- New production messages use real client-side E2EE; legacy reversible crypto remains read compatibility only.
- System attachment picker for images/video/documents.
- Attachment AES-GCM encryption before upload, E2EE transfer of attachment key material, authenticated download and private-cache decryption.
- Realtime receive, conversation pinning/read receipts, direct/group creation and message history.
- Optional FCM push with routing-only payloads.
- Real one-to-one WebRTC voice/video calls with mute, camera and speaker controls.
- Local/remote video rendering.
- Android foreground service for connecting/active calls.
- TURN/STUN ICE configuration supplied by the server.
- Current version: `1.1.0`, `versionCode 3`.

### Build/release

- CI validates Prisma, audits production npm dependencies, compiles the server and runs a fresh Docker integration smoke test.
- Smoke coverage includes auth, refresh rotation, realtime, device E2EE key discovery, message idempotency, attachment authorization/download, TURN config and call signaling/pending calls.
- Android CI builds an installable debug APK.
- Release workflow supports owner-supplied signing credentials and creates signed APK + AAB, then verifies the APK signature.

## Explicit boundaries / remaining product milestones

- Device-envelope E2EE is real client-side encryption but is **not Signal Protocol, Double Ratchet or externally audited**. It does not claim Signal-grade forward secrecy, post-compromise security or deniability.
- Group voice/video calling is not implemented. A proper implementation should use an authenticated SFU.
- FCM requires a real Firebase project/service account and Android Firebase client values; without them the app still works while realtime is connected.
- Reliable TURN relay requires a public `TURN_HOST` and correctly opened/forwarded TURN + relay ports.
- Production Play/long-term APK releases require a persistent owner-controlled signing keystore. The repository intentionally does not contain one.
- Some legacy/demo-only local features such as the old reaction/group-management experiments remain in source but are not part of the production flow.

## Validation rule

The project should be treated as shippable only when the current branch's `server`, `server-smoke` and `android` CI jobs are all green. A green debug APK validates compilation/install packaging but does not substitute for real-device interoperability testing across different networks, Firebase configuration testing, TURN firewall testing or independent cryptographic review.
