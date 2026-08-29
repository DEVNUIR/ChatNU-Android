import 'dart:async';

import 'package:chatnu/core/glass/glass_components.dart';
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
      color: Colors.transparent,
      child: ChatNuAtmosphere(
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: hasRemoteVideo
                    ? RTCVideoView(
                        _remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : _AudioCallBackdrop(state: state),
              ),
              if (hasRemoteVideo)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.black.withValues(alpha: 0.25),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.42),
                          ],
                          stops: const <double>[0, 0.5, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              PositionedDirectional(
                start: ChatNuSpacing.lg,
                end: ChatNuSpacing.lg,
                top: ChatNuSpacing.lg,
                child: Column(
                  children: <Widget>[
                    Text(
                      state.peerName ?? 'ChatNU contact',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: hasRemoteVideo
                                ? Colors.white
                                : palette.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel(state.status, state.video),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasRemoteVideo
                            ? Colors.white.withValues(alpha: 0.8)
                            : palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.video && state.localStream != null && _ready)
                PositionedDirectional(
                  top: 92,
                  end: ChatNuSpacing.md,
                  width: 126,
                  height: 178,
                  child: GlassSurface(
                    variant: GlassVariant.medium,
                    borderRadius: ChatNuRadii.lg,
                    padding: const EdgeInsets.all(2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(ChatNuRadii.lg - 2),
                      child: RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),
              if (state.error != null)
                PositionedDirectional(
                  start: ChatNuSpacing.lg,
                  end: ChatNuSpacing.lg,
                  bottom: 138,
                  child: Semantics(
                    liveRegion: true,
                    child: GlassCard(
                      child: Text(
                        state.error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.destructive,
                        ),
                      ),
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
                        ? _IncomingCallControls(ref: ref)
                        : _ActiveCallControls(ref: ref, state: state),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(ChatNuCallStatus status, bool video) => switch (status) {
    ChatNuCallStatus.incoming =>
      video ? 'Incoming video call' : 'Incoming voice call',
    ChatNuCallStatus.outgoing => 'Calling…',
    ChatNuCallStatus.connecting => 'Connecting…',
    ChatNuCallStatus.connected => 'Encrypted WebRTC media connected',
    ChatNuCallStatus.failed => 'Call connection failed',
    ChatNuCallStatus.ended => 'Call ended',
    ChatNuCallStatus.idle => '',
  };
}

class _AudioCallBackdrop extends StatelessWidget {
  const _AudioCallBackdrop({required this.state});

  final ChatNuCallState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 122,
            height: 122,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  palette.accentPrimary.withValues(alpha: 0.48),
                  palette.accentSecondary.withValues(alpha: 0.26),
                ],
              ),
              border: Border.all(color: palette.borderHighlight),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: palette.accentPrimary.withValues(alpha: 0.18),
                  blurRadius: 42,
                  spreadRadius: 8,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person_rounded, size: 58),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _IncomingCallControls extends StatelessWidget {
  const _IncomingCallControls({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _CallControlButton(
          tooltip: 'Accept',
          icon: Icons.call_rounded,
          background: palette.success,
          onPressed: () =>
              unawaited(ref.read(callControllerProvider.notifier).accept()),
        ),
        const SizedBox(width: ChatNuSpacing.lg),
        _CallControlButton(
          tooltip: 'Reject',
          icon: Icons.call_end_rounded,
          background: palette.destructive,
          onPressed: () =>
              unawaited(ref.read(callControllerProvider.notifier).reject()),
        ),
      ],
    );
  }
}

class _ActiveCallControls extends StatelessWidget {
  const _ActiveCallControls({required this.ref, required this.state});

  final WidgetRef ref;
  final ChatNuCallState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _CallControlButton(
          tooltip: state.muted ? 'Unmute' : 'Mute',
          icon: state.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          selected: state.muted,
          onPressed: ref.read(callControllerProvider.notifier).toggleMute,
        ),
        if (state.video) ...<Widget>[
          const SizedBox(width: ChatNuSpacing.xs),
          _CallControlButton(
            tooltip: state.cameraEnabled ? 'Camera off' : 'Camera on',
            icon: state.cameraEnabled
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            selected: !state.cameraEnabled,
            onPressed: ref.read(callControllerProvider.notifier).toggleCamera,
          ),
        ],
        const SizedBox(width: ChatNuSpacing.md),
        _CallControlButton(
          tooltip: 'End call',
          icon: Icons.call_end_rounded,
          background: palette.destructive,
          onPressed: () =>
              unawaited(ref.read(callControllerProvider.notifier).end()),
        ),
      ],
    );
  }
}

class _CallControlButton extends StatelessWidget {
  const _CallControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.background,
    this.selected = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? background;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Semantics(
      button: true,
      label: tooltip,
      selected: selected,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color:
              background ??
              (selected ? palette.glassStrong : palette.glassMedium),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 52,
              child: Icon(
                icon,
                color: background == null ? palette.textPrimary : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
