# ChatNU security model

## Implemented guarantees

- Passwords and recovery codes are hashed on the server with Argon2id. Plaintext passwords are not stored.
- Access tokens are short-lived JWTs. Refresh tokens are random, rotated when used, stored server-side only as SHA-256 hashes, and can be revoked per device.
- The Android client stores access and refresh tokens encrypted with an AES-GCM key generated in Android Keystore.
- Conversation membership is checked before message history, message submission, read receipts, attachment upload, and attachment download.
- The server stores the message `ciphertext` field as an opaque envelope and does not decrypt it.
- PostgreSQL, Redis and MinIO are internal Docker services by default. Only the API port is intended for public reverse-proxy exposure.
- Production deployment requires HTTPS/WSS in front of the API.

## Important limitation: E2EE is NOT complete yet

The original Android `CryptoEngine` is a simulation. It Base64-encodes plaintext inside an `ENC_GCM[...]` marker and is reversible without a secret key. It is not AES-GCM, Signal Protocol, X3DH, Double Ratchet, or audited end-to-end encryption.

Therefore the current branch must not claim production-grade Signal-compatible E2EE. The backend has been designed so a future real client-side encryption layer can send opaque envelopes without a server schema rewrite, but the existing client crypto must be replaced before making an E2EE security claim.

A production E2EE milestone should use a maintained, reviewed Signal/libsignal-compatible implementation, maintain independent identity and pre-key material per device, implement safety-number verification, encrypted attachment keys, group sender-key semantics, key-change warnings, replay protections, and migration/versioning tests.

## Metadata visible to the server

Even after real E2EE is added, this architecture exposes routing metadata including user IDs, conversation membership, timestamps, device/session metadata, message sizes/types and attachment metadata unless separately redesigned to hide them.

## Calls

The current Android call UI/state machine is still simulated. LiveKit/TURN are not yet wired into the production client. Do not represent voice/video calls as production-ready secure calls until RTC authentication, media encryption assumptions, NAT traversal and abuse controls are implemented and tested.

## Operational requirements

Before public deployment:

1. Replace every sample secret in `.env`.
2. Terminate TLS with Nginx/Caddy and expose only HTTPS/WSS.
3. Do not publish PostgreSQL, Redis, MinIO API or MinIO console ports.
4. Restrict `CORS_ORIGIN` when a browser client is introduced.
5. Back up PostgreSQL and MinIO data and test restores.
6. Add monitoring, structured logs, rate-limit tuning and alerting.
7. Replace the simulated `CryptoEngine` before advertising E2EE.
