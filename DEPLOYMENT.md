# ChatNU deployment

This guide targets a single Linux host running Docker Engine and Docker Compose v2.

## 1. DNS

Point an A/AAAA record such as `api.devnu.ir` at the server. Only the reverse proxy should be public. PostgreSQL and Redis are private Docker services, and the API is bound to host loopback by default.

## 2. Start the stack

```bash
git clone https://github.com/DEVNUIR/ChatNU-Android.git
cd ChatNU-Android
git checkout feat/production-ready-chatnu
chmod +x scripts/chatnu.sh
./scripts/chatnu.sh up
```

If `.env` does not exist, the helper creates it with random PostgreSQL and JWT secrets, sets file mode `0600`, builds the API image, starts PostgreSQL/Redis/API, applies versioned Prisma migrations and waits for `/health`.

Useful commands:

```bash
./scripts/chatnu.sh status
./scripts/chatnu.sh logs
./scripts/chatnu.sh restart
./scripts/chatnu.sh down
```

`./scripts/chatnu.sh reset` deletes the PostgreSQL, Redis and attachment volumes. Do not run it on a production instance unless data loss is intended.

## 3. Network exposure

The supplied Compose file already publishes only:

```yaml
ports:
  - "127.0.0.1:3000:3000"
```

PostgreSQL and Redis have no host ports. Do not change these defaults merely to make troubleshooting easier. SSH tunnels and `docker compose exec` exist precisely so databases do not have to sit naked on the internet.

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
        proxy_set_header Authorization $http_authorization;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 70s;
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

Issue the certificate using the normal Certbot Nginx flow before enabling the final TLS server block.

## 5. Production environment

The generated `.env` is already randomized. Review at least:

```dotenv
POSTGRES_PASSWORD=<random-secret>
JWT_SECRET=<at-least-32-random-bytes>
ACCESS_TOKEN_TTL_SECONDS=900
CORS_ORIGIN=https://your-web-client.example
MAX_UPLOAD_BYTES=26214400
```

If no browser client exists, CORS does not affect the Android app, but restricting it is still preferable before a web client is added.

Attachment bytes are stored at `/data/attachments` inside the API container on the named `chatnu_attachments` volume. Clients never receive a filesystem path; authenticated downloads are streamed through the API.

## 6. Database migrations

Production startup runs:

```bash
npx prisma migrate deploy
```

Migration files live in `server/prisma/migrations/`. Do not replace production migrations with `prisma db push`. For future schema changes, create and review a migration in development, commit it, then deploy the new image.

## 7. Android endpoints

Debug builds default to the Android emulator host:

```text
http://10.0.2.2:3000/
ws://10.0.2.2:3000/realtime
```

For a real device on a LAN:

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

Override them with `CHATNU_API_URL` and `CHATNU_WS_URL` at build time for another domain.

## 8. Backups

PostgreSQL and the attachment volume are durable data. Redis is realtime fan-out/cache state and is not a substitute for PostgreSQL.

PostgreSQL dump:

```bash
docker compose exec -T postgres pg_dump -U chatnu -d chatnu > chatnu-$(date +%F).sql
```

Attachment archive:

```bash
docker compose run --rm --no-deps api \
  tar -C /data -czf - attachments > chatnu-attachments-$(date +%F).tar.gz
```

Store backups away from the VPS and test restoration. A backup nobody has restored is merely an optimistic file collection.

## 9. Updating

```bash
git pull --ff-only
./scripts/chatnu.sh up
```

The API image is rebuilt and pending Prisma migrations are applied on startup. Back up production data before schema-changing deployments.

## 10. Security boundary

The account/auth/database/realtime transport stack in this branch is real. The legacy Android `CryptoEngine` is still a reversible simulation, not Signal/Double-Ratchet E2EE, and the call UI is not wired to a production RTC backend. See `SECURITY_MODEL.md` before making E2EE or secure-call claims.
