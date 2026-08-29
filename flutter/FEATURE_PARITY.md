# ChatNU Flutter feature parity matrix

This matrix records the audited product boundary for the Flutter client during the
2026 Liquid Glass UI rebuild. The Kotlin Android client, server implementation,
`API_CONTRACT.md`, `SECURITY_MODEL.md`, and production Flutter integration remain
the source of truth.

Legend:

- **Integrated** — production Flutter code is wired to the current server/security contract.
- **UI refactor** — capability exists; this branch changes presentation only.
- **Partial** — a real capability exists, but the current contract does not expose all UX expected from a mature messenger.
- **Not exposed** — do not create production UI that implies the backend supports it.

| Area | Status | Flutter production path | UI decision in this refactor |
| --- | --- | --- | --- |
| Login | Integrated | `SessionController` + `ChatNuApiClient.login` | Premium shared auth surface; no auth mocks |
| Registration | Integrated | `SessionController.register` + local device identity key | Same auth surface with explicit recovery/security messaging |
| Account recovery | Integrated | `SessionController.recover` | Keep visible and explicit; recovery revokes existing sessions per server behavior |
| Custom server selection | Integrated | `ServerEndpointController` | Keep server trust boundary visible; never hide behind an ambiguous icon |
| Emergency pinned TLS enrollment | Partial | Enrollment can be stored; Flutter transport intentionally refuses it until Android verification parity | State limitation explicitly; never bypass TLS validation |
| Access/refresh tokens | Integrated | `CredentialVault` + rotating refresh flow | Presentation-only changes; no token logging/query-string transport |
| Per-device E2EE identity | Integrated | `DeviceE2ee` + identity-key registration | Security copy names ChatNU Device Envelope v2 precisely; no Signal Protocol claim |
| Text messaging | Integrated | encrypted payload send + stable `clientId` | Optimistic bubble, sending/failed/retry states |
| Realtime messages | Integrated | authenticated WebSocket + reconciliation/deduplication | Inline connecting/disconnected state; stable list identity retained |
| Conversation read state | Integrated | optimistic local clear + server rollback | Preserve existing semantics |
| Conversation pin/mute | Integrated | optimistic mutation + rollback | Long-press/right-click actions only for supported operations |
| Contact/user search | Integrated | server-backed username search | Shared New Chat flow replaces old mock affordance |
| Direct conversation creation | Integrated | `openDirect` | Real server-backed result opens immediately |
| Group creation | Integrated | `createGroup` | Two-step member selection + group details; no fake avatar/update API |
| Message attachments | Integrated | encrypt bytes before upload; decrypt after download | Honest sending/failed/download state; no availability before server result |
| Message copy | Local capability | clipboard only | Context action exposed |
| Failed text retry | Integrated | reuses stable client ID where available | Context action exposed |
| Reply | Not exposed in audited Flutter message model/API path | No reply metadata/action in current production integration | Do not add a fake Reply action |
| Edit message | Not exposed | No audited edit endpoint/semantics | Do not add production control |
| Delete message | Not exposed | No audited delete endpoint/semantics | Do not add production control |
| Forward message | Not exposed | No audited forward endpoint/semantics | Do not add production control |
| Reactions | Not exposed | No audited reaction model/API | Do not render fake reactions |
| Typing indicator | Not exposed in audited realtime state | No production typing event surfaced to Flutter view state | Do not simulate typing |
| One-to-one audio calls | Integrated | WebRTC + realtime call signaling | Premium active-call overlay |
| One-to-one video calls | Integrated | WebRTC + realtime call signaling | Remote video first; local preview + floating controls |
| Mute / camera toggle | Integrated | `CallController` | Expose exactly these supported controls |
| Speaker route selector | Not exposed in current controller | No audited UI-safe controller action | Do not fake control |
| Switch camera | Not exposed in current controller | No audited controller action | Do not fake control |
| Group calls | Not supported | Security model specifies one-to-one calling | No group-call UI |
| Persistent call history | Not exposed in audited API contract | No call-history resource | Do not invent a Calls history destination yet |
| Theme mode | Integrated in this branch | persisted System/Light/Dark preference | Shared appearance controller |
| Glass quality | Integrated in this branch | persisted Full/Balanced/Reduced effect level | Allows performance-sensitive users/devices to reduce blur |
| English layout | Integrated | Flutter localization delegates | LTR verified in tests |
| Persian layout | Integrated | Flutter localization delegates | RTL + directional layout APIs; test coverage retained/expanded |
| Android identity | Integrated | generated Flutter host preserves `ir.devnu.chatnu`, ChatNU label/icon | CI identity gate remains mandatory |

## Non-negotiable implementation boundary

The Flutter presentation layer must not move REST, E2EE, credential, realtime,
attachment, or WebRTC behavior into widgets. It must not introduce alternate mock
repositories for production routes. Demo fixtures may exist only behind the explicit
`ChatNuAppMode.demo` override used by widget tests and local visual development.

## Performance boundary

Backdrop blur is reserved for persistent navigation chrome, modal/sheet surfaces,
conversation headers, the composer, and call controls. Conversation rows and message
bubbles use opaque/translucent paint only, remain lightweight inside scrolling lists,
and are isolated with repaint boundaries where useful.

## Release verification contract

A refactor milestone is not considered releasable until the repository Flutter workflow
passes all of these gates against the same commit: generated Android-host identity
verification, canonical Dart formatting, `flutter analyze --fatal-infos`, `flutter test`,
`flutter build apk --release`, APK signature verification, and explicit recording of
whether the artifact used production signing secrets or fallback Android signing.
