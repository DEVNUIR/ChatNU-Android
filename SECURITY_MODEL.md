# ChatNU security model

## Implemented guarantees

- Passwords and recovery codes are hashed on the server with Argon2id. Plaintext passwords are not stored.
- Access tokens are short-lived JWTs. Refresh tokens are random, rotated when used, stored server-side only as SHA-256 hashes, and can be revoked per device.
- Realtime WebSocket authentication uses the `Authorization` header instead of putting access tokens in URLs/query strings.
- Logout revokes the current device and closes local realtime sockets for that device. Account recovery revokes every device and closes local account sockets.
- Android stores access and refresh tokens encrypted with AES-GCM using a key generated in Android Keystore. Android application backup is disabled.
- Conversation membership is checked before message history, message submission, read receipts, device-key discovery, attachment upload/download, and call signaling.
- PostgreSQL and Redis remain private Docker services. The API is bound to loopback by default and is intended to be exposed only through a TLS reverse proxy.
- Production database changes use committed Prisma migrations.

## End-to-end encrypted messages

New Android messages use the `ChatNU-DeviceEnvelope-v2` client-side envelope.

For each message:

1. The sender generates a fresh random 256-bit AES content key and a fresh GCM nonce.
2. The plaintext payload is encrypted on the Android device with AES-256-GCM.
3. The client requests active device public keys for the conversation members.
4. The AES content key is wrapped independently for each active destination device with that device's RSA-3072 public key using RSA-OAEP/SHA-256.
5. Only the encrypted payload, nonce, protocol version and wrapped per-device keys are sent to the server.
6. A receiving device selects its wrapped key by device ID, unwraps it with its private Android Keystore key, and decrypts the AES-GCM payload locally.

The server never receives the private device keys or the plaintext content key. A database dump alone is therefore insufficient to decrypt new v2 messages.

### Important E2EE boundary

This is real client-side end-to-end encryption, but it is **not Signal Protocol, X3DH, Double Ratchet, MLS, or an externally audited cryptographic protocol**. In particular, this design does not claim Signal-grade forward secrecy, post-compromise security, deniability, pre-key asynchronous session establishment, safety-number verification, or group sender-key semantics.

The old `CryptoEngine` reversible compatibility format remains only so existing legacy messages can still be displayed. New production sends do not use it. Do not describe ChatNU as Signal-compatible or audited E2EE.

A future cryptographic hardening milestone should move to a maintained, reviewed protocol implementation, add identity verification and key-change warnings, define secure history transfer to new devices, add replay protections and protocol migration tests, and obtain independent review before stronger security claims.

## Encrypted attachments

Attachments are encrypted on the Android device before upload with a fresh AES-256-GCM key and nonce. The server stores only encrypted attachment bytes on the private attachment volume.

The attachment decryption material is carried inside the encrypted message payload, not as plaintext attachment metadata on the server. On open, Android downloads the encrypted blob through the authenticated API, decrypts it into private cache, and exposes the decrypted temporary file to another app only through `FileProvider` with a temporary read grant.

The server still sees attachment routing metadata such as the attachment ID, conversation ID, owner, encrypted byte size, declared content type and file name unless those fields are separately hidden in a future metadata-minimization design.

## Push notifications

FCM is optional. When configured, the server sends routing-only data suitable for waking the app. Message plaintext, message content keys and attachment keys are never placed in the push payload.

The Android notification for an encrypted message intentionally uses generic text rather than decrypted message content. Firebase credentials and Android Firebase client configuration are deployment secrets/configuration and are not committed to the repository.

## Voice and video calls

One-to-one calls use WebRTC with authenticated signaling over the ChatNU WebSocket.

- Signaling verifies that both caller and target are members of the selected conversation.
- Offer/answer/ICE events are routed only to the intended user.
- Offline call offers can be retained briefly as pending call state and surfaced when the peer reconnects.
- WebRTC media uses DTLS-SRTP between peers.
- A self-hosted Coturn service can relay media when direct ICE connectivity fails.
- TURN credentials are generated as short-lived REST credentials from a server-side shared secret rather than embedding a permanent TURN password in the APK.
- Android runs an active-call foreground service while media is connecting/active so microphone/camera use remains explicit to the operating system.

TURN relays encrypted WebRTC media but still observes network metadata. ChatNU does not currently provide group calling; a production group-call design should use an authenticated SFU rather than naïve client mesh.

## Metadata visible to the server

E2EE does not hide all metadata. The current architecture can expose user IDs, usernames, conversation membership, device IDs, timestamps, message and attachment sizes/types, IP/network information, delivery/read activity and call signaling metadata. TURN can additionally observe relay traffic metadata.

Reducing metadata leakage requires a separate privacy architecture and is not implied by payload encryption.

## Operational requirements

Before public deployment:

1. Use strong generated `.env` secrets and keep `.env` mode `0600`.
2. Terminate API traffic with HTTPS/WSS through Nginx or Caddy.
3. Keep PostgreSQL and Redis off public interfaces; keep the API on loopback behind the reverse proxy.
4. Configure `TURN_HOST`, `TURN_SECRET` and firewall/NAT rules for the Coturn relay port range if reliable calls across restrictive NATs are required.
5. Configure FCM server credentials only on the server and Firebase client configuration only in the Android build environment when push is required.
6. Back up PostgreSQL and the encrypted attachment volume and test restores.
7. Add monitoring, structured logs, rate-limit tuning and alerting.
8. Keep dependencies and base images patched and review advisories before upgrades.
9. Use a long-lived owner-controlled Android signing keystore for production releases and preserve it permanently.
10. Do not make Signal-compatible, audited-E2EE, anonymous-metadata or group-call claims that the implementation does not provide.
