import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MessengerDestination { chats, contacts, settings }

class MessengerDemoState {
  const MessengerDemoState({
    required this.currentUser,
    required this.destination,
    required this.conversations,
    required this.messagesByConversation,
    this.selectedConversationId,
  });

  final ChatNuUser currentUser;
  final MessengerDestination destination;
  final List<ChatNuConversation> conversations;
  final Map<String, List<ChatNuMessage>> messagesByConversation;
  final String? selectedConversationId;

  MessengerDemoState copyWith({
    MessengerDestination? destination,
    List<ChatNuConversation>? conversations,
    Map<String, List<ChatNuMessage>>? messagesByConversation,
    String? selectedConversationId,
    bool clearSelection = false,
  }) {
    return MessengerDemoState(
      currentUser: currentUser,
      destination: destination ?? this.destination,
      conversations: conversations ?? this.conversations,
      messagesByConversation:
          messagesByConversation ?? this.messagesByConversation,
      selectedConversationId: clearSelection
          ? null
          : selectedConversationId ?? this.selectedConversationId,
    );
  }
}

class MessengerDemoController extends Notifier<MessengerDemoState> {
  static const _me = ChatNuUser(
    id: 'me',
    username: 'chatnu_user',
    displayName: 'ChatNU User',
  );
  static const _leila = ChatNuUser(
    id: 'leila',
    username: 'leila',
    displayName: 'Leila Farhadi',
  );
  static const _navid = ChatNuUser(
    id: 'navid',
    username: 'navid',
    displayName: 'Navid Moradi',
  );
  static const _mona = ChatNuUser(
    id: 'mona',
    username: 'mona',
    displayName: 'Mona Rahimi',
  );

  @override
  MessengerDemoState build() {
    final conversations = <ChatNuConversation>[
      ChatNuConversation(
        id: 'direct-leila',
        title: 'Leila Farhadi',
        kind: ConversationKind.direct,
        members: const <ChatNuUser>[_me, _leila],
        lastMessagePreview: 'آره، نسخه جدید خیلی تمیزتر شده.',
        lastActivityAt: DateTime(2026, 8, 29, 10, 12),
        unreadCount: 2,
        isPinned: true,
      ),
      ChatNuConversation(
        id: 'group-design',
        title: 'Design team',
        kind: ConversationKind.group,
        members: const <ChatNuUser>[_me, _navid, _mona],
        lastMessagePreview: 'Mona: I pushed the updated prototype.',
        lastActivityAt: DateTime(2026, 8, 29, 9, 38),
        isMuted: true,
      ),
      ChatNuConversation(
        id: 'direct-navid',
        title: 'Navid Moradi',
        kind: ConversationKind.direct,
        members: const <ChatNuUser>[_me, _navid],
        lastMessagePreview: 'See you after lunch.',
        lastActivityAt: DateTime(2026, 8, 28, 18, 45),
      ),
    ];

    return MessengerDemoState(
      currentUser: _me,
      destination: MessengerDestination.chats,
      conversations: conversations,
      messagesByConversation: <String, List<ChatNuMessage>>{
        'direct-leila': <ChatNuMessage>[
          ChatNuMessage(
            id: 'm1',
            conversationId: 'direct-leila',
            senderId: _leila.id,
            senderName: _leila.displayName,
            body: 'سلام، فایل طراحی رو دیدی؟',
            sentAt: DateTime(2026, 8, 29, 10, 8),
          ),
          ChatNuMessage(
            id: 'm2',
            conversationId: 'direct-leila',
            senderId: _me.id,
            senderName: _me.displayName,
            body: 'آره، نسخه جدید خیلی تمیزتر شده.',
            sentAt: DateTime(2026, 8, 29, 10, 12),
          ),
        ],
        'group-design': <ChatNuMessage>[
          ChatNuMessage(
            id: 'm3',
            conversationId: 'group-design',
            senderId: _navid.id,
            senderName: _navid.displayName,
            body: 'Can we keep the composer compact on tablets?',
            sentAt: DateTime(2026, 8, 29, 9, 31),
          ),
          ChatNuMessage(
            id: 'm4',
            conversationId: 'group-design',
            senderId: _mona.id,
            senderName: _mona.displayName,
            body: 'I pushed the updated prototype.',
            sentAt: DateTime(2026, 8, 29, 9, 38),
          ),
        ],
        'direct-navid': <ChatNuMessage>[
          ChatNuMessage(
            id: 'm5',
            conversationId: 'direct-navid',
            senderId: _navid.id,
            senderName: _navid.displayName,
            body: 'See you after lunch.',
            sentAt: DateTime(2026, 8, 28, 18, 45),
          ),
        ],
      },
    );
  }

  void setDestination(MessengerDestination destination) {
    state = state.copyWith(destination: destination);
  }

  void selectConversation(String conversationId) {
    state = state.copyWith(
      destination: MessengerDestination.chats,
      selectedConversationId: conversationId,
      conversations: state.conversations
          .map(
            (conversation) => conversation.id == conversationId
                ? conversation.copyWith(unreadCount: 0)
                : conversation,
          )
          .toList(growable: false),
    );
  }

  void clearConversationSelection() {
    state = state.copyWith(clearSelection: true);
  }

  void togglePin(String conversationId) {
    final updated = state.conversations
        .map(
          (conversation) => conversation.id == conversationId
              ? conversation.copyWith(isPinned: !conversation.isPinned)
              : conversation,
        )
        .toList(growable: false);
    updated.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.lastActivityAt.compareTo(a.lastActivityAt);
    });
    state = state.copyWith(conversations: updated);
  }

  void sendText(String conversationId, String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return;
    final now = DateTime.now();
    final message = ChatNuMessage(
      id: 'local-${now.microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: state.currentUser.id,
      senderName: state.currentUser.displayName,
      body: text,
      sentAt: now,
      // Phase 2 has no backend connection. A local message is therefore queued
      // rather than pretending that a network send is in progress or accepted.
      deliveryState: MessageDeliveryState.queuedOffline,
    );
    final messages = Map<String, List<ChatNuMessage>>.from(
      state.messagesByConversation,
    );
    messages[conversationId] = <ChatNuMessage>[
      ...(messages[conversationId] ?? <ChatNuMessage>[]),
      message,
    ];
    final conversations = state.conversations
        .map(
          (conversation) => conversation.id == conversationId
              ? conversation.copyWith(
                  lastMessagePreview: text,
                  lastActivityAt: now,
                )
              : conversation,
        )
        .toList(growable: false);
    state = state.copyWith(
      messagesByConversation: messages,
      conversations: conversations,
    );
  }
}

final messengerDemoProvider =
    NotifierProvider<MessengerDemoController, MessengerDemoState>(
      MessengerDemoController.new,
    );
