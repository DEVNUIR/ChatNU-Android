import 'package:chatnu/features/accounts/domain/chatnu_user.dart';

enum ConversationKind { direct, group }

class ChatNuConversation {
  const ChatNuConversation({
    required this.id,
    required this.title,
    required this.kind,
    required this.members,
    required this.lastMessagePreview,
    required this.lastActivityAt,
    this.avatarUrl,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
  });

  final String id;
  final String title;
  final ConversationKind kind;
  final List<ChatNuUser> members;
  final String lastMessagePreview;
  final DateTime lastActivityAt;
  final String? avatarUrl;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;

  ChatNuConversation copyWith({
    String? title,
    List<ChatNuUser>? members,
    String? lastMessagePreview,
    DateTime? lastActivityAt,
    String? avatarUrl,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
  }) {
    return ChatNuConversation(
      id: id,
      title: title ?? this.title,
      kind: kind,
      members: members ?? this.members,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}
