# ChatNU deployment

This guide targets a single Linux host with Docker Engine + Docker Compose v2. ChatNU now ships an interactive installer for public deployments and real Internet-blackout deployments.

## 1. Recommended install

From the repository root:

```bash
chmod +x scripts/chatnu.sh
./scripts/chatnu.sh install
```

The wizard asks for a domain/reachable IP, checks port conflicts, starts the Docker stack, configures TLS, optionally opens supported host firewall rules, and prints the exact address users paste into Android.

The network layout intentionally keeps the Node API private:

```text
Internet / LAN
    |
    v
Nginx TLS edge: 0.0.0.0:443
    |
    v
ChatNU API: 127.0.0.1:3000 (or another automatic free 3000-3099 port)
    |
    +--> PostgreSQL (Docker-private)
    +--> Redis      (Docker-private)
```

Do **not** bind the ChatNU API itself to `0.0.0.0` for a normal deployment. Nginx should be the public HTTP/TLS boundary. TURN is separately reachable because WebRTC clients need it.

## 2. Public TLS mode

Choose:

```text
1) Public / Let's Encrypt
```

The wizard:

- installs Nginx when it is absent on supported apt/dnf/yum systems;
- reuses an existing Nginx installation when present;
- installs/uses Certbot;
- creates the ChatNU reverse-proxy and `/realtime` WebSocket configuration;
- obtains a publicly trusted certificate;
- redirects HTTP to HTTPS;
- keeps the API bound to localhost.

For the simplest public flow, use a DNS hostname such as:

```text
chat.example.com
```

Point that hostname to the server before issuance. Public ACME validation still requires network reachability; if the outside Internet is unavailable, use emergency mode instead.

## 3. Internet blackout / emergency TLS

Choose:

```text
2) Emergency offline CA
```

or run:

```bash
./scripts/chatnu.sh emergency 10.20.30.40
```

This mode does not contact Let's Encrypt and does not install a certificate-generation package on the host. OpenSSL is already included inside the ChatNU API image. The wizard generates a persistent local ChatNU CA, signs a server certificate with DNS/IP SANs, and starts the included Docker Nginx edge.

The server prints an enrollment URL such as:

```text
https://10.20.30.40#chatnu-ca=sha256/BASE64_PIN
```

Paste the complete line into ChatNU Android. Android pins that emergency CA for only that server and continues to verify the certificate chain and hostname. ChatNU never uses a global `trust all certificates` fallback.

See `EMERGENCY_DEPLOYMENT.md` for offline preparation and trust-rotation details.

## 4. Ports and conflicts

Preferred defaults:

- public HTTPS: TCP 443 on Nginx;
- public HTTP/ACME redirect: TCP 80 in normal public mode;
- internal ChatNU API: TCP 3000 on `127.0.0.1` only;
- TURN/STUN: TCP+UDP 3478;
- TURN relay media: UDP 49160-49200.

The wizard automatically moves the **internal API** to a free port in 3000-3099 when needed. It also moves TURN to a later free TCP/UDP port when 3478 is occupied.

In emergency mode, if TCP/443 is occupied, the included Nginx edge chooses a free HTTPS port starting at 8443 and prints that port in the Android enrollment URL.

For normal public Let's Encrypt mode, TCP/80 and TCP/443 should be available to Nginx (or already owned by the existing Nginx instance). If another unrelated daemon owns them, the wizard reports the listener instead of silently killing it.

## 5. TURN and calls

The supplied Coturn service uses host networking. Set by the wizard:

```dotenv
TURN_HOST=chat.example.com
TURN_PORT=3478
TURN_REALM=chatnu
TURN_SHARED_SECRET=<random secret>
TURN_MIN_PORT=49160
TURN_MAX_PORT=49200
```

`TURN_SHARED_SECRET` is generated locally and shared only between the API and Coturn. The API returns short-lived TURN REST credentials to authenticated clients; there is no permanent TURN password in the APK.

If the server is behind NAT, forward the selected TURN TCP/UDP listening port and UDP relay range to the host. Test calls from two genuinely different networks.

## 6. Firewall automation

At the end of installation the wizard can add narrowly scoped rules when active `ufw` or `firewalld` is detected. It opens only the selected HTTPS port, TURN TCP/UDP port and TURN UDP relay range; public mode also keeps TCP/80 available for ACME/redirect traffic.

The script does not replace arbitrary custom firewall policy on systems it does not recognize.

## 7. Offline image preparation

A completely fresh host cannot download containers during a total blackout. Beforehand, create a bundle:

```bash
./scripts/chatnu.sh offline-export chatnu-offline-images.tar
```

It includes:

- PostgreSQL;
- Redis;
- Coturn;
- the built ChatNU API image;
- the emergency Nginx edge image.

On the isolated host, Docker Engine + Compose must already exist. Then:

```bash
./scripts/chatnu.sh offline-import chatnu-offline-images.tar
./scripts/chatnu.sh install
```

Choose emergency mode. No runtime image pull or public CA is required.

## 8. Environment and secrets

The first run creates `.env` mode `0600` with random secrets. Important values include:

```dotenv
POSTGRES_PASSWORD=<random>
JWT_SECRET=<random>
ACCESS_TOKEN_TTL_SECONDS=900
MAX_UPLOAD_BYTES=26214400

CHATNU_BIND_ADDRESS=127.0.0.1
CHATNU_HOST_PORT=3000
CHATNU_EDGE_BIND_ADDRESS=0.0.0.0
CHATNU_HTTPS_PORT=443
CHATNU_PUBLIC_NAME=chat.example.com
CHATNU_TLS_MODE=public

TURN_HOST=chat.example.com
TURN_PORT=3478
TURN_REALM=chatnu
TURN_SHARED_SECRET=<random>
TURN_MIN_PORT=49160
TURN_MAX_PORT=49200
```

Do not commit `.env`, emergency CA private keys, Android signing keys, or offline image bundles.

## 9. Optional FCM push

ChatNU works without FCM while realtime WebSocket connectivity is alive. For offline wake-up notifications, configure a Firebase service account only on the server:

```dotenv
FIREBASE_SERVICE_ACCOUNT_B64=<base64-json>
```

Push payloads contain routing identifiers only, not message plaintext or E2EE media keys.

Android Firebase client values remain optional build-time values:

```text
FIREBASE_APP_ID
FIREBASE_API_KEY
FIREBASE_PROJECT_ID
FIREBASE_SENDER_ID
```

## 10. Backups

PostgreSQL:

```bash
docker compose exec -T postgres pg_dump -U chatnu -d chatnu > chatnu-$(date +%F).sql
```

Encrypted attachments:

```bash
docker compose run --rm --no-deps api \
  tar -C /data -czf - attachments > chatnu-attachments-$(date +%F).tar.gz
```

When emergency mode is used, also back up **privately**:

```text
deploy/tls/ca.key
deploy/tls/ca.crt
```

Losing the CA private key does not expose old traffic, but generating a replacement CA changes the emergency trust identity and requires trusted out-of-band re-enrollment of clients.

## 11. Useful operations

```bash
./scripts/chatnu.sh status
./scripts/chatnu.sh logs
./scripts/chatnu.sh restart
./scripts/chatnu.sh down
```

`reset` destroys PostgreSQL, Redis and attachment volumes, but deliberately preserves the emergency CA files:

```bash
./scripts/chatnu.sh reset
```

## 12. Android release signing

Production release signing remains owner-controlled through:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

Never commit a long-lived Android keystore or its passwords.

## 13. Security boundary

Message plaintext is encrypted client-side before reaching the server and attachments are encrypted before upload. One-to-one WebRTC media uses DTLS-SRTP. Emergency TLS protects transport without depending on a public CA during a blackout.

The current application E2EE protocol is still not Signal Double Ratchet/MLS and has not received an independent cryptographic audit. Stronger claims remain blocked on the work described in `SECURITY_HARDENING_ROADMAP.md`.
