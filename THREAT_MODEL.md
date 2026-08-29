# ChatNU - Threat Model

| Threat | Risk Level | Mitigation in ChatNU |
|---|---|---|
| **Malicious Server / Compromised API** | Medium | E2EE via Signal-like Double Ratchet. Server only sees opaque ciphertext. Media server cannot decrypt call audio/video. |
| **Network Man-In-The-Middle (MITM)** | High | TLS 1.3 pinning for `devnu.ir`, AES-256-GCM message encryption, Safety Number QR verification. |
| **Physical Device Theft (Locked)** | Medium | SQLCipher/AES local database encryption key tied to Android Keystore & biometric/PIN lock. |
| **Screen Capture / Spyware** | Medium | `FLAG_SECURE` enabled on View-Once media viewers. Sensitive UI previews hidden in Android Recent Apps overview. |
| **Replay Attacks** | High | Monotonically increasing ratchet sequence numbers & per-message nonces. |
| **Mass Username Enumeration** | Low | Strict rate limiting on search queries with anti-enumeration response delays. |
