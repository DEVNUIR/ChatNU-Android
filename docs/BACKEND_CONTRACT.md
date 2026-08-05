# Backend Contract Draft

The backend is a relay and synchronization service. It must not receive plaintext message bodies or attachment contents.

## Ports

A deployment should expose one public TLS endpoint, normally port `443`, and route internally:

```text
/api/*       -> REST service, internal port 8080
/realtime    -> WebSocket gateway, internal port 8081
```

The internal ports must be configurable through environment variables.

## REST

```http
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/keys/prekeys
GET  /api/v1/keys/bundle/{username}
GET  /api/v1/sync?cursor={cursor}
POST /api/v1/messages
POST /api/v1/attachments
GET  /api/v1/nodes
GET  /api/v1/health
```

## WebSocket

```text
wss://host/realtime
```

Events:

```json
{ "type": "envelope", "payload": { "messageId": "...", "ciphertext": "...", "nonce": "..." } }
{ "type": "typing", "conversationId": "...", "userId": "...", "typing": true }
{ "type": "receipt", "messageId": "...", "state": "delivered" }
```

Typing events should be ephemeral. Message envelopes and receipts should be persisted until acknowledged or expired by policy.
