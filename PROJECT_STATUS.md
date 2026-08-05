# ChatNU - Project Status

## Overview
**ChatNU** is a production-grade native Android messenger designed for `devnu.ir` with end-to-end encryption (E2EE) using Signal protocol principles, full voice/video calling state machine, media sharing (images, videos, voice messages, files, view-once, disappearing messages), live location tracking, and multi-device session management.

- **App Name**: ChatNU
- **Application ID**: `ir.devnu.chatnu`
- **Primary Domain**: `devnu.ir`
- **REST Backend**: `https://api.devnu.ir`
- **Realtime Gateway**: `wss://api.devnu.ir/realtime`
- **RTC / LiveKit**: `wss://rtc.devnu.ir`
- **Default Locale**: Persian (fa) / English (en) with full RTL mirroring & Jalali/Gregorian date formatting options.

---

## Current Status & Capabilities

### 1. Client Architecture
- **MOCK Mode (Default)**: Fully self-contained, interactive mock backend allowing immediate demonstration of all 50+ screens and flows without external network dependencies.
- **REMOTE Mode**: Seamless abstraction layer through `Repository` pattern to connect directly to `api.devnu.ir` when deployed.
- **Room Encrypted Database**: Modern Room DB + AES local state encryption.
- **Jetpack Compose UI**: Material Design 3 custom design system with primary accent `#5B7CFF`, OLED Black theme, and responsive Persian/English RTL/LTR support.

### 2. Messaging & Media Features
- [x] Username/Password authentication with argon2id hashing spec & local recovery codes.
- [x] End-to-end encrypted 1-on-1 and Group chats (Double Ratchet key evolution simulation & verification).
- [x] View-once images/videos with `FLAG_SECURE` rendering.
- [x] Disappearing messages with countdown timer state.
- [x] Audio voice message recorder with live waveform, play/pause, seek, and variable playback speeds.
- [x] Static and encrypted live location sharing with duration controls (15m, 1h, 8h).
- [x] Real-time voice/video/group calls with PIP, active speaker UI, camera flip, and mute toggles.
- [x] Active sessions management, remote device revoking, and key safety numbers verification.

---

## Infrastructure Requirements for Remote Production Deployment
1. **Domain Setup**: Point DNS record `api.devnu.ir` to API gateway and `rtc.devnu.ir` to LiveKit media server.
2. **TLS / SSL Certificates**: Managed via Let's Encrypt / Certbot on Nginx reverse proxy.
3. **Database**: PostgreSQL 16 with Prisma ORM.
4. **Cache & Queue**: Redis 7 with BullMQ for offline push wake-up job queues.
5. **Media Storage**: S3 / MinIO object storage bucket for encrypted attachments.
6. **TURN / STUN**: coturn instance for WebRTC NAT traversal.
