# ChatNU - Security Model

## 1. Principles
- **End-to-End Encryption By Default**: All private chat messages, group messages, voice notes, attachments, live locations, and call media are encrypted on the sender's device before transmission.
- **Zero Plaintext Visibility**: The `devnu.ir` servers act purely as opaque relay nodes. Servers store only encrypted ciphertext envelopes and metadata required for routing.
- **Android Keystore Protection**: Local private identity keys and DB encryption passphrases are wrapped inside Android Keystore.

## 2. Authentication & Keys
- **No Phone/Email Required**: Users register with unique username and argon2id salted hashed passwords.
- **Recovery Codes**: During setup, a 16-character cryptographic recovery code is generated. If lost, account recovery is impossible without local key backups.
- **Multi-Device Linkage**: Each device generates an independent identity key pair. Identity changes trigger safety number alerts across contacts.

## 3. Media & View-Once Protection
- **View-Once Content**: Rendered with `FLAG_SECURE` to prevent native screenshots/screen recordings. Ciphertext is purged immediately after decryption and viewing.
