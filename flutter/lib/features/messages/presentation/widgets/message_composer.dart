import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/application/live_location_controller.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:chatnu/features/messages/presentation/recording_session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

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
  final AudioRecorder _audioRecorder = AudioRecorder();

  ChatNuRecordingSession _recordingSession = const ChatNuRecordingSession();
  CameraController? _cameraController;
  OverlayEntry? _videoPreviewOverlay;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _recordTimer;
  DateTime? _lastRecordTick;
  Duration _elapsed = Duration.zero;
  List<double> _waveform = List<double>.filled(30, 0.12);
  bool _holding = false;

  static const _maxVoiceDuration = Duration(minutes: 5);
  static const _maxVideoDuration = Duration(seconds: 60);

  bool get _arming => _recordingSession.phase == ChatNuRecordingPhase.arming;
  bool get _finishing =>
      _recordingSession.phase == ChatNuRecordingPhase.finishing;
  bool get _paused => _recordingSession.isPaused;

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
    _recordTimer?.cancel();
    unawaited(_amplitudeSubscription?.cancel());
    unawaited(_audioRecorder.dispose());
    _removeVideoPreviewOverlay();
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
    final busyRecording = _recordingSession.isActive;

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
                      : ChatNuMotion.component,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: busyRecording
                      ? _RecordingStatus(
                          key: const ValueKey<String>('recording-status'),
                          session: _recordingSession,
                          elapsed: _elapsed,
                          waveform: _waveform,
                          onCancel: () =>
                              unawaited(_finishRecording(cancel: true)),
                          onPauseResume: () => unawaited(
                            _paused ? _resumeRecording() : _pauseRecording(),
                          ),
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
                    : ChatNuMotion.component,
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
                          backgroundColor: palette.accentPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(46, 46),
                        ),
                        onPressed: _send,
                        icon: const Icon(Icons.arrow_upward_rounded, size: 22),
                      )
                    : _HoldRecordButton(
                        key: ValueKey<String>(
                          'record-${_recordingSession.mode.name}',
                        ),
                        mode: _recordingSession.mode,
                        enabled: !demo && !_finishing,
                        recording: busyRecording,
                        cancelArmed: _recordingSession.cancelArmed,
                        onTap: busyRecording
                            ? () => unawaited(_finishRecording(cancel: false))
                            : _toggleRecordMode,
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
    if (!_recordingSession.isIdle) return;
    setState(() {
      _recordingSession = _recordingSession.toggleMode();
    });
    unawaited(HapticFeedback.selectionClick());
  }

  void _startHold(LongPressStartDetails details) {
    if (!_recordingSession.isIdle) return;
    _holding = true;
    FocusScope.of(context).unfocus();
    setState(() {
      _recordingSession = _recordingSession.startArming();
      _elapsed = Duration.zero;
      _waveform = List<double>.filled(30, 0.12);
    });
    unawaited(HapticFeedback.lightImpact());
    unawaited(_startRecording());
  }

  void _updateHold(LongPressMoveUpdateDetails details) {
    if (!_holding || (!_arming && !_recordingSession.isRecording)) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final previousGesture = _recordingSession.gesture;
    final previousPhase = _recordingSession.phase;
    final next = _recordingSession.updateHoldGesture(
      dx: details.offsetFromOrigin.dx,
      dy: details.offsetFromOrigin.dy,
      rtl: rtl,
    );
    if (next == _recordingSession) return;
    if (mounted) setState(() => _recordingSession = next);
    if (next.gesture != previousGesture &&
        next.gesture != ChatNuRecordingGesture.none) {
      unawaited(HapticFeedback.mediumImpact());
    }
    if (previousPhase != ChatNuRecordingPhase.locked &&
        next.phase == ChatNuRecordingPhase.locked) {
      unawaited(HapticFeedback.heavyImpact());
    }
  }

  void _endHold(LongPressEndDetails details) {
    _holding = false;
    if (_arming) return;
    final action = _recordingSession.releaseAction();
    switch (action) {
      case ChatNuRecordingReleaseAction.send:
        unawaited(_finishRecording(cancel: false));
      case ChatNuRecordingReleaseAction.cancel:
        unawaited(_finishRecording(cancel: true));
      case ChatNuRecordingReleaseAction.keepRecording:
      case ChatNuRecordingReleaseAction.none:
        return;
    }
  }

  Future<void> _startRecording() async {
    try {
      if (_recordingSession.mode == ChatNuRecordingMode.voice) {
        await _startVoiceRecording();
      } else {
        await _startVideoRecording();
      }
      if (!mounted) return;
      setState(() {
        _recordingSession = _recordingSession.startHolding();
      });
      _lastRecordTick = DateTime.now();
      _recordTimer = Timer.periodic(const Duration(milliseconds: 160), (_) {
        if (!mounted || !_recordingSession.isRecording) return;
        final now = DateTime.now();
        final previous = _lastRecordTick ?? now;
        _lastRecordTick = now;
        if (_paused) return;
        final elapsed = _elapsed + now.difference(previous);
        final maximum = _recordingSession.mode == ChatNuRecordingMode.voice
            ? _maxVoiceDuration
            : _maxVideoDuration;
        setState(() => _elapsed = elapsed);
        if (elapsed >= maximum) {
          _holding = false;
          unawaited(_finishRecording(cancel: false));
        }
      });

      if (_recordingSession.mode == ChatNuRecordingMode.voice) {
        await _startAmplitudeUpdates();
      }

      if (!_holding) {
        final action = _recordingSession.releaseAction();
        if (action == ChatNuRecordingReleaseAction.send) {
          await _finishRecording(cancel: false);
        } else if (action == ChatNuRecordingReleaseAction.cancel) {
          await _finishRecording(cancel: true);
        }
      }
    } catch (error) {
      await _abortRecording();
      if (!mounted) return;
      _showError(_readableRecordingError(error));
    }
  }

  Future<void> _startVoiceRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      throw StateError(
        'Microphone permission is required to record a voice message.',
      );
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

  Future<void> _startAmplitudeUpdates() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 90))
        .listen((amplitude) {
          if (!mounted || _paused || !_recordingSession.isRecording) return;
          final normalized = ((amplitude.current + 60) / 60).clamp(0.08, 1.0);
          setState(() {
            _waveform = <double>[..._waveform.skip(1), normalized.toDouble()];
          });
        });
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
    _showVideoPreviewOverlay(controller);
    await controller.startVideoRecording();
  }

  Future<void> _pauseRecording() async {
    if (_recordingSession.phase != ChatNuRecordingPhase.locked) return;
    try {
      if (_recordingSession.mode == ChatNuRecordingMode.voice) {
        await _audioRecorder.pause();
      } else {
        final camera = _cameraController;
        if (camera == null || !camera.value.isRecordingVideo) return;
        await camera.pauseVideoRecording();
      }
      _lastRecordTick = DateTime.now();
      if (!mounted) return;
      setState(() => _recordingSession = _recordingSession.pause());
      unawaited(HapticFeedback.selectionClick());
    } catch (error) {
      if (mounted) _showError(_readableRecordingError(error));
    }
  }

  Future<void> _resumeRecording() async {
    if (!_recordingSession.isPaused) return;
    try {
      if (_recordingSession.mode == ChatNuRecordingMode.voice) {
        await _audioRecorder.resume();
      } else {
        final camera = _cameraController;
        if (camera == null || !camera.value.isRecordingVideo) return;
        await camera.resumeVideoRecording();
      }
      _lastRecordTick = DateTime.now();
      if (!mounted) return;
      setState(() => _recordingSession = _recordingSession.resume());
      unawaited(HapticFeedback.selectionClick());
    } catch (error) {
      if (mounted) _showError(_readableRecordingError(error));
    }
  }

  Future<void> _finishRecording({required bool cancel}) async {
    if (_finishing || !_recordingSession.isActive) return;
    _recordTimer?.cancel();
    _recordTimer = null;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    final duration = _elapsed;
    final mode = _recordingSession.mode;
    if (mounted) {
      setState(() {
        _recordingSession = _recordingSession.finish();
      });
    }

    try {
      if (mode == ChatNuRecordingMode.voice) {
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
      if (mounted) {
        setState(() {
          _holding = false;
          _recordingSession = _recordingSession.reset();
          _elapsed = Duration.zero;
          _lastRecordTick = null;
          _waveform = List<double>.filled(30, 0.12);
        });
      }
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
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
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
      _recordingSession = _recordingSession.reset();
      _elapsed = Duration.zero;
      _lastRecordTick = null;
      _waveform = List<double>.filled(30, 0.12);
    });
  }

  void _showVideoPreviewOverlay(CameraController controller) {
    _removeVideoPreviewOverlay();
    final overlay = Overlay.of(context, rootOverlay: true);
    _videoPreviewOverlay = OverlayEntry(
      builder: (overlayContext) {
        final palette = overlayContext.chatNu;
        final shortestSide = MediaQuery.sizeOf(overlayContext).shortestSide;
        final diameter = (shortestSide * 0.42).clamp(168.0, 240.0).toDouble();
        return IgnorePointer(
          child: Positioned.fill(
            child: SafeArea(
              child: Center(
                child: Container(
                  width: diameter,
                  height: diameter,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.backgroundElevated,
                    border: Border.all(color: palette.accentPrimary, width: 3),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: palette.accentPrimary.withValues(alpha: 0.16),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.previewSize?.height ?? 1,
                        height: controller.value.previewSize?.width ?? 1,
                        child: CameraPreview(controller),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_videoPreviewOverlay!);
  }

  void _removeVideoPreviewOverlay() {
    _videoPreviewOverlay?.remove();
    _videoPreviewOverlay = null;
  }

  Future<void> _disposeCamera() async {
    _removeVideoPreviewOverlay();
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
    final liveLocation = ref.read(liveLocationControllerProvider);
    final choice = await showModalBottomSheet<_AttachmentChoice>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
      builder: (sheetContext) => SizedBox(
        width: double.infinity,
        child: GlassSheet(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: _AttachmentSheet(
                persian: strings.isPersian,
                liveLocationActive: liveLocation.isSharingConversation(
                  widget.conversationId,
                ),
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
      case _AttachmentChoice.video:
        await _captureVideo();
      case _AttachmentChoice.audio:
        await _pickAudio();
      case _AttachmentChoice.location:
        await _shareLocation();
      case _AttachmentChoice.file:
        await _pickFile();
      case _AttachmentChoice.liveLocation:
        await _toggleLiveLocation();
      case _AttachmentChoice.contact:
        _showUnsupportedAttachment(liveLocation: false);
    }
  }

  Future<void> _toggleLiveLocation() async {
    final controller = ref.read(liveLocationControllerProvider.notifier);
    final current = ref.read(liveLocationControllerProvider);
    final persian = ChatNuStrings.of(context).isPersian;
    if (current.isSharingConversation(widget.conversationId)) {
      controller.stop();
      if (mounted) {
        _showError(
          persian ? 'موقعیت زنده متوقف شد.' : 'Live Location stopped.',
        );
      }
      return;
    }

    await controller.start(widget.conversationId);
    if (!mounted) return;
    final next = ref.read(liveLocationControllerProvider);
    if (next.status == ChatNuLiveLocationStatus.failed) {
      _showError(
        next.error ??
            (persian
                ? 'اشتراک موقعیت زنده شروع نشد.'
                : 'Live Location could not start.'),
      );
      return;
    }
    _showError(
      persian
          ? 'موقعیت زنده تا ۱۵ دقیقه و فقط تا زمانی که ChatNU در پیش‌زمینه است ارسال می‌شود.'
          : 'Live Location shares for up to 15 minutes while ChatNU stays in the foreground.',
    );
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

  Future<void> _captureVideo() async {
    final file = await ImagePicker().pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
    );
    if (file == null) return;
    await _sendPickedXFile(file, forcedType: ChatNuMessageType.video);
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
    final metadata = <String, dynamic>{};
    if (type == ChatNuMessageType.video) {
      final duration = await _videoDuration(file.path);
      if (duration != null) metadata['durationMs'] = duration.inMilliseconds;
    }
    if (!mounted) return;
    await ref
        .read(messengerDemoProvider.notifier)
        .sendAttachment(
          conversationId: widget.conversationId,
          bytes: bytes,
          fileName: file.name,
          mimeType: mimeType,
          type: type,
          privateMetadata: metadata,
        );
  }

  Future<Duration?> _videoDuration(String path) async {
    if (path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(file);
      await controller.initialize();
      return controller.value.duration;
    } catch (_) {
      return null;
    } finally {
      await controller?.dispose();
    }
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
      if (mounted) _showError(_readableRecordingError(error));
    }
  }

  void _showUnsupportedAttachment({required bool liveLocation}) {
    final persian = ChatNuStrings.of(context).isPersian;
    _showError(
      liveLocation
          ? (persian
                ? 'اشتراک موقعیت زنده در این دستگاه فقط در پیش‌زمینه پشتیبانی می‌شود.'
                : 'Live Location on this device is supported only while ChatNU stays in the foreground.')
          : (persian
                ? 'پیام مخاطب هنوز قالب رمزگذاری‌شدهٔ قابل‌اعتماد در سرور ندارد.'
                : 'Contact messages stay unavailable until the server defines an encrypted contact payload.'),
    );
  }

  String _readableRecordingError(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '');
    return message.replaceFirst('StateError: ', '');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    required this.session,
    required this.elapsed,
    required this.waveform,
    required this.onCancel,
    required this.onPauseResume,
    super.key,
  });

  final ChatNuRecordingSession session;
  final Duration elapsed;
  final List<double> waveform;
  final VoidCallback onCancel;
  final VoidCallback onPauseResume;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final foreground = session.cancelArmed
        ? palette.destructive
        : palette.textPrimary;
    final locked = session.isLocked;

    return AnimatedContainer(
      duration: ChatNuMotion.micro,
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsetsDirectional.fromSTEB(9, 5, 8, 5),
      decoration: BoxDecoration(
        color: session.cancelArmed
            ? palette.destructive.withValues(alpha: 0.09)
            : palette.backgroundElevated.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: session.cancelArmed
              ? palette.destructive.withValues(alpha: 0.34)
              : locked
              ? palette.accentPrimary.withValues(alpha: 0.34)
              : palette.borderSubtle,
        ),
      ),
      child: Row(
        children: <Widget>[
          if (session.phase == ChatNuRecordingPhase.arming)
            SizedBox.square(
              dimension: 34,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              ),
            )
          else if (session.mode == ChatNuRecordingMode.video)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accentPrimary.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.videocam_rounded, size: 19, color: foreground),
            )
          else
            SizedBox(
              width: locked ? 68 : 52,
              height: 30,
              child: _VoiceWaveform(
                samples: waveform,
                color: foreground,
                paused: session.isPaused,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            _durationLabel(elapsed),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          if (locked) ...<Widget>[
            Expanded(
              child: Text(
                session.isPaused
                    ? (strings.isPersian ? 'مکث' : 'Paused')
                    : (strings.isPersian ? 'ضبط قفل شد' : 'Locked'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
              ),
            ),
            _RecordingAction(
              tooltip: strings.isPersian ? 'لغو ضبط' : 'Cancel recording',
              icon: Icons.delete_outline_rounded,
              foreground: palette.destructive,
              onPressed: onCancel,
            ),
            _RecordingAction(
              tooltip: session.isPaused
                  ? (strings.isPersian ? 'ادامه' : 'Continue')
                  : (strings.isPersian ? 'مکث' : 'Pause'),
              icon: session.isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              foreground: palette.textPrimary,
              onPressed: onPauseResume,
            ),
          ] else
            Expanded(
              child: AnimatedSwitcher(
                duration: ChatNuMotion.micro,
                child: Text(
                  key: ValueKey<String>(
                    '${session.phase.name}-${session.gesture.name}',
                  ),
                  session.cancelArmed
                      ? (strings.isPersian
                            ? 'رها کنید تا لغو شود'
                            : 'Release to cancel')
                      : session.lockArmed
                      ? (strings.isPersian
                            ? 'رها کنید؛ ضبط قفل می‌ماند'
                            : 'Release; recording stays locked')
                      : _finishingLabel(strings, session),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: session.cancelArmed
                        ? palette.destructive
                        : palette.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _finishingLabel(
    ChatNuStrings strings,
    ChatNuRecordingSession session,
  ) {
    if (session.phase == ChatNuRecordingPhase.finishing) {
      return strings.isPersian ? 'در حال ارسال…' : 'Sending…';
    }
    if (session.phase == ChatNuRecordingPhase.arming) {
      return strings.isPersian ? 'در حال آماده‌سازی…' : 'Preparing…';
    }
    return strings.isPersian
        ? 'چپ: لغو  •  بالا: قفل'
        : 'Slide left to cancel • up to lock';
  }

  static String _durationLabel(Duration duration) {
    final total = duration.inSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _RecordingAction extends StatelessWidget {
  const _RecordingAction({
    required this.tooltip,
    required this.icon,
    required this.foreground,
    required this.onPressed,
    this.background,
  });

  final String tooltip;
  final IconData icon;
  final Color foreground;
  final Color? background;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
      style: IconButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: background,
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _VoiceWaveform extends StatelessWidget {
  const _VoiceWaveform({
    required this.samples,
    required this.color,
    required this.paused,
  });

  final List<double> samples;
  final Color color;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveformPainter(
        samples: samples,
        color: color.withValues(alpha: paused ? 0.48 : 0.9),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({required this.samples, required this.color});

  final List<double> samples;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty || size.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    final step = size.width / samples.length;
    for (var index = 0; index < samples.length; index++) {
      final amplitude = samples[index].clamp(0.08, 1.0);
      final barHeight = 4 + (size.height - 4) * amplitude;
      final x = (index + 0.5) * step;
      final top = (size.height - barHeight) / 2;
      canvas.drawLine(Offset(x, top), Offset(x, top + barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.samples != samples;
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

  final ChatNuRecordingMode mode;
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
    final icon = mode == ChatNuRecordingMode.voice
        ? Icons.mic_rounded
        : Icons.videocam_rounded;
    final tooltip = recording
        ? strings.send
        : mode == ChatNuRecordingMode.voice
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
          onLongPressStart: enabled && !recording ? onLongPressStart : null,
          onLongPressMoveUpdate: enabled && !recording
              ? onLongPressMoveUpdate
              : null,
          onLongPressEnd: enabled && !recording ? onLongPressEnd : null,
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
                        color:
                            (cancelArmed
                                    ? palette.destructive
                                    : palette.accentPrimary)
                                .withValues(alpha: 0.24),
                        blurRadius: 18,
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Icon(
              recording
                  ? cancelArmed
                        ? Icons.close_rounded
                        : Icons.send_rounded
                  : icon,
              key: ValueKey<String>('${mode.name}-$recording-$cancelArmed'),
              size: 22,
              color: recording ? Colors.white : palette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

enum _AttachmentChoice {
  gallery,
  camera,
  video,
  audio,
  file,
  location,
  liveLocation,
  contact,
}

class _AttachmentSheet extends StatelessWidget {
  const _AttachmentSheet({
    required this.persian,
    required this.liveLocationActive,
    required this.onSelected,
  });

  final bool persian;
  final bool liveLocationActive;
  final ValueChanged<_AttachmentChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final items = <_AttachmentItem>[
      _AttachmentItem(
        choice: _AttachmentChoice.gallery,
        icon: Icons.photo_library_outlined,
        title: persian ? 'گالری' : 'Gallery',
        subtitle: persian ? 'عکس یا ویدیو' : 'Photo or video',
      ),
      _AttachmentItem(
        choice: _AttachmentChoice.camera,
        icon: Icons.photo_camera_outlined,
        title: persian ? 'دوربین' : 'Camera',
        subtitle: persian ? 'گرفتن عکس' : 'Take a photo',
      ),
      _AttachmentItem(
        choice: _AttachmentChoice.video,
        icon: Icons.videocam_outlined,
        title: persian ? 'ویدیو' : 'Video',
        subtitle: persian ? 'ضبط ویدیو' : 'Record a video',
      ),
      _AttachmentItem(
        choice: _AttachmentChoice.audio,
        icon: Icons.audio_file_outlined,
        title: persian ? 'صدا' : 'Audio',
        subtitle: persian ? 'فایل صوتی' : 'Audio file',
      ),
      _AttachmentItem(
        choice: _AttachmentChoice.file,
        icon: Icons.insert_drive_file_outlined,
        title: persian ? 'فایل' : 'File',
        subtitle: persian ? 'سند یا فایل دیگر' : 'Document or other file',
      ),
      _AttachmentItem(
        choice: _AttachmentChoice.location,
        icon: Icons.location_on_outlined,
        title: persian ? 'موقعیت' : 'Location',
        subtitle: persian ? 'موقعیت فعلی' : 'Current location',
      ),
      _AttachmentItem(
        choice: _AttachmentChoice.liveLocation,
        icon: Icons.my_location_rounded,
        title: persian ? 'موقعیت زنده' : 'Live Location',
        subtitle: liveLocationActive
            ? (persian
                  ? 'برای توقف لمس کنید • فقط پیش‌زمینه'
                  : 'Tap to stop • foreground only')
            : (persian
                  ? '۱۵ دقیقه • فقط پیش‌زمینه'
                  : '15 min • foreground only'),
      ),
      _AttachmentItem(
        choice: _AttachmentChoice.contact,
        icon: Icons.person_outline_rounded,
        title: persian ? 'مخاطب' : 'Contact',
        subtitle: persian ? 'نیازمند قالب امن سرور' : 'Secure payload required',
        enabled: false,
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
            final columns = constraints.maxWidth >= 560 ? 4 : 3;
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
                        icon: item.icon,
                        title: item.title,
                        subtitle: item.subtitle,
                        enabled: item.enabled,
                        onTap: () => onSelected(item.choice),
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

class _AttachmentItem {
  const _AttachmentItem({
    required this.choice,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = true,
  });

  final _AttachmentChoice choice;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Semantics(
      button: enabled,
      enabled: enabled,
      label: '$title, $subtitle',
      child: Opacity(
        opacity: enabled ? 1 : 0.46,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
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
                  Row(
                    children: <Widget>[
                      Icon(icon, size: 23, color: palette.textPrimary),
                      if (!enabled) ...<Widget>[
                        const Spacer(),
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 15,
                          color: palette.textMuted,
                        ),
                      ],
                    ],
                  ),
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
        ),
      ),
    );
  }
}
