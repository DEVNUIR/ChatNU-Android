# ChatNU security hardening roadmap

Security is a product requirement, not a UI badge. ChatNU should assume that Wi-Fi operators,
ISPs, reverse proxies, database administrators, TURN relays and even a compromised ChatNU server
may be curious or hostile. The endpoint device remains the trust anchor: if the phone itself is
unlocked, rooted or compromised by malware, no messenger can guarantee secrecy.

## What is protected today

- Public deployments are expected to use HTTPS/WSS, preventing passive network sniffing of API and signaling traffic.
- Message plaintext is encrypted on Android before it reaches the ChatNU server.
- Attachments are AES-256-GCM encrypted on-device before upload; attachment keys travel only inside the E2EE message envelope.
- One-to-one WebRTC media is protected by DTLS-SRTP; TURN forwards encrypted media and does not receive the SRTP media keys.
- Push notifications contain routing information only, not message plaintext or attachment keys.
- Private device identity keys are generated in Android Keystore and are not uploaded.

## Current limits that must stay visible

The current `ChatNU-DeviceEnvelope-v2` is not Signal Protocol, Double Ratchet or MLS and has not
received an independent cryptographic audit. It does not yet provide Signal-grade forward secrecy,
post-compromise security, deniability or a robust out-of-band safety-number workflow. The server is
also the current device-key directory, so a malicious server can attempt key substitution unless
clients independently verify identities. Metadata such as account identifiers, membership,
timestamps, IP addresses, message sizes and call routing remains visible to the relevant server.

Do not market ChatNU as "unbreakable", "anonymous", "Signal-compatible" or "impossible to intercept".
The target is: plaintext unavailable to transport/storage servers, strong passive-sniffing protection,
detectable identity changes, reviewed protocol primitives, and minimized metadata.

## P0 — before claiming high-assurance E2EE

1. Replace the custom RSA envelope with a maintained, reviewed ratcheting protocol implementation.
   Evaluate `signalapp/libsignal` carefully: it implements Double Ratchet and is used by Signal,
   but upstream states that use outside Signal is unsupported and the project is AGPLv3. Licensing,
   update cadence and operational ownership must be accepted before integration.
2. Add safety numbers / QR verification derived from long-term identity keys.
3. Persist verified peer identities locally and make unexpected identity/device-key changes explicit.
4. Block silent key substitution for previously verified peers.
5. Add replay protection, message counters/session identifiers and migration tests.
6. Define secure multi-device linking and history transfer instead of silently rewrapping old history.
7. Obtain independent security review before stronger public claims.

## P1 — local and media privacy

- Encrypt the local message database at rest with a key protected by Android Keystore.
- Add optional app lock/biometric gate without weakening the underlying E2EE keys.
- Replace whole-file attachment buffering with streaming/chunked authenticated encryption so large media does not live in RAM.
- Minimize plaintext attachment metadata on the server: store opaque object names and move original filename/MIME details into the encrypted message payload.
- Add configurable disappearing messages and best-effort decrypted-cache cleanup.
- Keep decrypted media in app-private storage and use one-time URI grants only when another app must open a file.

## P2 — groups and federation

- Use a reviewed group protocol (for example MLS or a well-reviewed sender-key design) rather than N² ad-hoc key wrapping as groups grow.
- Federation must use authenticated server identities, signed replay-resistant envelopes, explicit remote-device verification, abuse controls and version negotiation.
- Federation must never require servers to receive message plaintext or media keys.

## Calls

For one-to-one calls, DTLS-SRTP is suitable for media confidentiality even through TURN. Before group
calling, design an SFU model that preserves end-to-end media encryption and authenticated participant
keying; do not simply terminate media encryption at the SFU.

## Definition of done for a secure release

A release can make strong E2EE claims only when the protocol implementation is maintained/reviewed,
identity verification and key-change behavior are tested, server compromise does not silently expose
past message plaintext, network captures contain no plaintext message/media content, and an external
review has documented the remaining metadata and endpoint risks.
