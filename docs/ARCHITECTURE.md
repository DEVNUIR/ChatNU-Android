# Architecture

## Product principles

1. Identity is local-first and must not depend on a phone number.
2. Relay nodes transport opaque encrypted envelopes.
3. The UI stays responsive while offline and synchronizes when a node becomes reachable.
4. Security state is visible without turning every screen into a cybersecurity control panel.
5. Android behavior remains native even when the visual language borrows from iOS.

## Client layers

```text
UI / Compose screens
        ↓
Feature state holders
        ↓
Repository interfaces
        ↓
Local encrypted storage + sync engine
        ↓
REST API + WebSocket relay
```

The initial rebuild keeps a single Gradle module to reduce ceremony while the product surface is still moving. Packages already follow feature and core boundaries, allowing later extraction into modules without rewriting navigation or models.

## Recommended next technical phase

- Replace `DemoChatRepository` with repository interfaces and implementations.
- Add Room 2.8.x and SQLCipher-compatible encrypted storage.
- Add a foreground-safe WebSocket connection manager with exponential backoff.
- Implement cursor-based sync and idempotent message inserts.
- Add a vetted Signal Protocol implementation rather than home-grown cryptography.
- Add attachment encryption before upload and streaming decryption after download.
- Add testable node health scoring, failover, and trust pinning.
