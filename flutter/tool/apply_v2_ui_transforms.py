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
text = text[:start] + text[end:]
text = text.replace("import 'package:file_picker/file_picker.dart';\n", "", 1)
bubble.write_text(text)


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


# Analyzer/API compatibility fixes for file_picker 12 and Flutter 3.44.
contacts = ROOT / "flutter/lib/features/contacts/application/contact_book_controller.dart"
contacts_text = contacts.read_text().replace(
    "if (ref.mounted) state = const ContactBookState(loading: false);",
    "if (ref.mounted) {\n          state = const ContactBookState(loading: false);\n        }",
)
contacts.write_text(contacts_text)

composer = ROOT / "flutter/lib/features/messages/presentation/widgets/message_composer.dart"
replace_once(
    composer,
    """    final result = await FilePicker.platform.pickFiles(\n      type: fileType,\n      allowMultiple: false,\n      withData: true,\n    );\n    if (result == null || result.files.isEmpty) return;\n    final file = result.files.single;\n    final bytes = file.bytes;\n    if (bytes == null || !mounted) return;""",
    """    final file = await FilePicker.pickFile(type: fileType);\n    if (file == null) return;\n    final bytes = await file.readAsBytes();\n    if (!mounted) return;""",
)

rich = ROOT / "flutter/lib/features/messages/presentation/widgets/rich_message_content.dart"
replace_once(
    rich,
    """    if (message.hasLocation) return _LocationMessage(message: message, mine: mine);""",
    """    if (message.hasLocation) {\n      return _LocationMessage(message: message, mine: mine);\n    }""",
)
rich_text = rich.read_text().replace("FilePicker.platform.saveFile(", "FilePicker.saveFile(")
rich.write_text(rich_text)

actions = ROOT / "flutter/lib/features/settings/presentation/settings_action_sheets.dart"
replace_once(
    actions,
    """    final result = await FilePicker.platform.pickFiles(\n      type: FileType.image,\n      allowMultiple: false,\n      withData: true,\n    );\n    if (result == null || result.files.isEmpty) return;\n    final file = result.files.single;\n    final bytes = file.bytes;\n    if (bytes == null) {\n      setState(() => _error = 'Unable to read the selected image.');\n      return;\n    }""",
    """    final file = await FilePicker.pickFile(type: FileType.image);\n    if (file == null) return;\n    final bytes = await file.readAsBytes();""",
)
replace_once(
    actions,
    """          ...choices.entries.map(\n            (entry) => RadioListTile<ChatWallpaperStyle>(\n              value: entry.key,\n              groupValue: selected,\n              secondary: Icon(entry.value.icon),\n              title: Text(entry.value.title),\n              onChanged: (value) {\n                if (value == null) return;\n                unawaited(\n                  ref.read(appearanceProvider.notifier).setWallpaperStyle(value),\n                );\n              },\n            ),\n          ),""",
    """          ...choices.entries.map(\n            (entry) => ListTile(\n              leading: Icon(entry.value.icon),\n              title: Text(entry.value.title),\n              trailing: selected == entry.key\n                  ? const Icon(Icons.check_circle_rounded)\n                  : const Icon(Icons.circle_outlined),\n              selected: selected == entry.key,\n              onTap: () => unawaited(\n                ref.read(appearanceProvider.notifier).setWallpaperStyle(entry.key),\n              ),\n            ),\n          ),""",
)
