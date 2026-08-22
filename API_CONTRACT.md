# ChatNU API contract

Base REST URL: `https://api.devnu.ir/`
Realtime endpoint: `wss://api.devnu.ir/realtime?token=<access-token>`

The Docker development stack exposes the REST API on `http://127.0.0.1:3000`.

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
Requires Bearer authentication and revokes the current device session.

### `POST /auth/recover`
Request: `{ username, recoveryCode, newPassword }`

Resets the password and revokes all existing device sessions.

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

Only conversation members may read/send messages or access attachments.

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

The server treats `ciphertext` as opaque application data and never attempts to decrypt it. `clientId` makes retries idempotent per sender.

### `GET /sync?cursor=<ISO timestamp>&limit=200`
Returns message-created events after the supplied cursor for conversations the user belongs to.

## Realtime

Connect to `/realtime?token=<access-token>`. Server events currently include:

- `connected`
- `message.created`
- `conversation.created`
- `conversation.read`

Redis pub/sub allows multiple API instances to fan out events to connected users.

## Attachments

### `POST /attachments`
Multipart form fields:
- `conversationId`
- `file`

The server stores the uploaded bytes in MinIO and records metadata in PostgreSQL. Clients that promise E2EE must encrypt attachment bytes before upload.

### `GET /attachments/:id/download`
Returns a short-lived presigned MinIO URL after membership authorization.

## Health

`GET /health` checks PostgreSQL and Redis connectivity.
