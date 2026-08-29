class ChatNuCapabilities {
  const ChatNuCapabilities({
    required this.directMessages,
    required this.groups,
    required this.conversationPinning,
    required this.markRead,
    required this.oneToOneCalls,
    required this.encryptedAttachments,
    required this.channels,
    required this.archive,
    required this.deliveredReceipts,
    required this.messageReadReceipts,
    required this.persistentReactions,
    required this.messagePinning,
    required this.groupCalls,
  });

  final bool directMessages;
  final bool groups;
  final bool conversationPinning;
  final bool markRead;
  final bool oneToOneCalls;
  final bool encryptedAttachments;
  final bool channels;
  final bool archive;
  final bool deliveredReceipts;
  final bool messageReadReceipts;
  final bool persistentReactions;
  final bool messagePinning;
  final bool groupCalls;

  static const current = ChatNuCapabilities(
    directMessages: true,
    groups: true,
    conversationPinning: true,
    markRead: true,
    oneToOneCalls: true,
    encryptedAttachments: true,
    channels: false,
    archive: false,
    deliveredReceipts: false,
    messageReadReceipts: false,
    persistentReactions: false,
    messagePinning: false,
    groupCalls: false,
  );
}
