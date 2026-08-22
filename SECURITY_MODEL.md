# ChatNU security model

## Implemented guarantees

- Passwords and recovery codes are hashed on the server with Argon2id. Plaintext passwords are not stored.
- Access tokens are short-lived JWTs. Refresh tokens are random, rotated when used, stored server-side only as SHA-256 hashes, and can be revoked per device.
- Realtime WebSocket authentication uses the `Authorization` header instead of putting access tokens in URLs/query strings.
- Logout revokes the current device and closes local realtime sockets for that device. Account recovery revokes every device and closes local account sockets.
- The Android client stores access and refresh tokens encrypted with an AES-GCM key generated in Android Keystore, and Android application backup is disabled.
- Conversation membership is checked before message history, message submission, read receipts, attachment upload and attachment download.
- The server stores the message `ciphertext` field as an opaque envelope and does not decrypt it.
- Attachment bytes are stored on a private persistent server volume and are streamed only through authenticated API routes. No filesystem/object-store address is exposed to clients.
- PostgreSQL and Redis are internal Docker services. The API is bound to host loopback by default and is intended to be exposed only through a TLS reverse proxy.
- Production database changes use committed Prisma migrations.

## Important limitation: E2EE is NOT complete yet

The original Android `CryptoEngine` is a simulation. It Base64-encodes plaintext inside an `ENC_GCM[...]` marker and is reversible without a secret key. It is not AES-GCM, Signal Protocol, X3DH, Double Ratchet, or audited end-to-end encryption.

Therefore the current branch must not claim production-grade Signal-compatible E2EE. The backend is structured so a future real client-side encryption layer can send opaque envelopes and encrypted attachment bytes without a server schema rewrite, but the existing client crypto must be replaced before making an E2EE security claim.

A production E2EE milestone should use a maintained, reviewed Signal/libsignal-compatible implementation, maintain independent identity and pre-key material per device, implement safety-number verification, encrypted attachment keys, group sender-key semantics, key-change warnings, replay protections, and migration/versioning tests.

## Metadata visible to the server

Even after real E2EE is added, this architecture exposes routing metadata including user IDs, conversation membership, timestamps, device/session metadata, message sizes/types and attachment metadata unless separately redesigned to hide them.

## Calls

The current Android call UI/state machine is still simulated. No production RTC backend is wired into the client. Do not represent voice/video calls as production-ready secure calls until RTC authentication, media-encryption assumptions, NAT traversal and abuse controls are implemented and tested.

## Operational requirements

Before public deployment:

1. Use the generated strong `.env` secrets or replace sample values with cryptographically random values.
2. Terminate TLS with Nginx/Caddy and expose only HTTPS/WSS.
3. Keep PostgreSQL and Redis off public interfaces; keep the API bound to loopback behind the reverse proxy.
4. Restrict `CORS_ORIGIN` when a browser client is introduced.
5. Back up PostgreSQL and the attachment volume and test restores.
6. Add monitoring, structured logs, rate-limit tuning and alerting.
7. Keep dependencies and base images patched and review security advisories before upgrades.
8. Replace the simulated `CryptoEngine` before advertising E2EE.
