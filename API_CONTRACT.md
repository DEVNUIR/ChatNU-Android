# ChatNU API contract

Base REST URL: `https://api.devnu.ir/`
Realtime endpoint: `wss://api.devnu.ir/realtime`

The Docker development stack exposes the API on `http://127.0.0.1:3000`.

Protected REST requests and the WebSocket handshake use:

```http
Authorization: Bearer <access-token>
```

Access tokens are not accepted in realtime query strings.

## Authentication

### `POST /auth/register`

Request: `{ username, password, displayName, deviceName, identityPublicKey? }`

Creates the account and first device. Returns user, `deviceId`, short-lived access token, rotating refresh token, lifetime and one-time recovery code.

### `POST /auth/login`

Request: `{ username, password, deviceName, identityPublicKey? }`

Creates a new device session and returns user, `deviceId`, access token and refresh token.

### `POST /auth/refresh`

Request: `{ refreshToken }`

Rotates the refresh token and returns a fresh access token. A revoked device cannot refresh.

### `POST /auth/logout`

Revokes the current device session and closes its realtime sockets.

### `POST /auth/recover`

Request: `{ username, recoveryCode, newPassword }`

Changes the password and revokes all existing devices.

## Session and devices

### `GET /session`

Returns the authenticated device ID, user ID, device name, whether an E2EE identity public key is registered, and whether a push token is registered.

### `POST /devices/identity-key`

Request: `{ identityPublicKey }`

Registers/replaces the current device public key. Private identity keys never belong in this API and remain client-side.

### `POST /devices/push-token`

Request: `{ token: string | null }`

Registers or clears the current device FCM token.

### `GET /conversations/:id/keys`

Returns active member devices that have an identity public key. Only a conversation member can call this endpoint. Android uses the result to wrap a fresh message content key independently for every active device.

## Users

- `GET /me`
- `GET /users/search?q=<query>`

## Conversations

- `GET /conversations`
- `POST /conversations/direct` with `{ username }`
- `POST /conversations/group` with `{ title, usernames[] }`
- `PATCH /conversations/:id/preferences` with `{ isPinned?, isMuted? }`
- `GET /conversations/:id/messages?before=<ISO timestamp>&limit=50`
- `POST /conversations/:id/read`

Direct conversation creation is idempotent for a user pair.

## Messages

### `POST /messages`

Request:

```json
{
  "conversationId": "...",
  "clientId": "device-generated-idempotency-id",
  "type": "TEXT",
  "ciphertext": "opaque-client-envelope",
  "nonce": "optional",
  "protocolVersion": "ChatNU-DeviceEnvelope-v2",
  "metadata": {}
}
```

The server treats `ciphertext` as opaque application data and does not decrypt it. `clientId` makes retries idempotent per sender.

For v2 Android messages, payload encryption and per-device key wrapping happen before this request. The API persists and routes the envelope but does not receive private device keys.

### `GET /sync?cursor=<ISO timestamp>&limit=200`

Returns message-created events after the cursor for conversations the user belongs to.

## Attachments

### `POST /attachments`

Multipart fields:

- `conversationId`
- `file`

Membership is required. Current Android encrypts attachment bytes before upload, so the stored file is ciphertext. The API does not perform attachment E2EE itself.

### `GET /attachments/:id/download`

Streams the stored attachment bytes after membership authorization with `Cache-Control: private, no-store`.

## WebRTC / TURN

### `GET /rtc/config`

Returns ICE server configuration. A public STUN entry can be returned without TURN. When `TURN_HOST` and `TURN_SHARED_SECRET` are configured, the response also contains short-lived TURN REST credentials derived server-side. Permanent TURN credentials are not embedded in Android.

### `GET /calls/pending`

Returns recent pending incoming call offers for the authenticated user and consumes/expires them according to the server's pending-call policy. This allows a briefly disconnected peer to receive the call context after reconnecting.

## Realtime

Connect to `/realtime` with the Authorization header. Server events include messaging/read/conversation events plus authenticated call signaling.

Message-related examples:

- `connected`
- `message.created`
- `conversation.created`
- `conversation.read`

Client-to-server WebRTC signaling messages:

- `call.offer`
- `call.answer`
- `call.ice`
- `call.end`
- `call.reject`

A call signal includes `callId`, `conversationId`, `targetUserId` and the relevant SDP/ICE fields. The server validates that both sender and target belong to the conversation before routing the signal. Signaling is not a media relay; WebRTC carries media directly or through TURN.

Redis pub/sub fans realtime events across API instances.

## Push

When FCM is configured, the server can send routing-only data notifications to active device push tokens. Push does not contain message plaintext, E2EE content keys or attachment decryption keys.

## Health

`GET /health` checks PostgreSQL and Redis connectivity.
