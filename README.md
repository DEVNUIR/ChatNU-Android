# ChatNU

ChatNU is an open-source, local-first and decentralized messenger for Android. The Android client owns the readable local state, while relay nodes transport encrypted envelopes, realtime events and synchronization cursors.

## Redesign branch

`feature/chatnu-ios-redesign` is a complete reconstruction of the original uploaded prototype:

- Kotlin and Jetpack Compose with an iOS-inspired glass UI
- animated onboarding and Android Keystore-backed device identity
- Room plus SQLCipher local database
- offline outbox, retry backoff and WorkManager synchronization
- search, pin/archive gestures, replies, reactions and delivery states
- relay-node discovery, validation and custom-node support
- Ktor REST and WebSocket clients
- Fastify relay backend with PostgreSQL, Redis and Docker
- REST on internal port `8080` and WebSocket on internal port `8081`

## Android

Requirements:

- Android Studio with JDK 17
- Android SDK 36

Open the repository root in Android Studio, or build from a terminal:

```bash
./gradlew testDebugUnitTest assembleDebug
```

On the first run, the wrapper scripts download Gradle's official 8.13 wrapper JAR and verify its published SHA-256 checksum before executing it.

Default service endpoints:

```text
REST:      https://chatnu.devnu.ir
WebSocket: wss://chatnu.devnu.ir/realtime
```

## Backend

```bash
cp .env.example .env
# Replace POSTGRES_PASSWORD and JWT_SECRET with long random values.
docker compose up -d --build
```

The public TLS endpoint should terminate at Nginx. A deployment example is available in `deploy/nginx/chatnu.conf`.

## Security status

The storage, identity-key handling, authenticated device registration and encrypted-envelope transport boundaries are implemented. The current payload cipher is deliberately restricted to debug builds and is **not production E2EE**.

Production release requires an audited X3DH/Double Ratchet implementation, multi-device session handling, encrypted attachment keys, recovery design and an external security review. Do not market this branch as production-secure before those items are completed.

## License

Apache License 2.0.
