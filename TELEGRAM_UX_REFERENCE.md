# Telegram Android UX reference for ChatNU

ChatNU uses Telegram Android as a behavior/ergonomics reference, not as a branding clone. The goal is
for familiar messaging actions to be where users expect them, while keeping ChatNU's own iconography,
colors, security language and Compose implementation.

Reference repository: `DrKLO/Telegram`.

## Areas studied

- `DialogsActivity` / `DialogCell`: compact conversation hierarchy, readable unread/pin/mute states.
- `ContactsActivity`: fast searchable contact selection.
- `ChatActivity` and `Components/ChatActivityEnterView`: composer states, attachment access, voice/video mode switching.
- `VoiceMessageEnterTransition`: short ~220 ms continuity between recording and the sent voice bubble.
- `ThemeActivity` and theme preview cells: instant theme feedback and low-friction appearance switching.
- media/share components: attachment actions grouped by intent rather than exposing filesystem concepts first.

## ChatNU implementation rules

1. Do not copy Telegram trademarks, app name, logos or visual branding.
2. Prefer an original Jetpack Compose implementation of interaction patterns.
3. Keep primary actions reachable with one thumb and avoid confirmation dialogs for reversible actions.
4. Use short transitions (roughly 160–280 ms) and spring only on small controls; never make navigation wait for decoration.
5. Permission prompts are requested at the moment the related feature is used, not in a giant first-run permission wall.
6. Security state is visible but not noisy: encrypted by default, warnings only when a meaningful security property changes.
7. Media is encrypted before upload. UI convenience must never move plaintext encryption keys or decrypted media to the server.

## Licensing note

Telegram Android's repository is GPLv2. Directly incorporating or modifying GPL-covered Telegram code
has redistribution/license obligations. ChatNU currently follows the interaction ideas with original
Compose code rather than copying Telegram Java implementation. If Telegram code is intentionally
imported later, the project licensing decision must be made explicitly before release.
