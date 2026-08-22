# ChatNU API contract

Base REST URL: `https://api.devnu.ir/`
Realtime endpoint: `wss://api.devnu.ir/realtime`

The Docker development stack exposes the REST API on `http://127.0.0.1:3000`.

All protected REST requests use:

```http
Authorization: Bearer <access-token>
```

The WebSocket upgrade uses the same Authorization header. Access tokens are intentionally not accepted in the realtime query string.

## Authentication

### `POST /auth/register`
Request: `{ username, password, displayName, deviceName, identityPublicKey? }`

Returns the user, device ID, short-lived access token, rotating refresh token, token lifetime, and a one-time recovery code. Password and recovery code are hashed server-side using Argon2id.

### `POST /auth/login`
Request: `{ username, password, deviceName, identityPublicKey? }`

Returns the user, a new device session, access token and refresh token.

### `POST /auth/refresh`
Request: `{ refreshToken }`

Rotates the refresh token and returns a fresh access token. Revoked devices cannot refresh.

### `POST /auth/logout`
Requires Bearer authentication, revokes the current device session and closes local realtime sockets for that device.

### `POST /auth/recover`
Request: `{ username, recoveryCode, newPassword }`

Resets the password, revokes all existing device sessions and closes local realtime sockets for the account.

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

Only conversation members may read/send messages or access attachments. Direct conversation creation is idempotent for a given user pair.

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
  "protocolVersion": "optional",
  "metadata": {}
}
```

The server treats `ciphertext` as opaque application data and never attempts to decrypt it. `clientId` makes retries idempotent per sender, including concurrent duplicate submissions.

### `GET /sync?cursor=<ISO timestamp>&limit=200`
Returns message-created events after the supplied cursor for conversations the user belongs to.

## Realtime

Connect to `/realtime` with an `Authorization: Bearer ...` header on the WebSocket handshake. Server events currently include:

- `connected`
- `message.created`
- `conversation.created`
- `conversation.read`

Redis pub/sub allows multiple API instances to fan out events to connected users. Session validity is checked when the WebSocket is established.

## Attachments

### `POST /attachments`
Multipart form fields:
- `conversationId`
- `file`

The server stores the uploaded bytes on a private persistent attachment volume and records metadata in PostgreSQL. Clients that promise E2EE must encrypt attachment bytes before upload.

### `GET /attachments/:id/download`
After membership authorization, the API streams the attachment bytes directly to the authenticated client with `Cache-Control: private, no-store`. Filesystem paths are never returned to clients.

## Health

`GET /health` checks PostgreSQL and Redis connectivity.
