# ChatNU

ChatNU is a native Android messenger plus a self-hosted server stack.

## What is runnable now

- Android client source is organized as a normal Gradle `:app` module.
- Self-hosted API with PostgreSQL, Redis, WebSocket realtime delivery and MinIO attachment storage.
- Username/password registration and login, Argon2id password hashing, refresh-token rotation and device revocation.
- User search, direct conversations, group conversations, paginated messages, sync cursor and read receipts.
- One-command local/server startup through Docker Compose.

## Start the server

Requirements: Docker Engine + Docker Compose v2.

```bash
cp .env.example .env
# Edit .env and replace every default secret before exposing the service publicly.
./scripts/chatnu.sh up
curl http://127.0.0.1:3000/health
```

Useful commands:

```bash
./scripts/chatnu.sh status
./scripts/chatnu.sh logs
./scripts/chatnu.sh down
./scripts/chatnu.sh reset   # destroys local DB/Redis/MinIO volumes
```

For production, put the API behind Nginx/Caddy with HTTPS, set a strong `JWT_SECRET`, strong PostgreSQL/MinIO credentials, restrict `CORS_ORIGIN`, keep PostgreSQL/Redis/MinIO off the public network, and back up the PostgreSQL and MinIO volumes.

## Android

Open the repository in Android Studio and build the `app` module. Debug defaults target the Android emulator host at `http://10.0.2.2:3000/`. Production builds should use `https://api.devnu.ir/` and `wss://api.devnu.ir/realtime` through Gradle/environment configuration.

## Security status

The original repository described Signal-style E2EE, but its `CryptoEngine` was only a reversible Base64 simulation. That is **not end-to-end encryption**. The server in this branch is designed to store opaque ciphertext envelopes, but true Signal/Double-Ratchet key agreement still requires a reviewed libsignal-based client implementation before ChatNU may honestly advertise production E2EE.

TLS protects client/server traffic once deployed behind HTTPS. Passwords are never stored in plaintext. Do not market the current client crypto as Signal-compatible or audited E2EE.

## Repository layout

- `app/` Android application
- `server/` Node.js/TypeScript API
- `docker-compose.yml` PostgreSQL + Redis + MinIO + API
- `scripts/chatnu.sh` server lifecycle helper
- `API_CONTRACT.md` public API summary
- `SECURITY_MODEL.md` security guarantees and known gaps
