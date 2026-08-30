class ChatNuLiveLocationPolicy {
  const ChatNuLiveLocationPolicy._();

  static const Duration shareDuration = Duration(minutes: 15);
  static const Duration updateInterval = Duration(seconds: 30);
  static const Duration fixTimeout = Duration(seconds: 20);

  static DateTime endsAt(DateTime startedAt) => startedAt.add(shareDuration);

  static bool isExpired(DateTime now, DateTime endsAt) =>
      !now.isBefore(endsAt);

  static Duration remaining(DateTime now, DateTime endsAt) {
    if (isExpired(now, endsAt)) return Duration.zero;
    return endsAt.difference(now);
  }
}
