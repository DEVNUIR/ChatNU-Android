# ChatNU emergency / Internet-blackout deployment

ChatNU supports a deployment mode for real Internet blackouts where a public ACME CA such as Let's Encrypt cannot be reached.

## Security model

Emergency mode does **not** disable TLS verification and does not ask users to accept an arbitrary self-signed certificate.

Instead, the server creates a persistent local ChatNU CA and a short-lived server certificate signed by that CA. The Android client enrolls the SHA-256 SPKI pin of that CA for exactly one selected ChatNU origin. The normal Android system CA store remains in use for ordinary public servers.

The CA private key is stored only on the self-hosted server under `deploy/tls/ca.key`. Back it up securely and never send it to users. Users receive only an enrollment URL containing the public CA pin in the URL fragment; URL fragments are not transmitted in HTTP requests.

## Emergency setup

If ChatNU images are already present on the host:

```bash
./scripts/chatnu.sh install
```

Choose:

```text
2) Emergency offline CA
```

The wizard asks for a reachable domain or IP, generates TLS locally using OpenSSL that is already baked into the ChatNU API image, starts an Nginx edge container, and prints an enrollment link similar to:

```text
https://10.20.30.40#chatnu-ca=sha256/BASE64_PIN_HERE
```

If TCP/443 is occupied, the wizard selects a free port beginning at 8443 and includes that port in the enrollment URL.

Paste the complete enrollment link into the Android server picker. Do not remove the `#chatnu-ca=...` fragment on first enrollment.

## What binds to the network

The ChatNU API itself remains private:

```text
127.0.0.1:3000
```

or another automatically selected free port in `3000-3099`.

The emergency Nginx edge is the public listener:

```text
0.0.0.0:443
```

or the alternate HTTPS port selected by the wizard.

TURN uses its configured TCP/UDP port (3478 by default, automatically moved if occupied) plus the configured UDP relay range (49160-49200 by default).

PostgreSQL and Redis are never published to the host network.

## Prepare for a blackout before it happens

A completely fresh machine cannot download Docker images during a total blackout. Prepare an offline bundle while Internet access exists:

```bash
./scripts/chatnu.sh offline-export chatnu-offline-images.tar
```

Copy both the repository and that TAR to the isolated server. Docker Engine + Compose must already be installed there. Then run:

```bash
./scripts/chatnu.sh offline-import chatnu-offline-images.tar
./scripts/chatnu.sh install
```

Choose emergency mode. No public CA, Certbot package installation, or Internet download is required after the images are loaded.

## Normal Internet returns

When stable Internet and public DNS are available again, run the installer and choose public TLS. The normal flow installs/uses host Nginx and Certbot and obtains a publicly trusted certificate. Clients can then switch from the emergency enrollment link to the normal public HTTPS origin.

## Important trust rule

If `deploy/tls/ca.key` is lost and a new emergency CA is generated, existing phones should treat the new CA as a new server trust identity. Redistributing a replacement pin must happen over a trusted out-of-band channel. Never automatically accept a changed CA pin.
