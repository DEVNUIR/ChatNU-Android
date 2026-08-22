# ChatNU project status

## Branch goal

`feat/production-ready-chatnu` converts the original Android UI prototype into a runnable client/server project while preserving the existing mock/demo code for reference.

## Implemented

### Server
- Node.js 22 + TypeScript API
- PostgreSQL 16 + Prisma data model and versioned migrations
- Redis realtime fan-out
- Private persistent attachment volume with authenticated API streaming
- Argon2id account passwords and recovery codes
- Short-lived JWT access tokens + rotating/revocable refresh tokens
- Registration, login, logout and account recovery
- User search
- Idempotent direct conversations and group creation
- Message persistence, pagination, idempotent submission and sync
- Read receipts
- Authenticated WebSocket realtime message events
- Local WebSocket closure on logout/account recovery
- Authorized attachment upload/download
- Docker Compose stack and `scripts/chatnu.sh`
- API bound to loopback by default for reverse-proxy deployment

### Android
- Standard Gradle `:app` module
- Production launcher activity separated from the old mock activity
- Retrofit/OkHttp remote API client
- Automatic access-token refresh
- Android Keystore-protected session-token storage
- Android application backup disabled
- Real register/login/logout flow
- Remote conversation list and message history
- Direct chat creation by username
- Group creation
- Message submission and realtime WebSocket receive
- WebSocket token sent via Authorization header, not URL query parameters
- Server-backed conversation pinning/read receipts

## Still prototype/local-only

- Existing `CryptoEngine` is simulated and **not real E2EE**.
- Voice/video call UI and state machine are simulated; no production RTC backend is wired to Android yet.
- Some legacy UI actions remain client-local: emoji reactions, pinned messages, group member administration, group profile edits and leave-group persistence.
- Media picking/upload UI is not yet connected to the backend attachment endpoint, although server upload/download is implemented.
- Push notifications for offline Android devices are not yet implemented.
- The legacy mock repositories and mock data remain in source for demo/reference but are not the production launcher path.

## Validation

GitHub Actions validates/generates Prisma, compiles the TypeScript server, starts a fresh Docker stack for auth/database/messaging smoke tests and assembles the Android debug APK. Production rollout should happen only after CI is green and the E2EE/RTC limitations above are understood.
