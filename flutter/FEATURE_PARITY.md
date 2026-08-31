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
| Custom server selection | Integrated | `ServerEndpointController` + `SessionController.switchServer` | Settings can switch the active HTTPS server; current account is signed out and old-server bearer credentials are cleared before the endpoint changes |
| Server provisioning URI | Partial | `ChatNuProvisioningLink` validates `chatnu://server/add?v=1...` | Versioned HTTPS-only, allow-listed public configuration; scanner/app-link dispatch still to be connected |
| Emergency pinned TLS enrollment | Partial | Enrollment can be stored; Flutter transport intentionally refuses it until Android verification parity | Never bypass TLS validation |
| Access/refresh tokens | Integrated | `CredentialVault` + rotating refresh flow | No token logging/query-string transport |
| Multiple accounts / saved server registry | Not exposed | Current Flutter vault/session owns one active account and one active endpoint | Active server switching is real, but remembered multi-account/multi-server session switching still requires an isolated secure session registry plus per-account realtime/crypto lifecycle |
| Per-device E2EE identity | Integrated | `DeviceE2ee` + identity-key registration | Security copy names ChatNU Device Envelope v2 precisely; no Signal Protocol claim |
| Profile read | Integrated | `/me` + session user | Profile hub shows real display name, username, bio/avatar when provided, and active server |
| Profile edit | Integrated in this branch | authenticated `PATCH /me`, `POST /me/avatar`, `DELETE /me/avatar` + persisted session user | Settings edits display name/bio and uploads/removes the real avatar; username stays read-only because E2EE identity namespacing currently depends on it |
| Text messaging | Integrated | encrypted payload send + stable `clientId` | Reference-style bubbles with delivery/failure states |
| Realtime messages | Integrated | authenticated WebSocket + reconciliation/deduplication | Connection state only when attention is needed |
| Consecutive message grouping | UI refactor | chronological decrypted message list + local presentation policy | Same-sender messages group only within the same local day and configurable gap (5 minutes by default); system messages break groups; repeated incoming group-chat sender/avatar chrome collapses |
| In-chat message search | Local capability | currently loaded decrypted messages in client memory | Search body/sender/file-name text locally with highlighting and result navigation; no plaintext query is sent to the server, and older history must be paginated before it can be searched |
| Smart message following / new-message-below | UI refactor | reverse message viewport + realtime message state | Follow newest messages when already near the bottom or after an own send; otherwise preserve reading position and show a local separator/count plus jump-to-latest control without changing server read semantics |
| Conversation read state | Integrated | optimistic local clear + server rollback | Preserve existing semantics |
| Conversation pin/mute | Integrated | optimistic mutation + rollback | Long-press/right-click sheet contains only supported operations |
| Contact/user search | Integrated | server-backed username/display-name search | Real directory search; no fabricated server-side address book |
| Saved contacts | Partial/local | per-account + per-server secure local contact book | Search results can be saved/removed as contacts without pretending the server has a synchronized contacts resource |
| Direct conversation creation | Integrated | `openDirect` | Real server-backed result opens immediately |
| Group creation | Integrated | `createGroup` | Member selection then group details |
| Recent people strip | UI refactor | recent direct conversations | Real conversation peers; not a fabricated Stories feature |
| Message attachments | Integrated | encrypt bytes before upload; decrypt after download | Attachment sheet exposes only real transport paths; Gallery, Camera, Video, Audio, File, and static Location use the existing encrypted message pipeline |
| Image messages | Integrated transport + playback | server `MessageType.IMAGE`; encrypted attachment path; in-memory decrypted preview | Natural-ratio inline presentation after decryption plus a zoomable in-app viewer; encrypted images are not cropped into a fake fixed thumbnail |
| Video messages | Integrated transport + playback | server `MessageType.VIDEO`; encrypted attachment path + `video_player` | Before decryption the UI uses an honest video poster rather than fabricating a thumbnail; after decryption the real first frame/player, duration, scrubbing, and progress are available |
| Video notes | Integrated in this branch | front-camera capture up to 60 seconds, encrypted `VIDEO` attachment with private `videoNote` + `durationMs` metadata | Hold-to-record can lock, pause/continue, cancel, and send; circular preview/playback remains local to the client and encrypted media transport is unchanged |
| Voice messages | Integrated in this branch | `record` capture + `voice_note_kit` playback + encrypted `VOICE` attachment path | Hold-to-record supports directional cancel, slide-up lock, live amplitude waveform, timer, pause/continue, cancel, send, playback speed, waveform playback, and device-local listened feedback |
| Audio/music attachments | Integrated in this branch | encrypted attachment + internal audio player | Selected audio/music files are files with internal playback and speed controls, distinct from recorded voice notes |
| File attachments | Integrated in this branch | encrypted attachment download + temporary decrypted file + native open/save handoff | Cards show type/name/size, indeterminate decrypt progress, Open in the OS, and Save; temporary decrypted files are cleaned up with the media widget lifecycle |
| Recording state machine | Integrated in this branch | `ChatNuRecordingSession` + existing `record`/`camera` capture paths | Explicit idle → arming → holding → locked/paused → finishing states replace boolean-heavy recorder UI; cancel and lock gestures are mutually exclusive and RTL-aware |
| Static location messages | Integrated in this branch | encrypted location payload + `MessageType.LOCATION` + `flutter_map` renderer | Current coordinates are permission-gated, encrypted in message content, and rendered as a non-interactive OSM-backed map card with attribution |
| Live location | Partial/local in this branch | repeated device-E2EE `MessageType.LIVE_LOCATION` messages driven by `LiveLocationController`; no dedicated server session/update/revoke resource | User can share for up to 15 minutes while ChatNU remains foregrounded; the client sends a fresh encrypted coordinate about every 30 seconds and stops on app background, explicit stop, or local expiry. No background sharing, cross-device stop, participant session, or server-authoritative countdown is claimed |
| Contact message attachment | Not exposed | no audited encrypted contact-message payload in current server contract | Attachment sheet shows Contact disabled rather than serializing address-book data into an invented message format |
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
| One-to-one audio calls | Integrated in this branch | WebRTC + realtime call signaling + `CallController` connection policy | Direct calls expose preparing, ringing, connecting, connected, reconnecting, and failure states; unanswered ringing is bounded to 45 seconds and transient disconnects receive an 8-second reconnect grace period |
| One-to-one video calls | Integrated in this branch | WebRTC + realtime call signaling + `CallController` connection policy | Same resilient state model as voice calls while preserving real remote/local video, camera controls, and existing signaling |
| Call permission / transport errors | Integrated in this branch | media-device/WebRTC exceptions mapped at the call application layer | Consumer UI receives friendly microphone/camera/network guidance instead of raw WebRTC, ICE, or WebSocket exception strings |
| Mute / camera toggle | Integrated | `CallController` | Expose exactly supported controls |
| Speaker route | Integrated in this branch | `flutter_webrtc` `Helper.setSpeakerphoneOn` | Active-call overlay exposes speaker on/off and resets routing on teardown |
| Switch camera | Integrated in this branch | `flutter_webrtc` `Helper.switchCamera` | Video calls expose front/rear camera switching without changing signaling |
| Group calls / meetings / cast | Not supported by current signaling | realtime call schema requires one `targetUserId`; no group room/SFU/casting semantics | Do not bolt on a third-party meeting button; requires explicit multiparty signaling/media architecture first |
| Persistent call history | Not exposed | No call-history resource | Do not invent a Calls-history destination |
| Chat wallpaper | Integrated in this branch | persisted local appearance preference + lightweight painter | User can choose Ambient, Soft Grid, Midnight, or Solid; animation respects Reduce Motion |
| Header/navbar/composer glass | Integrated in this branch | `liquid_glass_easy` presentation layer | Full glass quality is the default; blur stays concentrated in chrome and modal surfaces rather than every message row |
| Pane/navigation motion | Integrated in this branch | presentation-only | eased fade/slide transitions, disabled for reduced-motion preference |
| Theme mode | Integrated | persisted System/Light/Dark preference | Shared appearance controller |
| Glass quality | Integrated | persisted Full/Balanced/Reduced level | Full is the default; lower modes remain available for performance/accessibility needs |
| Icon system | Partial rollout | `enefty_icons` dependency plus existing Material icons where no matching replacement has been audited | New/refactored surfaces can use the modern icon family without forcing unsafe mechanical replacement of every icon |
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
encrypted before upload. Capture/playback/location UX extends that existing encrypted
payload format rather than introducing a second plaintext media path.

Location coordinates, voice/media metadata, media dimensions, thumbnail references, and
similar content-sensitive metadata should remain inside the encrypted message payload
wherever routing does not require them. Phase 2 keeps recorded and picked-video duration
inside encrypted private metadata. Because the current encrypted attachment payload does
not carry a separately routable thumbnail, the client does not invent or upload a
plaintext video thumbnail: it shows a neutral poster before decryption and the real first
frame/player only after local decryption. Decrypted media created for playback/opening is
written only to app temporary storage and is deleted when the media widget is disposed.

## QR / internal-link boundary

`chatnu://server/add` is a versioned public provisioning format. It may contain only the
server HTTPS origin, optional public display name, and optional public TLS pin. Tokens,
recovery codes, device private keys, attachment keys, session identifiers, or other
secrets must never be serialized into QR/deep-link payloads. Unknown fields/actions and
non-HTTPS server enrollment are rejected.

## Map boundary

Static location cards use `flutter_map`. The current tile source is the standard
OpenStreetMap endpoint with attribution and a ChatNU user-agent. This is suitable for
functional validation and light use; a production-scale deployment should use an
OSM-compatible tile service or self-hosted tile infrastructure rather than treating the
community tile endpoint as an unlimited application CDN.

Phase 3 Live Location is deliberately not modeled as a durable server-side location
session because the audited backend exposes the `LIVE_LOCATION` message type but no
separate update/revoke/session resource. The foreground controller therefore emits a
series of ordinary device-E2EE live-location messages on a local 15-minute timer. It stops
when the app leaves the foreground and makes no promise that another device can revoke,
resume, or share a synchronized expiry countdown for that local session.

## Performance boundary

Liquid-glass/blur rendering is concentrated in navigation/header/composer chrome and modal
surfaces. Message and conversation rows remain lightweight; animated wallpaper is isolated
in a repaint boundary and stops when reduced motion is requested. Full glass is the default,
with Balanced and Reduced settings available when the device or user preference needs them.

## Release verification contract

A refactor milestone is not considered releasable until the repository Flutter workflow
passes all of these gates against the same commit: generated Android-host identity
verification, canonical Dart formatting, `flutter analyze --fatal-infos`, `flutter test`,
`flutter build apk --release`, APK signature verification, and explicit recording of
whether the artifact used production signing secrets or fallback Android signing.
