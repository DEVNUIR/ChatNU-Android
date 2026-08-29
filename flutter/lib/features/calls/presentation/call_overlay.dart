import 'dart:async';

import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/calls/application/call_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallOverlay extends ConsumerStatefulWidget {
  const CallOverlay({super.key});

  @override
  ConsumerState<CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends ConsumerState<CallOverlay> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    unawaited(_localRenderer.dispose());
    unawaited(_remoteRenderer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(callControllerProvider);
    if (!state.active) return const SizedBox.shrink();
    if (_ready) {
      _localRenderer.srcObject = state.localStream;
      _remoteRenderer.srcObject = state.remoteStream;
    }
    final palette = context.chatNu;
    final incoming = state.status == ChatNuCallStatus.incoming;
    final hasRemoteVideo = state.video && state.remoteStream != null && _ready;

    return Material(
      color: palette.backgroundPrimary.withValues(alpha: 0.97),
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: hasRemoteVideo
                  ? RTCVideoView(
                      _remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: palette.glassStrong,
                            child: const Icon(Icons.person_rounded, size: 52),
                          ),
                          const SizedBox(height: ChatNuSpacing.md),
                          Text(
                            state.peerName ?? 'ChatNU contact',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: ChatNuSpacing.xs),
                          Text(
                            _statusLabel(state.status, state.video),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (state.error != null) ...<Widget>[
                            const SizedBox(height: ChatNuSpacing.sm),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ChatNuSpacing.xl,
                              ),
                              child: Text(
                                state.error!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: palette.destructive),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            if (state.video && state.localStream != null && _ready)
              PositionedDirectional(
                top: ChatNuSpacing.md,
                end: ChatNuSpacing.md,
                width: 128,
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ChatNuRadii.lg),
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            PositionedDirectional(
              start: ChatNuSpacing.lg,
              end: ChatNuSpacing.lg,
              bottom: ChatNuSpacing.xl,
              child: Align(
                child: GlassSurface(
                  variant: GlassVariant.strong,
                  enableBlur: true,
                  borderRadius: ChatNuRadii.pill,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChatNuSpacing.sm,
                    vertical: ChatNuSpacing.xs,
                  ),
                  child: incoming
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton.filled(
                              tooltip: 'Accept',
                              onPressed: () => unawaited(
                                ref.read(callControllerProvider.notifier).accept(),
                              ),
                              icon: const Icon(Icons.call_rounded),
                            ),
                            const SizedBox(width: ChatNuSpacing.md),
                            IconButton.filledTonal(
                              tooltip: 'Reject',
                              onPressed: () => unawaited(
                                ref.read(callControllerProvider.notifier).reject(),
                              ),
                              icon: const Icon(Icons.call_end_rounded),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              tooltip: state.muted ? 'Unmute' : 'Mute',
                              onPressed: ref
                                  .read(callControllerProvider.notifier)
                                  .toggleMute,
                              icon: Icon(
                                state.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                              ),
                            ),
                            if (state.video)
                              IconButton(
                                tooltip: state.cameraEnabled
                                    ? 'Camera off'
                                    : 'Camera on',
                                onPressed: ref
                                    .read(callControllerProvider.notifier)
                                    .toggleCamera,
                                icon: Icon(
                                  state.cameraEnabled
                                      ? Icons.videocam_rounded
                                      : Icons.videocam_off_rounded,
                                ),
                              ),
                            const SizedBox(width: ChatNuSpacing.xs),
                            IconButton.filled(
                              tooltip: 'End call',
                              onPressed: () => unawaited(
                                ref.read(callControllerProvider.notifier).end(),
                              ),
                              icon: const Icon(Icons.call_end_rounded),
                            ),
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

  String _statusLabel(ChatNuCallStatus status, bool video) => switch (status) {
    ChatNuCallStatus.incoming => video ? 'Incoming video call' : 'Incoming voice call',
    ChatNuCallStatus.outgoing => 'Calling…',
    ChatNuCallStatus.connecting => 'Connecting…',
    ChatNuCallStatus.connected => 'Connected',
    ChatNuCallStatus.failed => 'Call failed',
    ChatNuCallStatus.ended => 'Call ended',
    ChatNuCallStatus.idle => '',
  };
}
