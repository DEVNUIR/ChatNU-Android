import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:camera/camera.dart';
import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum _RecordMode { voice, video }

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

class _MessageComposerState extends ConsumerState<MessageComposer>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  late final AnimationController _recordPulse;

  _RecordMode _recordMode = _RecordMode.voice;
  CameraController? _cameraController;
  Timer? _recordTimer;
  DateTime? _recordStartedAt;
  Duration _elapsed = Duration.zero;
  bool _holding = false;
  bool _arming = false;
  bool _recording = false;
  bool _finishing = false;
  bool _cancelArmed = false;

  static const _maxVoiceDuration = Duration(minutes: 5);
  static const _maxVideoDuration = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _recordPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
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
    _recordTimer?.cancel();
    _recordPulse.dispose();
    unawaited(_audioRecorder.dispose());
    unawaited(_disposeCamera());
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
    final busyRecording = _arming || _recording || _finishing;

    return GlassSurface(
      variant: GlassVariant.strong,
      enableBlur: true,
      borderRadius: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 9, 8, 9),
          decoration: BoxDecoration(
            color: palette.backgroundElevated.withValues(alpha: 0.5),
            border: Border(top: BorderSide(color: palette.borderSubtle)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              AnimatedOpacity(
                duration: ChatNuMotion.micro,
                opacity: busyRecording ? 0.42 : 1,
                child: IconButton(
                  key: const Key('message-attach-button'),
                  tooltip: strings.attach,
                  onPressed: demo || busyRecording
                      ? null
                      : () => unawaited(_showAttachmentSheet()),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(46, 46),
                    backgroundColor: palette.glassWeak,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 27),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : ChatNuMotion.fast,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: busyRecording
                      ? _RecordingStatus(
                          key: const ValueKey<String>('recording-status'),
                          mode: _recordMode,
                          elapsed: _elapsed,
                          arming: _arming,
                          finishing: _finishing,
                          cancelArmed: _cancelArmed,
                          cameraController: _cameraController,
                          pulse: _recordPulse,
                        )
                      : _ComposerField(
                          key: const ValueKey<String>('composer-field'),
                          controller: widget.controller,
                          hintText: strings.messageHint,
                        ),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : ChatNuMotion.fast,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: canSend && !busyRecording
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
                    : _HoldRecordButton(
                        key: ValueKey<String>('record-${_recordMode.name}'),
                        mode: _recordMode,
                        enabled: !demo && !_finishing,
                        recording: _recording || _arming,
                        cancelArmed: _cancelArmed,
                        onTap: _toggleRecordMode,
                        onLongPressStart: _startHold,
                        onLongPressMoveUpdate: _updateHold,
                        onLongPressEnd: _endHold,
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
    ref
        .read(messengerDemoProvider.notifier)
        .sendText(widget.conversationId, value);
    widget.controller.clear();
  }

  void _toggleRecordMode() {
    if (_arming || _recording || _finishing) return;
    setState(() {
      _recordMode = _recordMode == _RecordMode.voice
          ? _RecordMode.video
          : _RecordMode.voice;
    });
  }

  void _startHold(LongPressStartDetails details) {
    if (_arming || _recording || _finishing) return;
    _holding = true;
    _cancelArmed = false;
    unawaited(_startRecording());
  }

  void _updateHold(LongPressMoveUpdateDetails details) {
    if (!_holding || (!_arming && !_recording)) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final cancelDistance = rtl
        ? details.offsetFromOrigin.dx
        : -details.offsetFromOrigin.dx;
    final next = cancelDistance > 72;
    if (next != _cancelArmed && mounted) {
      setState(() => _cancelArmed = next);
    }
  }

  void _endHold(LongPressEndDetails details) {
    _holding = false;
    if (_arming) return;
    if (_recording) {
      unawaited(_finishRecording(cancel: _cancelArmed));
    }
  }

  Future<void> _startRecording() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _arming = true;
      _elapsed = Duration.zero;
    });
    try {
      if (_recordMode == _RecordMode.voice) {
        await _startVoiceRecording();
      } else {
        await _startVideoRecording();
      }
      if (!mounted) return;
      setState(() {
        _arming = false;
        _recording = true;
      });
      _recordStartedAt = DateTime.now();
      _recordPulse.repeat(reverse: true);
      _recordTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
        if (!mounted || !_recording) return;
        final started = _recordStartedAt;
        if (started == null) return;
        final elapsed = DateTime.now().difference(started);
        final maximum = _recordMode == _RecordMode.voice
            ? _maxVoiceDuration
            : _maxVideoDuration;
        setState(() => _elapsed = elapsed);
        if (elapsed >= maximum) {
          _holding = false;
          unawaited(_finishRecording(cancel: false));
        }
      });
      if (!_holding) {
        await _finishRecording(cancel: _cancelArmed);
      }
    } catch (error) {
      await _abortRecording();
      if (!mounted) return;
      _showError(_readableRecordingError(error));
    }
  }

  Future<void> _startVoiceRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      throw StateError('Microphone permission is required to record a voice message.');
    }
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/chatnu-voice-${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 96000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
  }

  Future<void> _startVideoRecording() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No camera is available on this device.');
    }
    final front = cameras.where(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    final description = front.isNotEmpty ? front.first : cameras.first;
    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: true,
    );
    _cameraController = controller;
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      _cameraController = null;
      return;
    }
    setState(() {});
    await controller.startVideoRecording();
  }

  Future<void> _finishRecording({required bool cancel}) async {
    if (_finishing) return;
    _recordTimer?.cancel();
    _recordTimer = null;
    _recordPulse
      ..stop()
      ..value = 0;
    final duration = _recordStartedAt == null
        ? _elapsed
        : DateTime.now().difference(_recordStartedAt!);
    setState(() {
      _finishing = true;
      _recording = false;
      _arming = false;
    });

    try {
      if (_recordMode == _RecordMode.voice) {
        final path = cancel
            ? await _cancelVoiceRecording()
            : await _audioRecorder.stop();
        if (!cancel && path != null && path.isNotEmpty) {
          final file = File(path);
          final bytes = await file.readAsBytes();
          if (mounted) {
            await ref
                .read(messengerDemoProvider.notifier)
                .sendAttachment(
                  conversationId: widget.conversationId,
                  bytes: bytes,
                  fileName: file.uri.pathSegments.last,
                  mimeType:
                      lookupMimeType(path, headerBytes: bytes) ?? 'audio/mp4',
                  type: ChatNuMessageType.voice,
                  privateMetadata: <String, dynamic>{
                    'durationMs': duration.inMilliseconds,
                  },
                );
          }
          unawaited(file.delete().catchError((_) => file));
        }
      } else {
        await _finishVideoRecording(cancel: cancel, duration: duration);
      }
    } catch (error) {
      if (mounted) _showError(_readableRecordingError(error));
    } finally {
      await _disposeCamera();
      if (!mounted) return;
      setState(() {
        _finishing = false;
        _cancelArmed = false;
        _elapsed = Duration.zero;
        _recordStartedAt = null;
      });
    }
  }

  Future<String?> _cancelVoiceRecording() async {
    await _audioRecorder.cancel();
    return null;
  }

  Future<void> _finishVideoRecording({
    required bool cancel,
    required Duration duration,
  }) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    XFile? video;
    if (controller.value.isRecordingVideo) {
      video = await controller.stopVideoRecording();
    }
    if (video == null) return;
    if (cancel) {
      final file = File(video.path);
      unawaited(file.delete().catchError((_) => file));
      return;
    }
    final bytes = await video.readAsBytes();
    if (!mounted) return;
    await ref
        .read(messengerDemoProvider.notifier)
        .sendAttachment(
          conversationId: widget.conversationId,
          bytes: bytes,
          fileName: video.name.isEmpty
              ? 'video-note-${DateTime.now().millisecondsSinceEpoch}.mp4'
              : video.name,
          mimeType:
              lookupMimeType(video.path, headerBytes: bytes) ?? 'video/mp4',
          type: ChatNuMessageType.video,
          privateMetadata: <String, dynamic>{
            'videoNote': true,
            'durationMs': duration.inMilliseconds,
          },
        );
    final file = File(video.path);
    unawaited(file.delete().catchError((_) => file));
  }

  Future<void> _abortRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    _recordPulse
      ..stop()
      ..value = 0;
    try {
      await _audioRecorder.cancel();
    } catch (_) {}
    final camera = _cameraController;
    if (camera != null) {
      try {
        if (camera.value.isRecordingVideo) {
          final video = await camera.stopVideoRecording();
          final file = File(video.path);
          unawaited(file.delete().catchError((_) => file));
        }
      } catch (_) {}
    }
    await _disposeCamera();
    if (!mounted) return;
    setState(() {
      _holding = false;
      _arming = false;
      _recording = false;
      _finishing = false;
      _cancelArmed = false;
      _elapsed = Duration.zero;
      _recordStartedAt = null;
    });
  }

  Future<void> _disposeCamera() async {
    final camera = _cameraController;
    _cameraController = null;
    if (camera != null) {
      try {
        await camera.dispose();
      } catch (_) {}
    }
  }

  Future<void> _showAttachmentSheet() async {
    FocusScope.of(context).unfocus();
    final strings = ChatNuStrings.of(context);
    final choice = await showModalBottomSheet<_AttachmentChoice>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
      transitionAnimationController: null,
      builder: (sheetContext) => SizedBox(
        width: double.infinity,
        child: GlassSheet(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: _AttachmentSheet(
                persian: strings.isPersian,
                onSelected: (value) => Navigator.of(sheetContext).pop(value),
              ),
            ),
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case _AttachmentChoice.gallery:
        await _pickGallery();
      case _AttachmentChoice.camera:
        await _capturePhoto();
      case _AttachmentChoice.audio:
        await _pickAudio();
      case _AttachmentChoice.location:
        await _shareLocation();
      case _AttachmentChoice.file:
        await _pickFile();
    }
  }

  Future<void> _pickGallery() async {
    final file = await ImagePicker().pickMedia();
    if (file == null) return;
    await _sendPickedXFile(file);
  }

  Future<void> _capturePhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
    );
    if (file == null) return;
    await _sendPickedXFile(file, forcedType: ChatNuMessageType.image);
  }

  Future<void> _sendPickedXFile(
    XFile file, {
    ChatNuMessageType? forcedType,
  }) async {
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final mimeType =
        lookupMimeType(file.name, headerBytes: bytes) ??
        lookupMimeType(file.path, headerBytes: bytes) ??
        'application/octet-stream';
    final type =
        forcedType ??
        (mimeType.startsWith('image/')
            ? ChatNuMessageType.image
            : mimeType.startsWith('video/')
            ? ChatNuMessageType.video
            : ChatNuMessageType.file);
    await ref
        .read(messengerDemoProvider.notifier)
        .sendAttachment(
          conversationId: widget.conversationId,
          bytes: bytes,
          fileName: file.name,
          mimeType: mimeType,
          type: type,
        );
  }

  Future<void> _pickAudio() async {
    final file = await FilePicker.pickFile(type: FileType.audio);
    if (file == null) return;
    await _sendPlatformFile(file);
  }

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return;
    await _sendPlatformFile(file);
  }

  Future<void> _sendPlatformFile(PlatformFile file) async {
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final mimeType =
        lookupMimeType(file.name, headerBytes: bytes) ??
        'application/octet-stream';
    final type = mimeType.startsWith('image/')
        ? ChatNuMessageType.image
        : mimeType.startsWith('video/')
        ? ChatNuMessageType.video
        : ChatNuMessageType.file;
    await ref
        .read(messengerDemoProvider.notifier)
        .sendAttachment(
          conversationId: widget.conversationId,
          bytes: bytes,
          fileName: file.name,
          mimeType: mimeType,
          type: type,
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
      await ref
          .read(messengerDemoProvider.notifier)
          .sendLocation(
            conversationId: widget.conversationId,
            latitude: position.latitude,
            longitude: position.longitude,
          );
    } catch (error) {
      if (mounted) _showError(error.toString());
    }
  }

  String _readableRecordingError(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '');
    return message.replaceFirst('StateError: ', '');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ComposerField extends StatelessWidget {
  const _ComposerField({
    required this.controller,
    required this.hintText,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Container(
      decoration: BoxDecoration(
        color: palette.backgroundElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 132),
        child: TextField(
          key: const Key('message-composer-field'),
          controller: controller,
          minLines: 1,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: hintText,
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
    );
  }
}

class _RecordingStatus extends StatelessWidget {
  const _RecordingStatus({
    required this.mode,
    required this.elapsed,
    required this.arming,
    required this.finishing,
    required this.cancelArmed,
    required this.cameraController,
    required this.pulse,
    super.key,
  });

  final _RecordMode mode;
  final Duration elapsed;
  final bool arming;
  final bool finishing;
  final bool cancelArmed;
  final CameraController? cameraController;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final camera = cameraController;
    final previewReady =
        mode == _RecordMode.video &&
        camera != null &&
        camera.value.isInitialized;
    final foreground = cancelArmed ? palette.destructive : palette.textPrimary;

    return AnimatedContainer(
      duration: ChatNuMotion.micro,
      height: 46,
      padding: const EdgeInsetsDirectional.fromSTEB(9, 5, 12, 5),
      decoration: BoxDecoration(
        color: cancelArmed
            ? palette.destructive.withValues(alpha: 0.09)
            : palette.backgroundElevated.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: cancelArmed
              ? palette.destructive.withValues(alpha: 0.34)
              : palette.borderSubtle,
        ),
      ),
      child: Row(
        children: <Widget>[
          if (previewReady)
            ClipOval(
              child: SizedBox.square(
                dimension: 36,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: camera.value.previewSize?.height ?? 1,
                    height: camera.value.previewSize?.width ?? 1,
                    child: CameraPreview(camera),
                  ),
                ),
              ),
            )
          else
            AnimatedBuilder(
              animation: pulse,
              builder: (context, _) => _VoiceActivity(
                phase: pulse.value,
                color: foreground,
                loading: arming,
              ),
            ),
          const SizedBox(width: 9),
          Text(
            _durationLabel(elapsed),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: ChatNuMotion.micro,
              child: Text(
                key: ValueKey<String>(
                  '$arming-$finishing-$cancelArmed-${mode.name}',
                ),
                cancelArmed
                    ? (strings.isPersian
                          ? 'رها کنید تا لغو شود'
                          : 'Release to cancel')
                    : finishing
                    ? (strings.isPersian ? 'در حال ارسال…' : 'Sending…')
                    : arming
                    ? (strings.isPersian
                          ? 'در حال آماده‌سازی…'
                          : 'Preparing…')
                    : (strings.isPersian
                          ? 'برای لغو به چپ بکشید'
                          : 'Slide left to cancel'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cancelArmed ? palette.destructive : palette.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _durationLabel(Duration duration) {
    final total = duration.inSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _VoiceActivity extends StatelessWidget {
  const _VoiceActivity({
    required this.phase,
    required this.color,
    required this.loading,
  });

  final double phase;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox.square(
        dimension: 34,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
      );
    }
    return SizedBox(
      width: 34,
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List<Widget>.generate(5, (index) {
          final wave = math.sin((phase * math.pi * 2) + index * 0.9).abs();
          return Container(
            width: 2.4,
            height: 7 + (wave * 18),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }
}

class _HoldRecordButton extends StatelessWidget {
  const _HoldRecordButton({
    required this.mode,
    required this.enabled,
    required this.recording,
    required this.cancelArmed,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
    super.key,
  });

  final _RecordMode mode;
  final bool enabled;
  final bool recording;
  final bool cancelArmed;
  final VoidCallback onTap;
  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressMoveUpdateCallback onLongPressMoveUpdate;
  final GestureLongPressEndCallback onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final icon = mode == _RecordMode.voice
        ? Icons.mic_rounded
        : Icons.videocam_rounded;
    final tooltip = mode == _RecordMode.voice
        ? (strings.isPersian
              ? 'صدا؛ لمس برای ویدیو، نگه‌دارید برای ضبط'
              : 'Voice; tap for video, hold to record')
        : (strings.isPersian
              ? 'ویدیو؛ لمس برای صدا، نگه‌دارید برای ضبط'
              : 'Video; tap for voice, hold to record');

    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          onLongPressStart: enabled ? onLongPressStart : null,
          onLongPressMoveUpdate: enabled ? onLongPressMoveUpdate : null,
          onLongPressEnd: enabled ? onLongPressEnd : null,
          child: AnimatedContainer(
            duration: ChatNuMotion.micro,
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: recording
                  ? cancelArmed
                        ? palette.destructive
                        : palette.accentPrimary
                  : palette.glassWeak,
              border: Border.all(
                color: recording
                    ? Colors.white.withValues(alpha: 0.18)
                    : palette.borderSubtle,
              ),
              boxShadow: recording
                  ? <BoxShadow>[
                      BoxShadow(
                        color: (cancelArmed
                                ? palette.destructive
                                : palette.accentPrimary)
                            .withValues(alpha: 0.24),
                        blurRadius: 18,
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: AnimatedSwitcher(
              duration: ChatNuMotion.micro,
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween<double>(begin: 0.88, end: 1).animate(animation),
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Icon(
                icon,
                key: ValueKey<_RecordMode>(mode),
                size: 22,
                color: recording ? Colors.white : palette.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _AttachmentChoice { gallery, camera, audio, location, file }

class _AttachmentSheet extends StatelessWidget {
  const _AttachmentSheet({
    required this.persian,
    required this.onSelected,
  });

  final bool persian;
  final ValueChanged<_AttachmentChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final items = <(_AttachmentChoice, IconData, String, String)>[
      (
        _AttachmentChoice.gallery,
        Icons.photo_library_outlined,
        persian ? 'گالری' : 'Gallery',
        persian ? 'عکس یا ویدیو' : 'Photo or video',
      ),
      (
        _AttachmentChoice.camera,
        Icons.photo_camera_outlined,
        persian ? 'دوربین' : 'Camera',
        persian ? 'گرفتن عکس' : 'Take a photo',
      ),
      (
        _AttachmentChoice.audio,
        Icons.audio_file_outlined,
        persian ? 'صدا' : 'Audio',
        persian ? 'فایل صوتی' : 'Audio file',
      ),
      (
        _AttachmentChoice.location,
        Icons.location_on_outlined,
        persian ? 'موقعیت' : 'Location',
        persian ? 'موقعیت فعلی' : 'Current location',
      ),
      (
        _AttachmentChoice.file,
        Icons.insert_drive_file_outlined,
        persian ? 'فایل' : 'File',
        persian ? 'سند یا فایل دیگر' : 'Document or other file',
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: palette.borderHighlight,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        Text(
          persian ? 'ارسال پیوست' : 'Share with chat',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          persian
              ? 'محتوای پیوست پیش از آپلود رمز می‌شود.'
              : 'Attachment content is encrypted before upload.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: ChatNuSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 560 ? 5 : 3;
            final width =
                (constraints.maxWidth - ((columns - 1) * 8)) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: width,
                      child: _AttachmentTile(
                        icon: item.$2,
                        title: item.$3,
                        subtitle: item.$4,
                        onTap: () => onSelected(item.$1),
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ChatNuRadii.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.glassWeak,
            borderRadius: BorderRadius.circular(ChatNuRadii.md),
            border: Border.all(color: palette.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 23, color: palette.textPrimary),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
