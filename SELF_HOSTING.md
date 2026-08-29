# ChatNU self-hosting

ChatNU is designed so the Android app does not require one central ChatNU-operated server. Anyone can run an independent ChatNU instance and point the same Android app at it.

## What "decentralized" means in the current release

Each ChatNU instance owns its own:

- user accounts and device sessions;
- PostgreSQL database;
- Redis realtime fan-out state;
- encrypted message envelopes and encrypted attachment blobs;
- WebSocket gateway;
- TURN configuration for calls;
- optional FCM routing credentials.

The Android client can select an instance at sign-in. HTTP API calls, token refreshes and the `/realtime` WebSocket are routed to that selected server. Device identity-key aliases are namespaced by server origin, so the same username on two independent instances does not intentionally reuse the same ChatNU identity-key alias.

No ChatNU central cloud is required for two users registered on the same self-hosted instance to use the messenger.

## Start your own server

Requirements:

- Linux/macOS host or another environment supported by Docker Engine;
- Docker Engine;
- Docker Compose v2 (`docker compose`);
- for public deployments, a DNS name and TLS reverse proxy are strongly recommended;
- public UDP/TCP reachability for the configured TURN ports if reliable calling is required.

From the repository root:

```bash
chmod +x scripts/chatnu.sh
./scripts/chatnu.sh up
```

The script creates `.env` on first run with random PostgreSQL, JWT and TURN secrets, builds the containers and waits for the API health check.

Useful commands:

```bash
./scripts/chatnu.sh status
./scripts/chatnu.sh logs
./scripts/chatnu.sh restart
./scripts/chatnu.sh down
```

`./scripts/chatnu.sh reset` deletes the PostgreSQL, Redis and attachment volumes. Treat it as destructive.

## Connect Android to your instance

On the ChatNU sign-in screen, tap the server address in the top-right corner and enter the origin of your instance, for example:

```text
https://chat.example.com
```

Enter only the origin; do not include `/auth`, `/realtime`, query parameters or credentials.

For a local emulator debug build, a typical development endpoint is:

```text
http://10.0.2.2:3000
```

Debug builds permit cleartext HTTP for local development. Public/release deployments should use HTTPS.

## Public deployment checklist

1. Put the API behind a TLS reverse proxy such as Caddy, nginx or Traefik.
2. Forward WebSocket upgrades for `/realtime`.
3. Set a strong `POSTGRES_PASSWORD`, `JWT_SECRET` and `TURN_SHARED_SECRET`.
4. Set `TURN_HOST` to the public TURN hostname or IP.
5. Expose the TURN listening port and relay port range configured in `.env` / `docker-compose.yml`.
6. Restrict `CORS_ORIGIN` when a browser client is deployed.
7. Back up PostgreSQL and the encrypted attachment volume.
8. Keep Docker images and host packages patched.
9. Configure FCM only if background push delivery is desired; connected realtime messaging does not require Firebase.

See `DEPLOYMENT.md` and `SECURITY_MODEL.md` for the detailed production and security notes.

## Important: independent instances are not federation yet

The current model is **multi-instance/self-hosted**, not full server-to-server federation.

Users on the same selected instance can communicate normally. A user registered on `server-a.example` cannot yet open a direct chat with `user@server-b.example` and have the two servers exchange messages automatically.

Cross-instance federation should not be bolted on as a plain HTTP relay. A safe federation design needs, at minimum:

- stable signed server identities and key rotation;
- authenticated discovery and remote-user addressing such as `user@host`;
- remote device-key discovery with anti-substitution protections;
- signed, replay-resistant server-to-server envelopes;
- idempotent delivery and retry semantics;
- conversation membership authorization across trust boundaries;
- abuse controls and remote-server blocking;
- attachment federation rules;
- privacy-preserving metadata decisions;
- a versioned protocol and compatibility negotiation.

Until those pieces are implemented and tested, ChatNU deliberately labels the architecture as self-hosted multi-instance rather than claiming Matrix-style federation.
