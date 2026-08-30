import 'package:chatnu/features/messages/domain/message.dart';

enum MessageGroupPosition { single, first, middle, last }

class MessageGrouping {
  const MessageGrouping._();

  static const Duration defaultGap = Duration(minutes: 5);

  static bool canGroup(
    ChatNuMessage first,
    ChatNuMessage second, {
    Duration gap = defaultGap,
  }) {
    if (first.type == ChatNuMessageType.system ||
        second.type == ChatNuMessageType.system) {
      return false;
    }
    if (first.senderId != second.senderId) return false;
    if (!_sameLocalDay(first.sentAt, second.sentAt)) return false;

    final deltaMs = second.sentAt.difference(first.sentAt).inMilliseconds.abs();
    return deltaMs <= gap.inMilliseconds;
  }

  static MessageGroupPosition positionAt(
    List<ChatNuMessage> messages,
    int index, {
    Duration gap = defaultGap,
  }) {
    assert(index >= 0 && index < messages.length);
    final message = messages[index];
    final previous = index == 0 ? null : messages[index - 1];
    final next = index + 1 >= messages.length ? null : messages[index + 1];
    final groupedWithPrevious =
        previous != null && canGroup(previous, message, gap: gap);
    final groupedWithNext = next != null && canGroup(message, next, gap: gap);

    if (!groupedWithPrevious && !groupedWithNext) {
      return MessageGroupPosition.single;
    }
    if (!groupedWithPrevious && groupedWithNext) {
      return MessageGroupPosition.first;
    }
    if (groupedWithPrevious && groupedWithNext) {
      return MessageGroupPosition.middle;
    }
    return MessageGroupPosition.last;
  }

  static bool isGroupStart(MessageGroupPosition position) =>
      position == MessageGroupPosition.single ||
      position == MessageGroupPosition.first;

  static bool isGroupEnd(MessageGroupPosition position) =>
      position == MessageGroupPosition.single ||
      position == MessageGroupPosition.last;

  static bool _sameLocalDay(DateTime first, DateTime second) {
    final a = first.toLocal();
    final b = second.toLocal();
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
