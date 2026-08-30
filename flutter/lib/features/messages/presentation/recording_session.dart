enum ChatNuRecordingMode { voice, video }

enum ChatNuRecordingPhase {
  idle,
  arming,
  holding,
  locked,
  paused,
  finishing,
}

enum ChatNuRecordingGesture { none, cancel, lock }

enum ChatNuRecordingReleaseAction { send, cancel, keepRecording, none }

class ChatNuRecordingSession {
  const ChatNuRecordingSession({
    this.mode = ChatNuRecordingMode.voice,
    this.phase = ChatNuRecordingPhase.idle,
    this.gesture = ChatNuRecordingGesture.none,
  });

  static const double defaultCancelDistance = 72;
  static const double defaultLockDistance = 78;

  final ChatNuRecordingMode mode;
  final ChatNuRecordingPhase phase;
  final ChatNuRecordingGesture gesture;

  bool get isIdle => phase == ChatNuRecordingPhase.idle;
  bool get isActive => !isIdle;
  bool get isRecording =>
      phase == ChatNuRecordingPhase.holding ||
      phase == ChatNuRecordingPhase.locked ||
      phase == ChatNuRecordingPhase.paused;
  bool get isLocked =>
      phase == ChatNuRecordingPhase.locked ||
      phase == ChatNuRecordingPhase.paused;
  bool get isPaused => phase == ChatNuRecordingPhase.paused;
  bool get isBusy =>
      phase == ChatNuRecordingPhase.arming ||
      phase == ChatNuRecordingPhase.finishing;
  bool get cancelArmed => gesture == ChatNuRecordingGesture.cancel;
  bool get lockArmed => gesture == ChatNuRecordingGesture.lock;

  ChatNuRecordingSession toggleMode() {
    if (!isIdle) return this;
    return copyWith(
      mode: mode == ChatNuRecordingMode.voice
          ? ChatNuRecordingMode.video
          : ChatNuRecordingMode.voice,
    );
  }

  ChatNuRecordingSession startArming() {
    if (!isIdle) return this;
    return copyWith(
      phase: ChatNuRecordingPhase.arming,
      gesture: ChatNuRecordingGesture.none,
    );
  }

  ChatNuRecordingSession startHolding() {
    if (phase != ChatNuRecordingPhase.arming) return this;
    return copyWith(
      phase: lockArmed
          ? ChatNuRecordingPhase.locked
          : ChatNuRecordingPhase.holding,
      gesture: gesture,
    );
  }

  ChatNuRecordingSession updateHoldGesture({
    required double dx,
    required double dy,
    required bool rtl,
    double cancelDistance = defaultCancelDistance,
    double lockDistance = defaultLockDistance,
  }) {
    if (phase != ChatNuRecordingPhase.arming &&
        phase != ChatNuRecordingPhase.holding) {
      return this;
    }

    final cancelDelta = rtl ? dx : -dx;
    final lockDelta = -dy;
    if (lockDelta >= lockDistance && lockDelta >= cancelDelta) {
      return copyWith(
        phase: phase == ChatNuRecordingPhase.holding
            ? ChatNuRecordingPhase.locked
            : phase,
        gesture: ChatNuRecordingGesture.lock,
      );
    }
    if (cancelDelta >= cancelDistance) {
      return copyWith(gesture: ChatNuRecordingGesture.cancel);
    }
    return copyWith(gesture: ChatNuRecordingGesture.none);
  }

  ChatNuRecordingSession pause() {
    if (phase != ChatNuRecordingPhase.locked) return this;
    return copyWith(
      phase: ChatNuRecordingPhase.paused,
      gesture: ChatNuRecordingGesture.none,
    );
  }

  ChatNuRecordingSession resume() {
    if (phase != ChatNuRecordingPhase.paused) return this;
    return copyWith(
      phase: ChatNuRecordingPhase.locked,
      gesture: ChatNuRecordingGesture.none,
    );
  }

  ChatNuRecordingSession finish() {
    if (!isRecording && phase != ChatNuRecordingPhase.arming) return this;
    return copyWith(
      phase: ChatNuRecordingPhase.finishing,
      gesture: ChatNuRecordingGesture.none,
    );
  }

  ChatNuRecordingSession reset() {
    return ChatNuRecordingSession(mode: mode);
  }

  ChatNuRecordingReleaseAction releaseAction() {
    if (phase == ChatNuRecordingPhase.locked ||
        phase == ChatNuRecordingPhase.paused ||
        lockArmed) {
      return ChatNuRecordingReleaseAction.keepRecording;
    }
    if (phase != ChatNuRecordingPhase.holding) {
      return ChatNuRecordingReleaseAction.none;
    }
    return cancelArmed
        ? ChatNuRecordingReleaseAction.cancel
        : ChatNuRecordingReleaseAction.send;
  }

  ChatNuRecordingSession copyWith({
    ChatNuRecordingMode? mode,
    ChatNuRecordingPhase? phase,
    ChatNuRecordingGesture? gesture,
  }) {
    return ChatNuRecordingSession(
      mode: mode ?? this.mode,
      phase: phase ?? this.phase,
      gesture: gesture ?? this.gesture,
    );
  }
}
