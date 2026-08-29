# ChatNU 2026 UI / Backend Capability Contract

The Liquid Glass redesign deliberately separates **UI architecture** from **backend truth**. A control or visual state is only presented as working when the current server can prove or persist it.

## Capability matrix

| Product capability | Current backend truth | 2026 UI behavior | Backend requirement to complete it |
| --- | --- | --- | --- |
| Sending | Client knows local optimistic send and server acceptance | `SENDING` → one check for `SENT_TO_SERVER`; failures are explicit | None for current behavior |
| Delivered receipt | Not provided by `MessageDto` or realtime events | Never shown | Per-message/device delivery receipt plus authenticated realtime event |
| Read receipt | Not provided by `MessageDto` or realtime events | Never shown; legacy `READ` values are clamped to sent-to-server | Per-message/per-participant read receipt plus realtime event and privacy setting |
| Offline queue | Storage enum supports queued architecture, but no durable outbound queue contract was found | UI state exists but is only shown if the client really emits it | Durable retry queue and reconnect policy |
| Chat folders | Conversation type/unread/pin data exists client-side | `All`, `Unread`, `Personal`, `Groups` work as local derived views | Stored custom folder definitions, ordering and inclusion/exclusion rules |
| Archive | No archive preference/API found | No fake archive destination/action | Per-user archived state, update endpoint and realtime preference sync |
| Mark unread | Only mark-read capability found | Not exposed as a working action | Per-user manual-unread marker |
| Saved Messages | No explicit cloud notebook/self-conversation contract found | Not presented as a fake working product | Stable self-conversation identity, search/indexing rules and multi-device semantics |
| Channels | Conversation model only distinguishes `DIRECT` and `GROUP` | No channel UI is shown as working | `CHANNEL` type, subscriber counts, roles, posting permissions, views, reactions, comments/discussion and pins |
| Group roles | Member list exists; role/admin metadata is absent | Member hierarchy only | Role/admin/permission fields and mutation APIs |
| Reactions | Message model can visually represent reaction architecture, persistence contract is absent | No persistent reaction controls | Reaction mutation/read API plus realtime events |
| Pinned messages | Conversation pin preference exists; message pin API not found | Chat pinning works; pinned-message banner does not pretend to work | Message pin endpoint, permission model and realtime event |
| Reply/edit/forward | Reply metadata exists in current model; full edit/forward product contract is incomplete | Reply styling can render known metadata; unsupported mutation controls remain hidden | Stable message references, edit history/event, forward origin metadata and permissions |
| Global message/media/file/link search | User search and client-loaded chat filtering exist | Local chat search and server user search only | Server-side indexed search with type/date/chat filters and pagination |
| Rich media thumbnails | Encrypted attachment flow exists, but server does not provide a plaintext thumbnail contract | Local optimistic image preview when available; encrypted media gets designed placeholders | Encrypted thumbnails/previews, dimensions, duration metadata, progressive transfer state |
| Transfer progress/resume | Attachment upload/download exists; granular progress/resume contract not exposed | No fabricated percentages | Progress stream, resumable transfer IDs and retry semantics |
| Voice listened state | Voice attachment playback exists; receipt/listened metadata absent | Play/pause and duration architecture without fake listened badge | Listened receipt, waveform metadata and playback-position policy |
| Static location | Coordinates are currently embedded in encrypted location payload text | Parsed and rendered as a real map preview; coordinates are secondary details | Prefer structured encrypted location fields in the message envelope |
| Live location | No persistent server session model/background lifecycle found | Foreground sender updates are supported as actual location messages; no fake participant/session state | Session ID, expiration, last-update time, participant markers, stop event and Android background policy |
| Map infrastructure | No dedicated map provider/cache contract | Public OpenStreetMap tiles with attribution and graceful fallback | Production tile provider/cache/privacy/usage-policy decision |
| Call history | WebRTC calling exists; durable history model not found | Active voice/video call UI works; permanent Calls destination is not faked | Call log/history API and missed-call events |
| Advanced group/video calls | Current manager is direct-call oriented | Not surfaced | Backend signaling/session model for multi-party calling |

## Delivery-state correctness

The old production mapping treated every server-materialized message as `READ`. The API contract does not contain evidence for that state. The 2026 UI introduces an explicit `MessageDeliveryState` boundary and currently clamps legacy `SENT`, `DELIVERED`, and `READ` storage values to `SENT_TO_SERVER` unless the backend later supplies authenticated receipt evidence.

This is intentional. A double check must never mean “probably delivered.”

## Recommended receipt contract

A future message payload should expose receipt information independently of ciphertext, for example conceptually:

- server accepted timestamp
- delivered device IDs / delivered-at timestamp
- read participant IDs / read-at timestamp
- user privacy policy controlling whether read receipts are emitted

Realtime events should be monotonic and idempotent so the Android client never regresses from a stronger known state to a weaker one.

## Saved Messages

Saved Messages should be implemented as a real first-class self conversation, not a client-only folder pretending to be cloud storage. It needs a stable server identity, multi-device synchronization, normal encrypted attachment support, search indexing, forwarding targets and explicit retention semantics.

## Channels

Channels require a separate domain type rather than styling a group differently. At minimum the server should add a broadcast conversation type, subscriber membership, admin/posting roles, optional discussion linkage, post views, reactions, pins and moderation permissions.

## Live location

The current UI can send actual foreground location updates, but a flagship live-location product needs a session object with `startedAt`, `expiresAt`, `lastUpdatedAt`, owner/participants and a stop event. Android background execution and notification requirements must be designed before claiming background live sharing.

## Maps and privacy

The current preview requests only the containing OpenStreetMap tile and overlays the exact pin locally, so the exact message coordinates are not embedded into a static-map URL. Before release, ChatNU should select a production-appropriate tile provider/cache strategy, comply with provider usage policy and document the network privacy boundary.
