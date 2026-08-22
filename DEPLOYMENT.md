# ChatNU deployment

This guide targets one Linux host with Docker Engine + Docker Compose v2, Nginx/Caddy for TLS, and an optional Firebase project for offline push.

## 1. DNS and public ports

Point the API hostname, for example `api.devnu.ir`, to the server. The ChatNU API remains bound to `127.0.0.1:3000` and should only be exposed through a TLS reverse proxy.

For reliable WebRTC calls, set `TURN_HOST` to a public DNS name or IP reachable by phones. The supplied Coturn container uses host networking. Open/forward:

- TCP/UDP `3478` for TURN/STUN, or your configured `TURN_PORT`.
- UDP `49160-49200` for relayed media, or your configured `TURN_MIN_PORT`/`TURN_MAX_PORT` range.

PostgreSQL and Redis must remain private.

## 2. Start the stack

```bash
git clone https://github.com/DEVNUIR/ChatNU-Android.git
cd ChatNU-Android
git checkout feat/production-ready-chatnu
chmod +x scripts/chatnu.sh
./scripts/chatnu.sh up
```

If `.env` does not exist, `scripts/chatnu.sh` creates it mode `0600` with random PostgreSQL, JWT and TURN shared secrets. It then builds the API, starts PostgreSQL/Redis/API/Coturn, applies committed Prisma migrations and verifies `/health`.

Useful commands:

```bash
./scripts/chatnu.sh status
./scripts/chatnu.sh logs
./scripts/chatnu.sh restart
./scripts/chatnu.sh down
```

`./scripts/chatnu.sh reset` destroys PostgreSQL, Redis and attachment volumes. Do not run it on production unless data loss is intentional.

## 3. Environment

Review `.env` before public deployment:

```dotenv
POSTGRES_PASSWORD=<random-secret>
JWT_SECRET=<long-random-secret>
ACCESS_TOKEN_TTL_SECONDS=900
CORS_ORIGIN=*
MAX_UPLOAD_BYTES=26214400

TURN_HOST=turn.example.com
TURN_PORT=3478
TURN_REALM=chatnu
TURN_SHARED_SECRET=<random-secret>
TURN_MIN_PORT=49160
TURN_MAX_PORT=49200
TURN_DETECT_EXTERNAL_IP=yes

FIREBASE_SERVICE_ACCOUNT_B64=
```

`TURN_SHARED_SECRET` must be identical for the API and Coturn. The API derives short-lived TURN REST credentials from it; no permanent TURN password is embedded in Android.

If the server is behind NAT, ensure the public IP is correctly detected/advertised by Coturn and forward both the listening port and relay range. Test calls from two different networks, not merely two phones on the same Wi-Fi.

## 4. Optional FCM push

ChatNU works without FCM while the realtime WebSocket is connected. For offline wake-up notifications, create a Firebase service account with Firebase Messaging permission and base64-encode its JSON as one line:

```bash
base64 -w0 firebase-service-account.json
```

Put the result only on the server:

```dotenv
FIREBASE_SERVICE_ACCOUNT_B64=<base64-json>
```

The server uses FCM HTTP v1. Push data contains routing identifiers only; message plaintext and E2EE keys are not sent through Firebase.

Android Firebase client values are supplied at build time:

```text
FIREBASE_APP_ID
FIREBASE_API_KEY
FIREBASE_PROJECT_ID
FIREBASE_SENDER_ID
```

Leaving them blank produces a valid build with FCM disabled.

## 5. Nginx reverse proxy

Example:

```nginx
server {
    listen 80;
    server_name api.devnu.ir;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.devnu.ir;

    ssl_certificate /etc/letsencrypt/live/api.devnu.ir/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.devnu.ir/privkey.pem;

    client_max_body_size 25m;

    location /realtime {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header Authorization $http_authorization;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 75s;
    }

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header Authorization $http_authorization;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Issue a valid TLS certificate before using the production Android endpoints. Android production traffic should use HTTPS/WSS only.

## 6. Database migrations and storage

API startup runs:

```bash
npx prisma migrate deploy
```

Migration files live in `server/prisma/migrations/`. Do not replace production migration history with `prisma db push`.

Attachments are already encrypted on Android before upload. The server stores the encrypted blobs on the `chatnu_attachments` named volume and serves them only through membership-authorized API routes.

## 7. Android builds

Debug defaults:

```text
http://10.0.2.2:3000/
ws://10.0.2.2:3000/realtime
```

DEVNU production defaults:

```text
https://api.devnu.ir/
wss://api.devnu.ir/realtime
```

Override endpoints at build time:

```bash
CHATNU_API_URL=https://api.example.com/ \
CHATNU_WS_URL=wss://api.example.com/realtime \
gradle :app:assembleDebug
```

The current Android version is `1.1.0` (`versionCode 3`).

## 8. Production signing and AAB

The release workflow requires these GitHub Actions secrets:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

Encode the long-lived owner-controlled keystore:

```bash
base64 -w0 chatnu-release.jks
```

Store the output as `ANDROID_KEYSTORE_BASE64`. Do not commit the keystore or passwords. Preserve this keystore permanently because Android app updates depend on the signing identity.

The release workflow builds both:

- signed `app-release.apk`
- signed `app-release.aab`

and verifies the APK signature with `apksigner`.

## 9. Backups

PostgreSQL dump:

```bash
docker compose exec -T postgres pg_dump -U chatnu -d chatnu > chatnu-$(date +%F).sql
```

Encrypted attachment archive:

```bash
docker compose run --rm --no-deps api \
  tar -C /data -czf - attachments > chatnu-attachments-$(date +%F).tar.gz
```

Store backups away from the VPS and test restoration.

## 10. Update

```bash
git pull --ff-only
./scripts/chatnu.sh up
```

Back up data before schema-changing deployments.

## 11. Security boundary

New messages and attachments use real client-side device-based E2EE. This implementation is not Signal Protocol/Double Ratchet and does not claim Signal-grade forward secrecy or an external audit. One-to-one calls are real WebRTC using DTLS-SRTP and authenticated signaling; group calling is not implemented. See `SECURITY_MODEL.md` for exact guarantees and metadata limitations.
