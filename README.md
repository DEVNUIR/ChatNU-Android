# ChatNU

ChatNU is a native Android messenger plus a self-hosted server stack.

## What is runnable now

- Android client source is organized as a normal Gradle `:app` module.
- Self-hosted API with PostgreSQL, Redis and authenticated WebSocket realtime delivery.
- Username/password registration and login, Argon2id password hashing, rotating refresh tokens, recovery codes and session revocation.
- User search, direct conversations, group conversations, persistent messages, history/sync and read receipts.
- Encrypted attachment payload storage on a dedicated Docker volume, served only through authenticated API routes.
- Versioned Prisma/PostgreSQL migrations.
- One-command startup and lifecycle management through Docker Compose.

## Start the server

Requirements: Docker Engine + Docker Compose v2.

The easiest path generates strong local secrets automatically:

```bash
chmod +x scripts/chatnu.sh
./scripts/chatnu.sh up
curl http://127.0.0.1:3000/health
```

If `.env` does not exist, the helper creates it with random PostgreSQL and JWT secrets and permissions `0600`.

Useful commands:

```bash
./scripts/chatnu.sh status
./scripts/chatnu.sh logs
./scripts/chatnu.sh restart
./scripts/chatnu.sh down
./scripts/chatnu.sh reset   # destroys DB, Redis and attachment volumes
```

The API is intentionally bound to `127.0.0.1:3000` by default. For an internet-facing installation, put Nginx/Caddy in front of it and terminate HTTPS there. PostgreSQL and Redis are not published to the host network.

See `DEPLOYMENT.md` for DNS, TLS, reverse-proxy and backup instructions.

## Android

Open the repository in Android Studio and build the `app` module. Debug builds default to the Android emulator host at:

```text
http://10.0.2.2:3000/
ws://10.0.2.2:3000/realtime
```

A physical device can use a LAN server address through `CHATNU_API_URL` and `CHATNU_WS_URL` build-time environment overrides. Release builds default to:

```text
https://api.devnu.ir/
wss://api.devnu.ir/realtime
```

Session tokens are encrypted with Android Keystore and application backup is disabled.

## Security status

The original repository described Signal-style E2EE, but its `CryptoEngine` was only a reversible Base64 simulation. That is **not end-to-end encryption**. The server in this branch stores opaque message payloads and attachment bytes so a real reviewed client-side encryption layer can replace the simulation without redesigning persistence, but true Signal/Double-Ratchet key agreement is not implemented yet.

TLS protects transport after deployment behind HTTPS. Passwords and recovery codes are Argon2id hashes in PostgreSQL. Refresh tokens are stored as hashes server-side and are rotated. WebSocket authentication uses the Authorization header rather than query-string tokens.

Do not market the current client crypto or call UI as audited E2EE/secure calling.

## Repository layout

- `app/` Android application
- `server/` Node.js/TypeScript API and Prisma schema/migrations
- `docker-compose.yml` PostgreSQL + Redis + API
- `scripts/chatnu.sh` server lifecycle helper
- `DEPLOYMENT.md` production deployment instructions
- `API_CONTRACT.md` public API summary
- `SECURITY_MODEL.md` guarantees and known gaps
