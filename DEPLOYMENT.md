# ChatNU deployment

This guide is for a single Linux host running Docker Engine and Docker Compose v2.

## 1. DNS

Point an A/AAAA record such as `api.devnu.ir` at the server. Keep PostgreSQL, Redis and MinIO private; only the reverse proxy should be public.

## 2. Start the stack

```bash
git clone https://github.com/DEVNUIR/ChatNU-Android.git
cd ChatNU-Android
git checkout feat/production-ready-chatnu
chmod +x scripts/chatnu.sh
./scripts/chatnu.sh up
```

The helper creates `.env` with random PostgreSQL, JWT and MinIO secrets when one does not exist. The API becomes available on `127.0.0.1:3000`/host port `3000` and `/health` is used as the startup check.

Useful commands:

```bash
./scripts/chatnu.sh status
./scripts/chatnu.sh logs
./scripts/chatnu.sh restart
./scripts/chatnu.sh down
```

`./scripts/chatnu.sh reset` deletes all Docker volumes. Do not run it on a production instance unless data loss is intended.

## 3. Lock down the API binding

For a public deployment, bind the API port to loopback in `docker-compose.yml`:

```yaml
ports:
  - "127.0.0.1:3000:3000"
```

The MinIO console is already bound to loopback. PostgreSQL and Redis have no public host ports.

## 4. Nginx reverse proxy

Install Nginx and Certbot, then use a server block similar to this:

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
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 70s;
    }

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Issue the certificate using the normal Certbot Nginx flow before enabling the final TLS server block.

## 5. Production environment

The generated `.env` is usable for a private installation. Before exposing a server publicly, review at least:

```dotenv
POSTGRES_PASSWORD=<random-secret>
JWT_SECRET=<at-least-32-random-bytes>
MINIO_ACCESS_KEY=<non-default-user>
MINIO_SECRET_KEY=<random-secret>
MINIO_BUCKET=chatnu-attachments
ACCESS_TOKEN_TTL_SECONDS=900
CORS_ORIGIN=https://your-web-client.example
MAX_UPLOAD_BYTES=26214400
```

If no browser client exists, CORS is mostly irrelevant to the Android client, but leaving `*` indefinitely is still poor operational hygiene.

## 6. Android endpoints

Debug builds default to the Android emulator host:

```text
http://10.0.2.2:3000/
ws://10.0.2.2:3000/realtime
```

For a real device on a LAN, build with the server's reachable LAN address:

```bash
CHATNU_API_URL=http://192.168.1.10:3000/ \
CHATNU_WS_URL=ws://192.168.1.10:3000/realtime \
gradle :app:assembleDebug
```

Release defaults are:

```text
https://api.devnu.ir/
wss://api.devnu.ir/realtime
```

Override them with `CHATNU_API_URL` and `CHATNU_WS_URL` at build time when deploying under another domain.

## 7. Backups

Back up both PostgreSQL and MinIO. Redis is used for realtime fan-out and does not replace PostgreSQL durability.

Example PostgreSQL dump:

```bash
docker compose exec -T postgres pg_dump -U chatnu -d chatnu > chatnu-$(date +%F).sql
```

MinIO objects live in the `chatnu_minio` Docker volume. Use your normal volume/snapshot/object-storage backup strategy and test restores.

## 8. Security boundary

The transport/auth/database stack in this branch is real. The legacy Android `CryptoEngine` is not real Signal/Double-Ratchet encryption and the call UI is not wired to a production RTC backend. See `SECURITY_MODEL.md` before making any E2EE or secure-call claims.
