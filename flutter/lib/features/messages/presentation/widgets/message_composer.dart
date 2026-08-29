import 'dart:async';
import 'dart:io';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:voice_note_kit/voice_note_kit.dart';

class MessageComposer extends ConsumerStatefulWidget {
  const MessageComposer({
    required this.controller,
    required this.conversationId,
    super.key,
  });

  final TextEditingController controller;
  final String conversationId;

  @override
  ConsumerState<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends ConsumerState<MessageComposer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant MessageComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final demo = ref.watch(appModeProvider) == ChatNuAppMode.demo;
    final canSend = widget.controller.text.trim().isNotEmpty;

    return GlassSurface(
      variant: GlassVariant.strong,
      enableBlur: true,
      borderRadius: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 9, 8, 9),
          decoration: BoxDecoration(
            color: palette.backgroundElevated.withValues(alpha: 0.54),
            border: Border(top: BorderSide(color: palette.borderSubtle)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              IconButton(
                key: const Key('message-attach-button'),
                tooltip: strings.attach,
                onPressed: demo ? null : () => unawaited(_showAttachmentSheet()),
                style: IconButton.styleFrom(
                  minimumSize: const Size(46, 46),
                  backgroundColor: palette.glassWeak,
                ),
                icon: const Icon(Icons.add_rounded, size: 27),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.backgroundElevated.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: palette.borderSubtle),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 132),
                    child: TextField(
                      key: const Key('message-composer-field'),
                      controller: widget.controller,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: strings.messageHint,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                child: canSend
                    ? IconButton.filled(
                        key: const Key('message-send-button'),
                        tooltip: strings.send,
                        style: IconButton.styleFrom(
                          backgroundColor: palette.textPrimary,
                          foregroundColor: palette.backgroundElevated,
                          minimumSize: const Size(46, 46),
                        ),
                        onPressed: _send,
                        icon: const Icon(Icons.arrow_upward_rounded, size: 22),
                      )
                    : IconButton(
                        key: const ValueKey<String>('composer-voice-note'),
                        tooltip: strings.isPersian ? 'پیام صوتی' : 'Voice note',
                        onPressed: demo ? null : () => unawaited(_recordVoice()),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(46, 46),
                          backgroundColor: palette.glassWeak,
                        ),
                        icon: const Icon(Icons.mic_none_rounded, size: 22),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _send() {
    final value = widget.controller.text;
    if (value.trim().isEmpty) return;
    ref.read(messengerDemoProvider.notifier).sendText(widget.conversationId, value);
    widget.controller.clear();
  }

  Future<void> _showAttachmentSheet() async {
    FocusScope.of(context).unfocus();
    final palette = context.chatNu;
    final persian = Localizations.localeOf(context).languageCode == 'fa';
    final choice = await showModalBottomSheet<_AttachmentChoice>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (context) => GlassSurface(
        variant: GlassVariant.strong,
        enableBlur: true,
        borderRadius: 28,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: palette.borderHighlight,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: <Widget>[
                _AttachmentAction(
                  icon: Icons.photo_rounded,
                  label: persian ? 'عکس' : 'Photo',
                  onTap: () => Navigator.of(context).pop(_AttachmentChoice.photo),
                ),
                _AttachmentAction(
                  icon: Icons.videocam_rounded,
                  label: persian ? 'ویدیو' : 'Video',
                  onTap: () => Navigator.of(context).pop(_AttachmentChoice.video),
                ),
                _AttachmentAction(
                  icon: Icons.music_note_rounded,
                  label: persian ? 'صدا/موسیقی' : 'Audio',
                  onTap: () => Navigator.of(context).pop(_AttachmentChoice.audio),
                ),
                _AttachmentAction(
                  icon: Icons.video_camera_front_outlined,
                  label: persian ? 'ویدیو نوت' : 'Video note',
                  onTap: () =>
                      Navigator.of(context).pop(_AttachmentChoice.videoNote),
                ),
                _AttachmentAction(
                  icon: Icons.location_on_outlined,
                  label: persian ? 'موقعیت' : 'Location',
                  onTap: () => Navigator.of(context).pop(_AttachmentChoice.location),
                ),
                _AttachmentAction(
                  icon: Icons.insert_drive_file_outlined,
                  label: persian ? 'فایل' : 'File',
                  onTap: () => Navigator.of(context).pop(_AttachmentChoice.file),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case _AttachmentChoice.videoNote:
        await _captureVideoNote();
      case _AttachmentChoice.location:
        await _shareLocation();
      case _AttachmentChoice.photo:
      case _AttachmentChoice.video:
      case _AttachmentChoice.audio:
      case _AttachmentChoice.file:
        await _pickAttachment(choice.fileType);
    }
  }

  Future<void> _recordVoice() async {
    FocusScope.of(context).unfocus();
    final palette = context.chatNu;
    final persian = Localizations.localeOf(context).languageCode == 'fa';
    final file = await showModalBottomSheet<File>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GlassSurface(
        variant: GlassVariant.strong,
        enableBlur: true,
        borderRadius: 28,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              persian ? 'پیام صوتی' : 'Voice note',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            VoiceRecorderWidget(
              maxRecordDuration: const Duration(minutes: 5),
              showTimerText: true,
              showSwipeLeftToCancel: true,
              backgroundColor: palette.textPrimary,
              iconColor: palette.backgroundElevated,
              recordingWavesColor: palette.accentPrimary,
              idleWavesColor: palette.textMuted,
              onRecorded: (recorded) => Navigator.of(sheetContext).pop(recorded),
              onError: (error) => ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(content: Text(error)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              persian
                  ? 'صدا قبل از آپلود با کلید تصادفی رمز می‌شود.'
                  : 'Audio is encrypted before upload with a random attachment key.',
              textAlign: TextAlign.center,
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final mimeType = lookupMimeType(file.path, headerBytes: bytes) ?? 'audio/m4a';
    await ref.read(messengerDemoProvider.notifier).sendAttachment(
      conversationId: widget.conversationId,
      bytes: bytes,
      fileName: file.uri.pathSegments.last,
      mimeType: mimeType,
      type: ChatNuMessageType.voice,
    );
    unawaited(file.delete().catchError((_) => file));
  }

  Future<void> _captureVideoNote() async {
    final picked = await ImagePicker().pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final mimeType = lookupMimeType(picked.name, headerBytes: bytes) ?? 'video/mp4';
    await ref.read(messengerDemoProvider.notifier).sendAttachment(
      conversationId: widget.conversationId,
      bytes: bytes,
      fileName: picked.name,
      mimeType: mimeType,
      type: ChatNuMessageType.video,
      privateMetadata: const <String, dynamic>{'videoNote': true},
    );
  }

  Future<void> _shareLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Location services are disabled.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission is not available.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      await ref.read(messengerDemoProvider.notifier).sendLocation(
        conversationId: widget.conversationId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _pickAttachment(FileType fileType) async {
    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || !mounted) return;
    final mimeType =
        lookupMimeType(file.name, headerBytes: bytes) ?? 'application/octet-stream';
    final type = mimeType.startsWith('image/')
        ? ChatNuMessageType.image
        : mimeType.startsWith('video/')
        ? ChatNuMessageType.video
        : ChatNuMessageType.file;
    await ref.read(messengerDemoProvider.notifier).sendAttachment(
      conversationId: widget.conversationId,
      bytes: bytes,
      fileName: file.name,
      mimeType: mimeType,
      type: type,
    );
  }
}

enum _AttachmentChoice { photo, video, audio, videoNote, location, file }

extension on _AttachmentChoice {
  FileType get fileType => switch (this) {
    _AttachmentChoice.photo => FileType.image,
    _AttachmentChoice.video => FileType.video,
    _AttachmentChoice.audio => FileType.audio,
    _AttachmentChoice.file => FileType.any,
    _AttachmentChoice.videoNote || _AttachmentChoice.location => FileType.any,
  };
}

class _AttachmentAction extends StatelessWidget {
  const _AttachmentAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return SizedBox(
      width: 94,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: palette.glassMedium,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(icon, size: 23),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
