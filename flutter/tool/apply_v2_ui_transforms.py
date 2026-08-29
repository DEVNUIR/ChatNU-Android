from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    if old not in text:
        raise SystemExit(f"Expected block not found in {path}: {old[:120]!r}")
    path.write_text(text.replace(old, new, 1))


# Settings: wire real profile/server/wallpaper actions and capability copy.
settings = ROOT / "flutter/lib/features/settings/presentation/settings_pane.dart"
replace_once(
    settings,
    "import 'package:chatnu/features/settings/presentation/settings_support_sheets.dart';\n",
    "import 'package:chatnu/features/settings/presentation/settings_action_sheets.dart';\nimport 'package:chatnu/features/settings/presentation/settings_support_sheets.dart';\n",
)
replace_once(
    settings,
    """                onTap: () => unawaited(\n                  showChatNuProfileSheet(\n                    context,\n                    user: user,\n                    endpoint: endpoint,\n                  ),\n                ),""",
    """                onTap: () => unawaited(\n                  showProfileEditorSheet(context, user: user),\n                ),""",
)
replace_once(
    settings,
    """                    subtitle: strings.isPersian\n                        ? 'نام، نام کاربری، توضیح و سرور فعال'\n                        : 'Identity, bio and active server',\n                    onTap: () => unawaited(\n                      showChatNuProfileSheet(\n                        context,\n                        user: user,\n                        endpoint: endpoint,\n                      ),\n                    ),""",
    """                    subtitle: strings.isPersian\n                        ? 'تصویر نمایه، نام نمایشی و توضیح حساب'\n                        : 'Avatar, display name and account bio',\n                    onTap: () => unawaited(\n                      showProfileEditorSheet(context, user: user),\n                    ),""",
)
replace_once(
    settings,
    """                    subtitle: strings.isPersian\n                        ? 'هویت فعال، سرور و provisioning امن'\n                        : 'Active identity, server and secure provisioning',\n                    onTap: () => unawaited(\n                      showAccountsServersSheet(\n                        context,\n                        user: user,\n                        endpoint: endpoint,\n                      ),\n                    ),""",
    """                    subtitle: strings.isPersian\n                        ? 'تغییر امن سرور فعال؛ تغییر سرور باعث خروج از حساب می‌شود'\n                        : 'Safely switch the active server; switching signs this account out',\n                    onTap: () => unawaited(\n                      showServerManagerSheet(context, endpoint: endpoint),\n                    ),""",
)
replace_once(
    settings,
    """                    subtitle: strings.isPersian\n                        ? 'پس‌زمینهٔ محیطی متحرک با احترام به Reduce Motion'\n                        : 'Ambient animated wallpaper that respects Reduce Motion',\n                  ),""",
    """                    subtitle: strings.isPersian\n                        ? 'محیطی، شبکهٔ نرم، نیمه‌شب یا ساده'\n                        : 'Ambient, soft grid, midnight or solid',\n                    onTap: () => unawaited(showWallpaperPickerSheet(context)),\n                  ),""",
)
replace_once(
    settings,
    """                    subtitle: strings.isPersian\n                        ? 'تصویر، ویدیو، صدا و فایل با رمزگذاری قبل از آپلود'\n                        : 'Images, video, audio and files encrypted before upload',""",
    """                    subtitle: strings.isPersian\n                        ? 'تصویر، ویدیو نوت، پیام صوتی، موسیقی، موقعیت و فایل؛ رمزگذاری قبل از آپلود'\n                        : 'Images, video notes, voice notes, music, location and files; encrypted before upload',""",
)
replace_once(
    settings,
    """                    subtitle: strings.isPersian\n                        ? 'تماس صوتی و تصویری امن یک‌به‌یک'\n                        : 'Secure one-to-one audio and video calling',""",
    """                    subtitle: strings.isPersian\n                        ? 'تماس امن یک‌به‌یک با بلندگو و تعویض دوربین؛ جلسه گروهی نیازمند پروتکل/SFU سرور است'\n                        : 'Secure 1:1 calls with speaker and camera switching; meetings require server SFU/protocol support',""",
)


# Message bubble: route rich encrypted media through the dedicated renderer.
bubble = ROOT / "flutter/lib/features/messages/presentation/widgets/message_bubble.dart"
replace_once(
    bubble,
    "import 'package:chatnu/features/messages/domain/message.dart';\n",
    "import 'package:chatnu/features/messages/domain/message.dart';\nimport 'package:chatnu/features/messages/presentation/widgets/rich_message_content.dart';\n",
)
replace_once(
    bubble,
    """              if (message.type == ChatNuMessageType.text ||\n                  !message.hasAttachment)\n                Directionality(\n                  textDirection: directionForText(message.body),\n                  child: Text(\n                    message.body,\n                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(\n                      color: mine ? Colors.black : palette.textPrimary,\n                    ),\n                  ),\n                )\n              else\n                _AttachmentContent(message: message, mine: mine),""",
    """              if (message.type == ChatNuMessageType.text ||\n                  message.type == ChatNuMessageType.system ||\n                  (message.type == ChatNuMessageType.location &&\n                      !message.hasLocation))\n                Directionality(\n                  textDirection: directionForText(message.body),\n                  child: Text(\n                    message.body,\n                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(\n                      color: mine ? Colors.black : palette.textPrimary,\n                    ),\n                  ),\n                )\n              else\n                RichMessageContent(message: message, mine: mine),""",
)
text = bubble.read_text()
start = text.find("class _AttachmentContent extends ConsumerWidget {")
end = text.find("class DeliveryStatus extends StatelessWidget {")
if start < 0 or end < 0 or end <= start:
    raise SystemExit("AttachmentContent block not found")
bubble.write_text(text[:start] + text[end:])


# Call controller: add native speaker route and camera switching without changing signaling.
calls = ROOT / "flutter/lib/features/calls/application/call_controller.dart"
replace_once(
    calls,
    """    this.cameraEnabled = true,\n    this.localStream,""",
    """    this.cameraEnabled = true,\n    this.speakerOn = false,\n    this.localStream,""",
)
replace_once(
    calls,
    """  final bool cameraEnabled;\n  final MediaStream? localStream;""",
    """  final bool cameraEnabled;\n  final bool speakerOn;\n  final MediaStream? localStream;""",
)
replace_once(
    calls,
    """    bool? cameraEnabled,\n    MediaStream? localStream,""",
    """    bool? cameraEnabled,\n    bool? speakerOn,\n    MediaStream? localStream,""",
)
replace_once(
    calls,
    """      cameraEnabled: cameraEnabled ?? this.cameraEnabled,\n      localStream: localStream ?? this.localStream,""",
    """      cameraEnabled: cameraEnabled ?? this.cameraEnabled,\n      speakerOn: speakerOn ?? this.speakerOn,\n      localStream: localStream ?? this.localStream,""",
)
replace_once(
    calls,
    """  void toggleCamera() {\n    if (!state.video) return;\n    final next = !state.cameraEnabled;\n    for (final track\n        in _localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) {\n      track.enabled = next;\n    }\n    state = state.copyWith(cameraEnabled: next);\n  }\n\n  Future<void> _preparePeer""",
    """  void toggleCamera() {\n    if (!state.video) return;\n    final next = !state.cameraEnabled;\n    for (final track\n        in _localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) {\n      track.enabled = next;\n    }\n    state = state.copyWith(cameraEnabled: next);\n  }\n\n  Future<void> toggleSpeaker() async {\n    final next = !state.speakerOn;\n    try {\n      await Helper.setSpeakerphoneOn(next);\n      state = state.copyWith(speakerOn: next);\n    } catch (error) {\n      state = state.copyWith(error: error.toString());\n    }\n  }\n\n  Future<void> switchCamera() async {\n    if (!state.video) return;\n    final tracks = _localStream?.getVideoTracks() ?? <MediaStreamTrack>[];\n    if (tracks.isEmpty) return;\n    try {\n      await Helper.switchCamera(tracks.first, null, _localStream);\n    } catch (error) {\n      state = state.copyWith(error: error.toString());\n    }\n  }\n\n  Future<void> _preparePeer""",
)
replace_once(
    calls,
    """  Future<void> _disposePeer() async {\n    final peer = _peer;""",
    """  Future<void> _disposePeer() async {\n    try {\n      await Helper.setSpeakerphoneOn(false);\n      await Helper.clearAndroidCommunicationDevice();\n    } catch (_) {}\n    final peer = _peer;""",
)


# Call overlay: surface supported local media controls.
overlay = ROOT / "flutter/lib/features/calls/presentation/call_overlay.dart"
replace_once(
    overlay,
    """        if (state.video) ...<Widget>[\n          const SizedBox(width: ChatNuSpacing.xs),\n          _CallControlButton(\n            tooltip: state.cameraEnabled ? 'Camera off' : 'Camera on',\n            icon: state.cameraEnabled\n                ? Icons.videocam_rounded\n                : Icons.videocam_off_rounded,\n            selected: !state.cameraEnabled,\n            onPressed: ref.read(callControllerProvider.notifier).toggleCamera,\n          ),\n        ],\n        const SizedBox(width: ChatNuSpacing.md),""",
    """        const SizedBox(width: ChatNuSpacing.xs),\n        _CallControlButton(\n          tooltip: state.speakerOn ? 'Speaker off' : 'Speaker on',\n          icon: state.speakerOn ? Icons.volume_up_rounded : Icons.hearing_rounded,\n          selected: state.speakerOn,\n          onPressed: () => unawaited(\n            ref.read(callControllerProvider.notifier).toggleSpeaker(),\n          ),\n        ),\n        if (state.video) ...<Widget>[\n          const SizedBox(width: ChatNuSpacing.xs),\n          _CallControlButton(\n            tooltip: state.cameraEnabled ? 'Camera off' : 'Camera on',\n            icon: state.cameraEnabled\n                ? Icons.videocam_rounded\n                : Icons.videocam_off_rounded,\n            selected: !state.cameraEnabled,\n            onPressed: ref.read(callControllerProvider.notifier).toggleCamera,\n          ),\n          const SizedBox(width: ChatNuSpacing.xs),\n          _CallControlButton(\n            tooltip: 'Switch camera',\n            icon: Icons.cameraswitch_rounded,\n            onPressed: () => unawaited(\n              ref.read(callControllerProvider.notifier).switchCamera(),\n            ),\n          ),\n        ],\n        const SizedBox(width: ChatNuSpacing.md),""",
)
