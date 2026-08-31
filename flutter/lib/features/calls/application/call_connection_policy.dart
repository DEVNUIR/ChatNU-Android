class ChatNuCallConnectionPolicy {
  const ChatNuCallConnectionPolicy._();

  static const Duration disconnectGrace = Duration(seconds: 8);
  static const Duration ringingTimeout = Duration(seconds: 45);

  static String friendlyError(Object error, {required bool video}) {
    final raw = error.toString().toLowerCase();

    if (raw.contains('permission') ||
        raw.contains('notallowed') ||
        raw.contains('not allowed') ||
        raw.contains('denied')) {
      if (video && raw.contains('camera')) {
        return 'Camera permission is required for video calls.';
      }
      return video
          ? 'Microphone and camera permission are required for video calls.'
          : 'Microphone permission is required for voice calls.';
    }

    if (raw.contains('notfound') ||
        raw.contains('not found') ||
        raw.contains('no microphone') ||
        raw.contains('no camera') ||
        raw.contains('device unavailable')) {
      return video
          ? 'A microphone and camera are required for this video call.'
          : 'A microphone is required for this voice call.';
    }

    if (raw.contains('realtime') ||
        raw.contains('websocket') ||
        raw.contains('network') ||
        raw.contains('ice') ||
        raw.contains('connection')) {
      return 'Call connection is unavailable. Check your network and try again.';
    }

    return 'Something went wrong with the call. Please try again.';
  }
}
