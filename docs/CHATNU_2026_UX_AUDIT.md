# ChatNU 2026 Screen-by-Screen UX Audit

Status legend: **Implemented**, **Partial**, **Backend-blocked**, **Follow-up**.

## Design system — Implemented

- Central spacing, radius, icon, avatar, touch-target, depth, glass and motion tokens.
- Functional-layer glass surfaces only; message/content lists avoid realtime blur.
- Warm neutral light palette, deep neutral dark palette and restrained ChatNU indigo identity.
- High-contrast glass fallback and animation-scale awareness.
- Minimum primary touch targets are designed around Android's recommended 48dp baseline.

## Authentication — Partial

- Existing secure server selection and recovery-code flow preserved.
- Current login/register surface is already Material 3 and usable, but has not been fully migrated to the new glass component library in this pass.
- Security/server enrollment wording remains intentionally explicit.

## Main navigation — Implemented / Partial adaptive

- Phone: floating translucent navigation with animated selected label.
- Primary working destinations: Chats, Contacts, Settings.
- A permanent Calls destination is intentionally omitted because durable call history does not exist yet.
- Large width: compact navigation rail.
- **Follow-up:** true tablet/foldable three-pane navigation rail + conversation list + active conversation. Current conversation navigation still becomes full-screen.

## Conversation list — Implemented

- Dense list rows rather than card-per-chat UI.
- Avatar, name, preview, timestamp, unread badge, pinned, muted, draft and conversation-type signals.
- Long-press action surface.
- Swipe to mark read and pin/unpin using real current capabilities.
- Empty, loading/refresh and connection-error treatments.
- No thick dividers or giant permanent archive row.

## Folders — Implemented / Backend-blocked for custom folders

- Floating segmented glass control.
- All / Unread / Personal / Groups derive from actual current model fields.
- Unread badges and animated selection.
- **Backend-blocked:** custom folders, persisted reorder/rules, Channels, Archive.

## Contacts — Implemented

- Server-backed username search with debounce.
- Direct-message action.
- Empty/no-result/error states.

## Global search — Partial

- Immediate conversation-list filtering.
- Server-backed people search.
- In-chat search across currently loaded messages.
- **Backend-blocked:** global indexed messages/media/files/links search and rich contextual filters.

## Chat screen — Implemented

- Edge-to-edge message content scrolls beneath floating functional controls.
- Floating glass top bar with back, avatar, title, security/member context, calls, search and details.
- Group sender names only when needed.
- Compact information hierarchy.
- Explicit load/error/empty states.

## Message grouping and bubbles — Implemented / RTL follow-up

- Consecutive messages from the same sender visually group and morph corners.
- Incoming/outgoing treatment is visually distinct without glass coating every bubble.
- Reply block styling supported for known reply metadata.
- System/security messages use compact centered pills.
- **RTL audit:** text itself relies on Android bidi handling and logical controls mirror correctly. Ownership-side bubble alignment currently follows layout direction; a physical-side ownership policy should be product-tested with Persian before release rather than blindly assumed.

## Delivery states — Implemented and corrected

- Queued/offline architecture: clock.
- Sending: spinner.
- Sent to server: one check.
- Delivered: two checks architecture exists but cannot be emitted by today's server contract.
- Read: differentiated two-check architecture exists but cannot be emitted by today's server contract.
- Failed: explicit error with retry action.
- Legacy server-loaded `READ` values are deliberately clamped to sent-to-server because the API does not prove delivery/read state.

## Composer — Implemented / interaction follow-up

- Floating glass composer.
- Empty state: attachment + field + camera + microphone.
- Text state: send button replaces mic/camera affordance with animated content transition.
- Multiline expansion.
- Emoji tray.
- Draft preservation per conversation while the app process is alive.
- Send/long-press haptics.
- **Follow-up:** durable draft persistence if desired.
- **Follow-up:** hold-and-drag voice gesture with drag-left cancel / drag-up lock. Current implementation records real audio with explicit cancel/send mode but does not fake Telegram-equivalent gesture completeness.

## Voice recording/playback — Partial

- Real `MediaRecorder` AAC/M4A capture.
- Recording timer and explicit cancel/send.
- Real playback through decrypted attachment file.
- Waveform component renders only when real sample data exists; otherwise a neutral progress line is shown rather than a fake waveform.
- **Backend/product follow-up:** pause/continue, playback speed, persisted listened state, waveform metadata and drag-lock interaction.

## Attachment panel — Implemented

- Modern Material 3 bottom sheet rather than side/dialog attachment UI.
- Gallery, camera, video picker, video capture, file, location and live-location entry points.
- Existing encrypted attachment upload/download path preserved.
- No placeholder Poll/Music/Contact actions are shown without implementation.

## Images — Implemented / metadata follow-up

- Local optimistic URI previews when actual local content is available.
- Rounded natural media container treatment.
- Encrypted historical content uses a designed decrypt/open state instead of pretending a thumbnail exists.
- **Backend follow-up:** encrypted thumbnails, dimensions, progressive transfer and resumable progress.

## Video — Partial

- Dedicated visual video surface, play affordance and view-once differentiation.
- **Backend follow-up:** real encrypted thumbnail/duration/progress metadata and integrated media player transition.

## Files — Implemented / progress follow-up

- Filename/type/size hierarchy where metadata exists.
- Dedicated file affordance and existing encrypted open flow.
- **Backend follow-up:** granular upload/download progress and resume semantics.

## Static location — Implemented

- Location messages never render as raw coordinate-only text in the new chat UI.
- Coordinates are parsed from the currently encrypted payload and rendered as a map preview.
- OpenStreetMap tile preview with exact pin overlaid locally.
- Graceful map-unavailable fallback.
- Coordinates appear only as secondary full-screen details.
- External maps handoff available.

## Live location — Partial

- Foreground sender can emit real periodic live-location messages.
- Live visual treatment and sender stop control are present while the local session is running.
- **Backend-blocked:** persistent live session ID, shared remaining time, multi-participant markers, reliable background sharing and cross-device stop state.

## Saved Messages — Backend-blocked

- Not faked. The current backend has no explicit self/cloud notebook conversation semantics.
- Required server contract is documented in `CHATNU_2026_UI_BACKEND_GAPS.md`.

## Groups — Implemented / metadata follow-up

- Group member count and member list hierarchy.
- Sender names in grouped chat messages.
- Real group creation and server membership.
- **Backend-blocked:** roles/admin badges, permissions, mentions index and pinned-message APIs.

## Channels — Backend-blocked

- Not disguised as groups.
- Requires a real `CHANNEL` domain type and broadcast metadata before any channel UX is presented as working.

## Archive — Backend-blocked

- No permanent fake archive row.
- Requires per-user server archive preference before archive actions are enabled.

## Profile/contact details — Partial

- Large avatar/name/status context.
- Call/video actions for supported direct chats.
- Group member list and encryption explanation.
- **Backend/product follow-up:** shared media/files/links, groups in common, block/report API and formal safety-number verification.

## Voice/video calls — Implemented for active direct calls

- Existing WebRTC signaling/media internals preserved.
- Voice: large identity surface, connection state and floating controls.
- Video: edge-to-edge remote video, floating local preview and glass control dock.
- Permission flow retained.
- **Backend-blocked:** call history / missed-call product and multi-party calls.

## Settings — Implemented

- Replaced old top-app-bar + stack-of-cards feel with floating ChatNU glass header, compact sections and flatter information groups.
- System/light/dark theme controls retained.
- Security boundaries remain visible without cluttering ordinary conversations.

## Light and dark themes — Implemented

- Light: warm neutral base instead of washed-out blue gray.
- Dark: deep neutral base instead of pure black.
- Accent is restrained to selection/status/action hierarchy.
- System theme supported through existing ThemeManager.

## RTL / Persian — Partial source audit, device QA required

- `supportsRtl` remains enabled.
- Auto-mirrored back controls are used in redesigned production navigation.
- Compose logical start/end spacing supports RTL.
- Mixed-language text uses platform bidi behavior.
- Maps and coordinate strings remain LTR semantic data inside an RTL layout.
- **Release blocker QA:** screenshot/device test Persian chat list, mixed Persian/English bubbles, URL/phone-number runs, status indicators, folder tabs, attachment sheet and composer.
- **Product decision needed:** keep outgoing ownership on a fixed physical side across languages or mirror it with layout direction. Current implementation mirrors; do not change blindly without testing.

## Accessibility — Implemented / QA required

- Functional glass increases opacity under detected high-text-contrast preference.
- Primary interactive targets meet or exceed the normal Android 48dp baseline.
- Important icon actions have content descriptions.
- Text uses Material typography rather than fixed pixel sizes.
- System animator scale is respected as the reduced-motion source.
- **Release QA:** TalkBack order/semantic grouping, 200% font scale, contrast tooling and switch-access traversal.

## Performance — Implemented by architecture / benchmark follow-up

- No realtime blur behind chat/message LazyColumn rows.
- Glass is limited to top-level controls and sheets.
- Lazy lists use stable message/conversation keys.
- Derived folder filtering is remembered.
- Map previews use image tiles and Coil caching rather than embedded interactive maps per row.
- **Release QA:** Macrobenchmark scroll/jank on low/mid/high devices, image-heavy conversations and 120Hz hardware.

## Motion and haptics — Partial

- Animated nav/folder selection, send/mic content morph, search/composer transitions, sheet motion and call control surfaces.
- Haptics on long press, send, folder/navigation selection and recording actions.
- **Follow-up:** predictive-back shared motion, richer chat-open media transitions, archive/reaction motion after those features exist.

## Final release blockers after this UI pass

1. CI must compile and package the API-36 Android app.
2. Persian/RTL screenshot/device QA and TalkBack/font-scale QA.
3. Physical-side ownership decision for RTL bubbles.
4. Production map-tile provider/cache/privacy decision.
5. Backend work for genuine delivered/read receipts before two-check states can ever appear.
6. Backend work for Saved Messages, Channels, Archive/custom folders and global search if those are mandatory for the launch milestone.
7. Tablet/foldable three-pane mode and Telegram-grade locked voice-record gesture remain UI follow-ups rather than fabricated completed features.
