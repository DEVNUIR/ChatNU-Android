# ChatNU Flutter feature parity matrix

This matrix records the audited product boundary for the Flutter client during the
2026 messenger UX rebuild. The Kotlin Android client, server implementation,
`API_CONTRACT.md`, `SECURITY_MODEL.md`, and production Flutter integration remain
the source of truth.

Legend:

- **Integrated** — production Flutter code is wired to the current server/security contract.
- **UI refactor** — capability exists; this branch changes presentation only.
- **Partial** — a real capability exists, but the current contract does not expose all UX expected from a mature messenger.
- **Not exposed** — do not create production UI that implies the backend supports it.

| Area | Status | Flutter production path | UI decision in this refactor |
| --- | --- | --- | --- |
| Login | Integrated | `SessionController` + `ChatNuApiClient.login` | Focused sign-in screen; no auth mocks |
| Registration | Integrated | `SessionController.register` + local device identity key | Three-stage identity/password/review flow followed by mandatory recovery-code acknowledgement |
| Account recovery | Integrated | `SessionController.recover` | Two-stage account/recovery-code then new-password flow; recovery revokes existing sessions per server behavior |
| Custom server selection | Integrated | `ServerEndpointController` | Keep the trust boundary available in a focused sheet without cluttering the primary auth flow |
| Emergency pinned TLS enrollment | Partial | Enrollment can be stored; Flutter transport intentionally refuses it until Android verification parity | State limitation explicitly; never bypass TLS validation |
| Access/refresh tokens | Integrated | `CredentialVault` + rotating refresh flow | Presentation-only changes; no token logging/query-string transport |
| Per-device E2EE identity | Integrated | `DeviceE2ee` + identity-key registration | Security copy names ChatNU Device Envelope v2 precisely; no Signal Protocol claim |
| Text messaging | Integrated | encrypted payload send + stable `clientId` | Reference-style incoming/outgoing bubbles with sending/failed/retry states |
| Realtime messages | Integrated | authenticated WebSocket + reconciliation/deduplication | Show connection state only when attention is needed; stable list identity retained |
| Conversation read state | Integrated | optimistic local clear + server rollback | Preserve existing semantics |
| Conversation pin/mute | Integrated | optimistic mutation + rollback | Long-press/right-click sheet contains only supported operations |
| Contact/user search | Integrated | server-backed username search | Compact New Chat action sheet leads to real directory search |
| Direct conversation creation | Integrated | `openDirect` | Real server-backed result opens immediately |
| Group creation | Integrated | `createGroup` | Member selection then group details; no fake avatar/update API |
| Recent people strip | UI refactor | recent direct conversations | Uses real conversations as quick-access people; it is not a fabricated Stories feature |
| Message attachments | Integrated | encrypt bytes before upload; decrypt after download | Honest sending/failed/download state; no availability before server result |
| Message copy | Local capability | clipboard only | Context action exposed |
| Failed text retry | Integrated | reuses stable client ID where available | Context action exposed |
| Reply | Not exposed in audited Flutter message model/API path | No reply metadata/action in current production integration | Do not add a fake Reply action even when visual references contain one |
| Edit message | Not exposed | No audited edit endpoint/semantics | Do not add production control |
| Delete message | Not exposed | No audited delete endpoint/semantics | Do not add production control |
| Forward message | Not exposed | No audited forward endpoint/semantics | Do not add production control |
| Reactions | Not exposed | No audited reaction model/API | Do not render fake reactions even when visual references contain them |
| Typing indicator | Not exposed in audited realtime state | No production typing event surfaced to Flutter view state | Do not simulate typing |
| Presence / Online | Not exposed | No audited user-presence state | Direct-chat header says `Encrypted`, never fabricates `Online` |
| One-to-one audio calls | Integrated | WebRTC + realtime call signaling | Simple reference-style call action + active-call overlay |
| One-to-one video calls | Integrated | WebRTC + realtime call signaling | Simple reference-style video action + active-call overlay |
| Mute / camera toggle | Integrated | `CallController` | Expose exactly these supported controls |
| Speaker route selector | Not exposed in current controller | No audited UI-safe controller action | Do not fake control |
| Switch camera | Not exposed in current controller | No audited controller action | Do not fake control |
| Group calls | Not supported | Security model specifies one-to-one calling | No group-call UI |
| Persistent call history | Not exposed in audited API contract | No call-history resource | Do not invent a Calls history destination yet |
| Theme mode | Integrated in this branch | persisted System/Light/Dark preference | Shared appearance controller |
| Glass quality | Integrated in this branch | persisted Full/Balanced/Reduced effect level | Retained for existing compatible surfaces; core chat/auth UX now intentionally uses mostly flat native surfaces |
| English layout | Integrated | Flutter localization delegates | LTR verified in tests |
| Persian layout | Integrated | Flutter localization delegates | RTL + directional layout APIs; test coverage retained/expanded |
| Android identity | Integrated | generated Flutter host preserves `ir.devnu.chatnu`, ChatNU label/icon | CI identity gate remains mandatory |

## Non-negotiable implementation boundary

The Flutter presentation layer must not move REST, E2EE, credential, realtime,
attachment, or WebRTC behavior into widgets. It must not introduce alternate mock
repositories for production routes. Demo fixtures may exist only behind the explicit
`ChatNuAppMode.demo` override used by widget tests and local visual development.

## Reference-driven UX boundary

The current phone UI intentionally follows the supplied Mengobrol references in
composition and interaction rhythm: paper-like surfaces, near-black typography, warm
yellow message/unread accents, a recent-people strip, flat chat rows, a centered New Chat
pill, compact native-feeling action sheets, simple conversation chrome, and staged auth.
Visual references are not permission to invent backend capabilities. Stories,
communities, email/OTP verification, presence, reactions, reply, forward, and delete are
omitted until the production contract exposes real semantics for them.

## Performance boundary

The primary chat list, message history, auth screens, composer, and routine action sheets
use flat opaque/translucent paint rather than per-row or per-bubble backdrop blur. Message
and conversation lists remain lightweight and use repaint boundaries where useful.

## Release verification contract

A refactor milestone is not considered releasable until the repository Flutter workflow
passes all of these gates against the same commit: generated Android-host identity
verification, canonical Dart formatting, `flutter analyze --fatal-infos`, `flutter test`,
`flutter build apk --release`, APK signature verification, and explicit recording of
whether the artifact used production signing secrets or fallback Android signing.
