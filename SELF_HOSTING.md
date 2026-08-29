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

The Android client can select an instance at sign-in. HTTP API calls, token refreshes and the `/realtime` WebSocket are routed to that selected server. Device identity-key aliases are namespaced by server origin and trust identity, so identical usernames on independent instances do not intentionally reuse the same ChatNU identity-key alias.

No ChatNU central cloud is required for two users registered on the same self-hosted instance to use the messenger.

## Easiest setup: run the wizard

Requirements:

- Linux host with Docker Engine + Docker Compose v2;
- for normal public TLS, working DNS/Internet during certificate issuance;
- for blackout mode, previously loaded ChatNU Docker images or an offline image bundle.

Run:

```bash
chmod +x scripts/chatnu.sh
./scripts/chatnu.sh
```

or explicitly:

```bash
./scripts/chatnu.sh install
```

The wizard:

1. asks for the public domain or reachable IP;
2. keeps the API private on `127.0.0.1` and automatically selects a free local port beginning at 3000;
3. automatically selects a free TURN TCP/UDP port beginning at 3478;
4. offers normal public TLS or emergency blackout TLS;
5. for public TLS, installs/uses Nginx and Certbot and configures the reverse proxy + WebSocket upgrade;
6. for emergency TLS, generates a persistent local CA inside the already-built ChatNU image and starts a Docker Nginx edge without disabling certificate validation;
7. optionally opens only the required `ufw`/`firewalld` ports;
8. prints the exact server address/enrollment link users paste into Android.

The intended public binding is **not** the Node API. The safe layout is:

```text
Internet/LAN -> Nginx 0.0.0.0:443 -> ChatNU API 127.0.0.1:<auto-port>
```

PostgreSQL and Redis remain private. TURN is intentionally reachable on its configured TCP/UDP listening port and UDP relay range.

## Internet blackout / emergency TLS

A public CA cannot issue or renew a certificate if its validation infrastructure cannot reach the deployment. ChatNU therefore supports an emergency mode that does not contact a public CA:

```bash
./scripts/chatnu.sh emergency 10.20.30.40
```

or choose emergency mode in the installer.

It prints an enrollment link such as:

```text
https://10.20.30.40#chatnu-ca=sha256/BASE64_PIN
```

The Android app stores that CA pin only for the selected origin and verifies the emergency certificate chain and hostname. It never enables a global trust-all certificate mode.

See `EMERGENCY_DEPLOYMENT.md` for the full blackout threat model and offline preparation steps.

## Prepare an offline bundle

Before a possible blackout:

```bash
./scripts/chatnu.sh offline-export chatnu-offline-images.tar
```

On the isolated host (with Docker Engine + Compose already installed):

```bash
./scripts/chatnu.sh offline-import chatnu-offline-images.tar
./scripts/chatnu.sh install
```

This avoids runtime pulls/builds for PostgreSQL, Redis, Coturn, the ChatNU API and the emergency Nginx edge.

## Useful commands

```bash
./scripts/chatnu.sh status
./scripts/chatnu.sh logs
./scripts/chatnu.sh restart
./scripts/chatnu.sh down
```

`./scripts/chatnu.sh reset` deletes the PostgreSQL, Redis and attachment volumes. It preserves the emergency CA files so enrolled phones do not silently get a different trust anchor.

## Connect Android to your instance

On the ChatNU sign-in screen, tap the server address in the top-right corner and enter the origin printed by the wizard, for example:

```text
https://chat.example.com
```

For emergency mode, paste the **complete** enrollment link including `#chatnu-ca=...` the first time.

For a local emulator debug build, a typical development endpoint is:

```text
http://10.0.2.2:3000
```

Debug builds permit cleartext HTTP for local development. Public/release deployments should use HTTPS or pinned emergency TLS.

## Ports

Default/preferred ports are:

- Nginx public HTTPS: TCP 443;
- Nginx HTTP/ACME redirect in normal public mode: TCP 80;
- ChatNU internal API: TCP 3000 on `127.0.0.1` only; wizard may choose 3001-3099 if occupied;
- TURN/STUN: TCP+UDP 3478; wizard can select a later free port when occupied;
- TURN relay media: UDP 49160-49200 by default.

If emergency TCP/443 is occupied, the wizard chooses a free HTTPS port starting at 8443 and includes it in the Android enrollment URL.

## Public deployment checklist

1. Prefer the wizard-managed Nginx TLS edge rather than exposing the API port.
2. Keep WebSocket upgrades working for `/realtime`.
3. Keep `POSTGRES_PASSWORD`, `JWT_SECRET` and `TURN_SHARED_SECRET` private and randomly generated.
4. Set `TURN_HOST` to the reachable TURN hostname or IP.
5. Expose only the required TURN listening port and relay range.
6. Restrict `CORS_ORIGIN` if/when a browser client is deployed.
7. Back up PostgreSQL, encrypted attachments, and (if used) the emergency CA key.
8. Keep Docker images and host packages patched.
9. Configure FCM only if background push delivery is desired; connected realtime messaging does not require Firebase.

See `DEPLOYMENT.md`, `EMERGENCY_DEPLOYMENT.md`, and `SECURITY_MODEL.md` for detailed production/security notes.

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
