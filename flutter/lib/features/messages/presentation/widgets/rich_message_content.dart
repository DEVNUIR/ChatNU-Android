import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
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
      final identity = _senderIdentity(ref, message);
      return _LocationMessage(
        message: message,
        mine: mine,
        senderName: identity.name,
        senderAvatarUrl: identity.avatarUrl,
      );
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

  ({String name, String? avatarUrl}) _senderIdentity(
    WidgetRef ref,
    ChatNuMessage message,
  ) {
    final state = ref.watch(messengerDemoProvider);
    ChatNuUser? user;
    if (state.currentUser.id == message.senderId) {
      user = state.currentUser;
    } else {
      final conversation = state.conversations
          .where((item) => item.id == message.conversationId)
          .firstOrNull;
      if (conversation != null) {
        user = conversation.members
            .where((member) => member.id == message.senderId)
            .firstOrNull;
      }
    }
    return (
      name: user?.displayName ?? message.senderName,
      avatarUrl: user?.avatarUrl,
    );
  }
}

class _LocationMessage extends StatelessWidget {
  const _LocationMessage({
    required this.message,
    required this.mine,
    required this.senderName,
    required this.senderAvatarUrl,
  });

  final ChatNuMessage message;
  final bool mine;
  final String senderName;
  final String? senderAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final latitude = message.locationLatitude!;
    final longitude = message.locationLongitude!;
    final center = LatLng(latitude, longitude);
    final foreground = mine ? Colors.black : palette.textPrimary;
    final secondary = mine
        ? Colors.black.withValues(alpha: 0.62)
        : palette.textMuted;

    return SizedBox(
      width: 292,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              GlassAvatar(
                label: senderName,
                imageUrl: senderAvatarUrl,
                size: 34,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      strings.isPersian
                          ? 'موقعیت اشتراک‌گذاری‌شده'
                          : 'Shared location',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: secondary),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.location_on_rounded,
                size: 18,
                color: foreground.withValues(alpha: 0.75),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(ChatNuRadii.md),
              onTap: () => _openMap(
                context,
                center: center,
                senderName: senderName,
                senderAvatarUrl: senderAvatarUrl,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ChatNuRadii.md),
                child: SizedBox(
                  height: 176,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 15,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: <Widget>[
                          _osmTiles(),
                          MarkerLayer(
                            markers: <Marker>[
                              Marker(
                                point: center,
                                width: 62,
                                height: 70,
                                child: _PersonLocationMarker(
                                  senderName: senderName,
                                  avatarUrl: senderAvatarUrl,
                                ),
                              ),
                            ],
                          ),
                          _mapAttribution(),
                        ],
                      ),
                      PositionedDirectional(
                        end: 8,
                        top: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: palette.backgroundElevated.withValues(
                              alpha: 0.82,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: palette.borderSubtle),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.open_in_full_rounded, size: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: foreground),
          ),
          Text(
            '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: secondary),
          ),
        ],
      ),
    );
  }

  void _openMap(
    BuildContext context, {
    required LatLng center,
    required String senderName,
    required String? senderAvatarUrl,
  }) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 220),
        reverseTransitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) =>
            _LocationMapPage(
              center: center,
              senderName: senderName,
              senderAvatarUrl: senderAvatarUrl,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _LocationMapPage extends StatelessWidget {
  const _LocationMapPage({
    required this.center,
    required this.senderName,
    required this.senderAvatarUrl,
  });

  final LatLng center;
  final String senderName;
  final String? senderAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return Scaffold(
      backgroundColor: palette.backgroundPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16,
              minZoom: 3,
              maxZoom: 19,
            ),
            children: <Widget>[
              _osmTiles(),
              MarkerLayer(
                markers: <Marker>[
                  Marker(
                    point: center,
                    width: 72,
                    height: 80,
                    child: _PersonLocationMarker(
                      senderName: senderName,
                      avatarUrl: senderAvatarUrl,
                      large: true,
                    ),
                  ),
                ],
              ),
              _mapAttribution(),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(ChatNuSpacing.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: GlassSurface(
                    variant: GlassVariant.strong,
                    enableBlur: true,
                    borderRadius: ChatNuRadii.xl,
                    padding: const EdgeInsets.all(ChatNuSpacing.xs),
                    child: Row(
                      children: <Widget>[
                        GlassIconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icons.arrow_back_ios_new_rounded,
                        ),
                        const SizedBox(width: 6),
                        GlassAvatar(
                          label: senderName,
                          imageUrl: senderAvatarUrl,
                          size: 42,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                senderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                strings.isPersian
                                    ? 'موقعیت اشتراک‌گذاری‌شده'
                                    : 'Shared location',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: Text(
                            '${center.latitude.toStringAsFixed(5)}, '
                            '${center.longitude.toStringAsFixed(5)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonLocationMarker extends StatelessWidget {
  const _PersonLocationMarker({
    required this.senderName,
    required this.avatarUrl,
    this.large = false,
  });

  final String senderName;
  final String? avatarUrl;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final avatarSize = large ? 50.0 : 42.0;
    return Align(
      alignment: Alignment.topCenter,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.backgroundElevated,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: GlassAvatar(
              label: senderName,
              imageUrl: avatarUrl,
              size: avatarSize,
            ),
          ),
          Positioned(
            bottom: -9,
            child: Container(
              width: large ? 25 : 22,
              height: large ? 25 : 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accentPrimary,
                border: Border.all(
                  color: palette.backgroundElevated,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.location_on_rounded,
                size: large ? 15 : 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

TileLayer _osmTiles() => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'ir.devnu.chatnu',
);

Widget _mapAttribution() => const RichAttributionWidget(
  showFlutterMapAttribution: false,
  attributions: <SourceAttribution>[
    TextSourceAttribution('© OpenStreetMap contributors'),
  ],
);

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
    if (file != null) {
      unawaited(file.delete().catchError((_) => file));
    }
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
    if (mime.contains('m4a') || mime.contains('mp4a')) return 'm4a';
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
      return Container(
        width: 292,
        padding: const EdgeInsetsDirectional.fromSTEB(2, 2, 2, 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChatNuRadii.md),
          color: widget.mine
              ? Colors.black.withValues(alpha: 0.035)
              : palette.backgroundElevated.withValues(alpha: 0.42),
        ),
        child: AudioPlayerWidget(
          autoLoad: true,
          autoPlay: false,
          audioPath: tempFile!.path,
          audioType: AudioType.directFile,
          playerStyle: PlayerStyle.style2,
          shapeType: PlayIconShapeType.circular,
          textDirection: Directionality.of(context),
          width: 288,
          size: 42,
          showProgressBar: true,
          showTimer: true,
          backgroundColor: Colors.transparent,
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
                : 'Play voice message')
          : (ChatNuStrings.of(context).isPersian ? 'پخش صدا' : 'Play audio'),
      detail: widget.message.mediaDurationMs == null
          ? null
          : _durationLabel(
              Duration(milliseconds: widget.message.mediaDurationMs!),
            ),
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
    controller.addListener(_onTick);
    _controller = controller;
    setState(() {});
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      unawaited(controller.pause());
    } else {
      unawaited(controller.play());
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_onTick);
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return widget.message.isVideoNote
          ? _videoNote(context, controller)
          : _regularVideo(context, controller);
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
                : 'Play video message')
          : (ChatNuStrings.of(context).isPersian ? 'پخش ویدیو' : 'Play video'),
      detail: widget.message.mediaDurationMs == null
          ? null
          : _durationLabel(
              Duration(milliseconds: widget.message.mediaDurationMs!),
            ),
      onPressed: widget.message.hasAttachment ? () => unawaited(_load()) : null,
    );
  }

  Widget _videoNote(BuildContext context, VideoPlayerController controller) {
    final palette = context.chatNu;
    final value = controller.value;
    final duration = value.duration;
    final progress = duration.inMilliseconds <= 0
        ? null
        : (value.position.inMilliseconds / duration.inMilliseconds)
              .clamp(0.0, 1.0)
              .toDouble();
    return SizedBox.square(
      dimension: 226,
      child: GestureDetector(
        onTap: _togglePlayback,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.backgroundPrimary,
                border: Border.all(
                  color: widget.mine
                      ? Colors.black.withValues(alpha: 0.12)
                      : palette.borderSubtle,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _CoverVideo(controller: controller),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  color: Colors.white.withValues(alpha: 0.86),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: value.isPlaying ? 0 : 1,
              duration: ChatNuMotion.micro,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.48),
                ),
                child: Icon(
                  value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(ChatNuRadii.pill),
                ),
                child: Text(
                  _durationLabel(
                    value.position > Duration.zero
                        ? value.position
                        : value.duration,
                  ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _regularVideo(BuildContext context, VideoPlayerController controller) {
    final palette = context.chatNu;
    final aspect = controller.value.aspectRatio == 0
        ? 16 / 9
        : controller.value.aspectRatio;
    return ClipRRect(
      borderRadius: BorderRadius.circular(ChatNuRadii.md),
      child: SizedBox(
        width: 292,
        child: AspectRatio(
          aspectRatio: aspect,
          child: ColoredBox(
            color: palette.backgroundPrimary,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned.fill(child: VideoPlayer(controller)),
                IconButton.filledTonal(
                  onPressed: _togglePlayback,
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 6,
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    colors: VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white.withValues(alpha: 0.35),
                      backgroundColor: Colors.black.withValues(alpha: 0.32),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverVideo extends StatelessWidget {
  const _CoverVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    if (size.width <= 0 || size.height <= 0) {
      return VideoPlayer(controller);
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
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
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final bytes = await ref
        .read(messengerDemoProvider.notifier)
        .downloadAttachment(widget.message);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _bytes = bytes;
      _error = bytes == null ? 'Unable to decrypt this image.' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(ChatNuRadii.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 292, maxHeight: 370),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              width: 220,
              height: 120,
              child: Center(child: Icon(Icons.broken_image_outlined)),
            ),
          ),
        ),
      );
    }
    return _LoadMediaTile(
      message: widget.message,
      mine: widget.mine,
      loading: _loading,
      error: _error,
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
      detail: _sizeLabel(message.sizeBytes),
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
    this.detail,
    this.loading = false,
    this.error,
    this.onPressed,
  });

  final ChatNuMessage message;
  final bool mine;
  final IconData icon;
  final String label;
  final String? detail;
  final bool loading;
  final String? error;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final foreground = mine ? Colors.black : palette.textPrimary;
    final secondary = mine
        ? Colors.black.withValues(alpha: 0.58)
        : palette.textMuted;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(ChatNuRadii.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: mine
                        ? Colors.black.withValues(alpha: 0.08)
                        : palette.backgroundElevated,
                    borderRadius: BorderRadius.circular(14),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: mine ? foreground : palette.destructive,
                          ),
                        )
                      else if (detail != null)
                        Text(
                          detail!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: secondary),
                        )
                      else if (message.mimeType != null)
                        Text(
                          message.mimeType!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: secondary),
                        ),
                    ],
                  ),
                ),
                if (onPressed != null && !loading)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: secondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _durationLabel(Duration duration) {
  final total = duration.inSeconds;
  final minutes = total ~/ 60;
  final seconds = total % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String? _sizeLabel(int? bytes) {
  if (bytes == null) return null;
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
