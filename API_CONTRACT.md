# ChatNU - OpenAPI & AsyncAPI Specification Contract

Backend Service: `https://api.devnu.ir`
WebSocket Gateway: `wss://api.devnu.ir/realtime`

## REST Endpoints Summary

### Auth (`/auth`)
- `POST /auth/register`: `{ username, passwordHash, displayName, identityKey }` -> `{ token, refreshToken, userId }`
- `POST /auth/login`: `{ username, passwordHash, deviceName }` -> `{ token, refreshToken, user }`
- `POST /auth/recover`: `{ username, recoveryCode, newPasswordHash }` -> `{ status }`

### Conversations & Messages (`/conversations`, `/messages`)
- `GET /conversations`: List active encrypted chats.
- `POST /conversations/direct`: Create or fetch direct conversation.
- `POST /messages`: `{ conversationId, recipientDeviceId, ciphertextEnvelope, nonce }`
- `GET /sync?cursor={cursor}`: Fetch unread encrypted event logs.

### Keys & Pre-keys (`/keys`)
- `POST /keys/prekeys`: Upload signed prekey bundle.
- `GET /keys/bundle/{username}`: Fetch user prekey bundle for ratchet init.

### Attachments (`/attachments`)
- `POST /attachments/upload`: Upload encrypted payload byte stream.
- `GET /attachments/{id}/download`: Get temporary signed URL for encrypted media.
