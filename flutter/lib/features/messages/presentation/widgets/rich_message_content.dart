import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:voice_note_kit/voice_note_kit.dart';

class RichMessageContent extends ConsumerWidget {
  const RichMessageContent({
    required this.message,
    required this.mine,
    super.key,
  });

  final ChatNuMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.hasLocation) {
      return _LocationMessage(message: message, mine: mine);
    }
    if (message.isPlayableAudio) {
      return _EncryptedAudioMessage(message: message, mine: mine);
    }
    if (message.type == ChatNuMessageType.video ||
        message.type == ChatNuMessageType.viewOnceVideo) {
      return _EncryptedVideoMessage(message: message, mine: mine);
    }
    if (message.type == ChatNuMessageType.image ||
        message.type == ChatNuMessageType.viewOnceImage) {
      return _EncryptedImageMessage(message: message, mine: mine);
    }
    return _EncryptedFileMessage(message: message, mine: mine);
  }
}

class _LocationMessage extends StatelessWidget {
  const _LocationMessage({required this.message, required this.mine});

  final ChatNuMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final latitude = message.locationLatitude!;
    final longitude = message.locationLongitude!;
    final center = LatLng(latitude, longitude);
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(ChatNuRadii.md),
            child: SizedBox(
              height: 170,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: <Widget>[
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'ir.devnu.chatnu',
                  ),
                  MarkerLayer(
                    markers: <Marker>[
                      Marker(
                        point: center,
                        width: 46,
                        height: 46,
                        child: Icon(
                          Icons.location_pin,
                          size: 42,
                          color: palette.destructive,
                        ),
                      ),
                    ],
                  ),
                  const RichAttributionWidget(
                    showFlutterMapAttribution: false,
                    attributions: <SourceAttribution>[
                      TextSourceAttribution('© OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message.body,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: mine ? Colors.black : palette.textPrimary,
            ),
          ),
          Text(
            '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: mine
                  ? Colors.black.withValues(alpha: 0.58)
                  : palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

abstract class _EncryptedMediaState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> {
  bool loading = false;
  String? error;
  File? tempFile;

  Future<File?> decryptToTemp(ChatNuMessage message) async {
    if (tempFile != null) return tempFile;
    setState(() {
      loading = true;
      error = null;
    });
    final bytes = await ref
        .read(messengerDemoProvider.notifier)
        .downloadAttachment(message);
    if (!mounted) return null;
    if (bytes == null) {
      setState(() {
        loading = false;
        error = 'Unable to decrypt this attachment.';
      });
      return null;
    }
    final directory = await getTemporaryDirectory();
    final safeExtension = _extensionFor(message);
    final file = File(
      '${directory.path}/chatnu-${message.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.$safeExtension',
    );
    await file.writeAsBytes(bytes, flush: true);
    if (!mounted) {
      unawaited(file.delete().catchError((_) => file));
      return null;
    }
    tempFile = file;
    setState(() => loading = false);
    return file;
  }

  @override
  void dispose() {
    final file = tempFile;
    if (file != null) unawaited(file.delete().catchError((_) => file));
    super.dispose();
  }

  static String _extensionFor(ChatNuMessage message) {
    final name = message.fileName ?? '';
    final dot = name.lastIndexOf('.');
    if (dot >= 0 && dot < name.length - 1) {
      final raw = name
          .substring(dot + 1)
          .replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      if (raw.isNotEmpty && raw.length <= 8) return raw;
    }
    final mime = message.mimeType?.toLowerCase() ?? '';
    if (mime.contains('mp4')) return 'mp4';
    if (mime.contains('webm')) return 'webm';
    if (mime.contains('mpeg')) return 'mp3';
    if (mime.contains('ogg')) return 'ogg';
    if (mime.contains('wav')) return 'wav';
    if (mime.contains('png')) return 'png';
    if (mime.contains('webp')) return 'webp';
    if (mime.contains('jpeg')) return 'jpg';
    return 'bin';
  }
}

class _EncryptedAudioMessage extends ConsumerStatefulWidget {
  const _EncryptedAudioMessage({required this.message, required this.mine});

  final ChatNuMessage message;
  final bool mine;

  @override
  ConsumerState<_EncryptedAudioMessage> createState() =>
      _EncryptedAudioMessageState();
}

class _EncryptedAudioMessageState
    extends _EncryptedMediaState<_EncryptedAudioMessage> {
  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final foreground = widget.mine ? Colors.black : palette.textPrimary;
    if (tempFile != null) {
      return SizedBox(
        width: 290,
        child: AudioPlayerWidget(
          autoLoad: true,
          autoPlay: false,
          audioPath: tempFile!.path,
          audioType: AudioType.directFile,
          playerStyle: PlayerStyle.style2,
          shapeType: PlayIconShapeType.circular,
          textDirection: Directionality.of(context),
          width: 290,
          size: 42,
          showProgressBar: true,
          showTimer: true,
          backgroundColor: widget.mine
              ? Colors.black.withValues(alpha: 0.08)
              : palette.backgroundElevated,
          progressBarColor: foreground,
          progressBarBackgroundColor: foreground.withValues(alpha: 0.18),
          iconColor: foreground,
        ),
      );
    }
    return _LoadMediaTile(
      message: widget.message,
      mine: widget.mine,
      loading: loading,
      error: error,
      icon: Icons.graphic_eq_rounded,
      label: widget.message.type == ChatNuMessageType.voice
          ? (ChatNuStrings.of(context).isPersian
                ? 'پخش پیام صوتی'
                : 'Play voice note')
          : (ChatNuStrings.of(context).isPersian ? 'پخش صدا' : 'Play audio'),
      onPressed: widget.message.hasAttachment
          ? () => unawaited(decryptToTemp(widget.message))
          : null,
    );
  }
}

class _EncryptedVideoMessage extends ConsumerStatefulWidget {
  const _EncryptedVideoMessage({required this.message, required this.mine});

  final ChatNuMessage message;
  final bool mine;

  @override
  ConsumerState<_EncryptedVideoMessage> createState() =>
      _EncryptedVideoMessageState();
}

class _EncryptedVideoMessageState
    extends _EncryptedMediaState<_EncryptedVideoMessage> {
  VideoPlayerController? _controller;

  Future<void> _load() async {
    final file = await decryptToTemp(widget.message);
    if (file == null || !mounted) return;
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    _controller = controller;
    setState(() {});
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      final player = Stack(
        alignment: Alignment.center,
        children: <Widget>[
          AspectRatio(
            aspectRatio: controller.value.aspectRatio == 0
                ? 1
                : controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          IconButton.filledTonal(
            onPressed: () {
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
              setState(() {});
            },
            icon: Icon(
              controller.value.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
            ),
          ),
        ],
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(
          widget.message.isVideoNote ? 56 : ChatNuRadii.md,
        ),
        child: SizedBox(
          width: widget.message.isVideoNote ? 220 : 290,
          height: widget.message.isVideoNote ? 220 : null,
          child: ColoredBox(color: palette.backgroundPrimary, child: player),
        ),
      );
    }
    return _LoadMediaTile(
      message: widget.message,
      mine: widget.mine,
      loading: loading,
      error: error,
      icon: widget.message.isVideoNote
          ? Icons.video_camera_front_outlined
          : Icons.play_circle_outline_rounded,
      label: widget.message.isVideoNote
          ? (ChatNuStrings.of(context).isPersian
                ? 'پخش ویدیو نوت'
                : 'Play video note')
          : (ChatNuStrings.of(context).isPersian ? 'پخش ویدیو' : 'Play video'),
      onPressed: widget.message.hasAttachment ? () => unawaited(_load()) : null,
    );
  }
}

class _EncryptedImageMessage extends ConsumerStatefulWidget {
  const _EncryptedImageMessage({required this.message, required this.mine});

  final ChatNuMessage message;
  final bool mine;

  @override
  ConsumerState<_EncryptedImageMessage> createState() =>
      _EncryptedImageMessageState();
}

class _EncryptedImageMessageState
    extends ConsumerState<_EncryptedImageMessage> {
  Uint8List? _bytes;
  bool _loading = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    final bytes = await ref
        .read(messengerDemoProvider.notifier)
        .downloadAttachment(widget.message);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _bytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(ChatNuRadii.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 290, maxHeight: 360),
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
      );
    }
    return _LoadMediaTile(
      message: widget.message,
      mine: widget.mine,
      loading: _loading,
      icon: Icons.image_outlined,
      label: ChatNuStrings.of(context).isPersian ? 'نمایش تصویر' : 'View image',
      onPressed: widget.message.hasAttachment ? () => unawaited(_load()) : null,
    );
  }
}

class _EncryptedFileMessage extends ConsumerWidget {
  const _EncryptedFileMessage({required this.message, required this.mine});

  final ChatNuMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ChatNuStrings.of(context);
    return _LoadMediaTile(
      message: message,
      mine: mine,
      icon: Icons.insert_drive_file_outlined,
      label: message.fileName ?? message.body,
      onPressed: message.hasAttachment
          ? () => unawaited(_download(context, ref, strings))
          : null,
    );
  }

  Future<void> _download(
    BuildContext context,
    WidgetRef ref,
    ChatNuStrings strings,
  ) async {
    final bytes = await ref
        .read(messengerDemoProvider.notifier)
        .downloadAttachment(message);
    if (bytes == null || !context.mounted) return;
    final result = await FilePicker.saveFile(
      dialogTitle: strings.attachmentDownload,
      fileName: message.fileName ?? 'attachment',
      bytes: bytes,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == null ? strings.saveCancelled : strings.attachmentSaved,
        ),
      ),
    );
  }
}

class _LoadMediaTile extends StatelessWidget {
  const _LoadMediaTile({
    required this.message,
    required this.mine,
    required this.icon,
    required this.label,
    this.loading = false,
    this.error,
    this.onPressed,
  });

  final ChatNuMessage message;
  final bool mine;
  final IconData icon;
  final String label;
  final bool loading;
  final String? error;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final foreground = mine ? Colors.black : palette.textPrimary;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(ChatNuRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: mine
                      ? Colors.black.withValues(alpha: 0.08)
                      : palette.backgroundElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: loading
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: foreground,
                        ),
                      )
                    : Icon(icon, color: foreground),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: foreground),
                    ),
                    if (error != null)
                      Text(
                        error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.destructive,
                        ),
                      )
                    else if (message.sizeBytes != null)
                      Text(
                        _formatBytes(message.sizeBytes!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: mine
                              ? Colors.black.withValues(alpha: 0.58)
                              : palette.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (onPressed != null && !loading)
                Icon(Icons.chevron_right_rounded, color: foreground),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatBytes(int value) {
    if (value < 1024) return '$value B';
    if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(1)} KiB';
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MiB';
  }
}
