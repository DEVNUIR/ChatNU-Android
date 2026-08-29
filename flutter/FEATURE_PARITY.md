# ChatNU Flutter feature parity matrix

This matrix records the audited product boundary for the Flutter client during the
2026 messenger UX rebuild. The Kotlin Android client, server implementation,
`API_CONTRACT.md`, `SECURITY_MODEL.md`, and production Flutter integration remain
the source of truth.

Legend:

- **Integrated** — production Flutter code is wired to the current server/security contract.
- **UI refactor** — capability exists; this branch changes presentation only.
- **Partial** — a real capability exists, but the current client/API does not expose the full mature-messenger UX yet.
- **Not exposed** — do not create production UI that implies the backend supports it.

| Area | Status | Production path | UI decision in this refactor |
| --- | --- | --- | --- |
| Login | Integrated | `SessionController` + `ChatNuApiClient.login` | Focused sign-in journey; no auth mocks |
| Registration | Integrated | `SessionController.register` + local device identity key | Staged welcome/name/username/security/review flow followed by recovery-code acknowledgement |
| Account recovery | Integrated | `SessionController.recover` | Staged recovery flow; server revokes existing sessions |
| Custom server selection | Integrated | `ServerEndpointController` | Trust boundary stays explicit without cluttering the main auth journey |
| Server provisioning URI | Partial | `ChatNuProvisioningLink` validates `chatnu://server/add?v=1...` | Versioned HTTPS-only, allow-listed public configuration; scanner/app-link dispatch still to be connected |
| Emergency pinned TLS enrollment | Partial | Enrollment can be stored; Flutter transport intentionally refuses it until Android verification parity | Never bypass TLS validation |
| Access/refresh tokens | Integrated | `CredentialVault` + rotating refresh flow | No token logging/query-string transport |
| Multiple accounts / servers | Not exposed as production switching | Current Flutter vault/session owns one active account; old Kotlin `AccountManager` prototype is mock/random and is not production truth | Requires secure multi-session registry plus per-account realtime/crypto lifecycle before switch UI is enabled |
| Per-device E2EE identity | Integrated | `DeviceE2ee` + identity-key registration | Security copy names ChatNU Device Envelope v2 precisely; no Signal Protocol claim |
| Profile read | Integrated | `/me` + session user | Profile hub shows real display name, username, bio/avatar when provided, and active server |
| Profile edit | Not exposed by current REST contract | Prisma user already has `displayName`, `avatarUrl`, `bio`, but no authenticated profile-update route is currently published | Do not save fake local-only profile edits; add authenticated update contract first |
| Text messaging | Integrated | encrypted payload send + stable `clientId` | Reference-style bubbles with delivery/failure states |
| Realtime messages | Integrated | authenticated WebSocket + reconciliation/deduplication | Connection state only when attention is needed |
| Conversation read state | Integrated | optimistic local clear + server rollback | Preserve existing semantics |
| Conversation pin/mute | Integrated | optimistic mutation + rollback | Long-press/right-click sheet contains only supported operations |
| Contact/user search | Integrated | server-backed username/display-name search | Real directory search; no fabricated address book |
| Direct conversation creation | Integrated | `openDirect` | Real server-backed result opens immediately |
| Group creation | Integrated | `createGroup` | Member selection then group details |
| Recent people strip | UI refactor | recent direct conversations | Real conversation peers; not a fabricated Stories feature |
| Message attachments | Integrated | encrypt bytes before upload; decrypt after download | File transport remains opaque encrypted bytes |
| Image messages | Partial | server `MessageType.IMAGE`; Flutter mapper/composer already maps image attachments | Gallery/file selection works through encrypted attachment path; dedicated gallery/camera UX still pending |
| Video messages | Partial | server `MessageType.VIDEO`; Flutter mapper/composer already maps video attachments | Encrypted video attachment transport exists; capture/thumbnail/player polish pending |
| Voice messages | Partial | server `MessageType.VOICE`; Flutter mapper/composer already maps audio attachments | Encrypted audio attachment transport exists; recorder/waveform/duration UX pending |
| Static location messages | Partial | server `MessageType.LOCATION` exists | Needs encrypted location payload schema + permission/map card implementation |
| Live location | Partial foundation only | server `MessageType.LIVE_LOCATION` and Kotlin session model exist, but no audited production update/revoke stream yet | Must define expiry/revoke and encrypted realtime-update semantics before live sharing UI |
| View-once media | Partial foundation only | server enum contains `VIEW_ONCE_IMAGE` / `VIEW_ONCE_VIDEO` | Needs one-view enforcement semantics before UI |
| Message copy | Local capability | clipboard only | Context action exposed |
| Failed text retry | Integrated | stable client ID | Context action exposed |
| Reply | Not exposed | No audited reply metadata/action | Do not fake |
| Edit message | Not exposed | No audited edit endpoint/semantics | Do not fake |
| Delete message | Not exposed | `deletedAt` exists in storage but no audited client endpoint/authorization semantics | Do not fake |
| Forward message | Not exposed | No audited forward semantics | Do not fake |
| Reactions | Not exposed | No audited reaction model/API | Do not fake |
| Typing indicator | Not exposed | No production typing event surfaced to Flutter view state | Do not simulate |
| Presence / Online | Not exposed | `lastSeenAt` exists but no audited presence contract | Header says encrypted rather than fabricating online state |
| One-to-one audio calls | Integrated | WebRTC + realtime call signaling | Modern direct-call action + active-call overlay |
| One-to-one video calls | Integrated | WebRTC + realtime call signaling | Modern video action + active-call overlay |
| Mute / camera toggle | Integrated | `CallController` | Expose exactly supported controls |
| Speaker route selector | Not exposed in current controller | No audited UI-safe controller action | Do not fake |
| Switch camera | Not exposed in current controller | No audited controller action | Do not fake |
| Group calls | Not supported by current signaling | realtime call schema requires one `targetUserId`; no group room/SFU semantics | Requires multiparty signaling/media architecture before group-call UI |
| Persistent call history | Not exposed | No call-history resource | Do not invent a Calls-history destination |
| Chat wallpaper | Integrated in this branch | animated local paint only; no network data | Ambient wallpaper under conversations, respects Reduce Motion |
| Header/navbar blur | Integrated in this branch | presentation-only | Backdrop blur limited to chrome rather than every row/bubble |
| Pane/navigation motion | Integrated in this branch | presentation-only | eased fade/slide transitions, disabled for reduced-motion preference |
| Theme mode | Integrated | persisted System/Light/Dark preference | Shared appearance controller |
| Glass quality | Integrated | persisted Full/Balanced/Reduced level | Depth is concentrated in chrome/surfaces, not per-message blur |
| Language preference | Integrated in this branch | persisted System/English/فارسی | App-level locale override with EN/FA delegates |
| English layout | Integrated | Flutter localization delegates | LTR verified in tests |
| Persian layout | Integrated | Flutter localization delegates | RTL + directional layout APIs |
| Getting Started / FAQ / About | Integrated in this branch | local product guidance | Includes precise security wording and `Developed by devnu.ir` |
| Android identity | Integrated | generated Flutter host preserves `ir.devnu.chatnu`, ChatNU label/icon | CI identity gate remains mandatory |

## Non-negotiable implementation boundary

The Flutter presentation layer must not move REST, E2EE, credential, realtime,
attachment, or WebRTC behavior into widgets. It must not introduce alternate mock
repositories for production routes. Demo fixtures may exist only behind the explicit
`ChatNuAppMode.demo` override used by widget tests and local visual development.

## Media/security boundary

The server already validates/stores the complete Prisma `MessageType` enum, including
`IMAGE`, `VIDEO`, `VOICE`, `LOCATION`, `LIVE_LOCATION`, and view-once media. Flutter's
production encrypted-message mapper already maps these types, and attachment bytes are
encrypted before upload. New capture/playback/location UX should therefore extend the
existing encrypted payload format rather than introduce a second plaintext media path.

Location payload coordinates, voice duration/waveform metadata, media dimensions,
thumbnail references, and similar content-sensitive metadata should remain inside the
encrypted message payload wherever routing does not require them.

## QR / internal-link boundary

`chatnu://server/add` is a versioned public provisioning format. It may contain only the
server HTTPS origin, optional public display name, and optional public TLS pin. Tokens,
recovery codes, device private keys, attachment keys, session identifiers, or other
secrets must never be serialized into QR/deep-link payloads. Unknown fields/actions and
non-HTTPS server enrollment are rejected.

## Performance boundary

Backdrop blur is concentrated in navigation/header chrome and modal surfaces. Message and
conversation rows remain lightweight; animated wallpaper is isolated in a repaint boundary
and stops when reduced motion is requested.

## Release verification contract

A refactor milestone is not considered releasable until the repository Flutter workflow
passes all of these gates against the same commit: generated Android-host identity
verification, canonical Dart formatting, `flutter analyze --fatal-infos`, `flutter test`,
`flutter build apk --release`, APK signature verification, and explicit recording of
whether the artifact used production signing secrets or fallback Android signing.
