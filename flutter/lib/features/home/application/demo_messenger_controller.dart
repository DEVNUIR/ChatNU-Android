import 'dart:async';
import 'dart:typed_data';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/realtime/chatnu_realtime_client.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
import 'package:chatnu/features/auth/application/session_controller.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/home/data/messenger_repository.dart';
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
    this.realtimeStatus = RealtimeConnectionStatus.disconnected,
    this.isLoading = false,
    this.error,
    this.contactResults = const <ChatNuUser>[],
  });

  final ChatNuUser currentUser;
  final MessengerDestination destination;
  final List<ChatNuConversation> conversations;
  final Map<String, List<ChatNuMessage>> messagesByConversation;
  final String? selectedConversationId;
  final RealtimeConnectionStatus realtimeStatus;
  final bool isLoading;
  final String? error;
  final List<ChatNuUser> contactResults;

  MessengerDemoState copyWith({
    ChatNuUser? currentUser,
    MessengerDestination? destination,
    List<ChatNuConversation>? conversations,
    Map<String, List<ChatNuMessage>>? messagesByConversation,
    String? selectedConversationId,
    bool clearSelection = false,
    RealtimeConnectionStatus? realtimeStatus,
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<ChatNuUser>? contactResults,
  }) {
    return MessengerDemoState(
      currentUser: currentUser ?? this.currentUser,
      destination: destination ?? this.destination,
      conversations: conversations ?? this.conversations,
      messagesByConversation:
          messagesByConversation ?? this.messagesByConversation,
      selectedConversationId: clearSelection
          ? null
          : selectedConversationId ?? this.selectedConversationId,
      realtimeStatus: realtimeStatus ?? this.realtimeStatus,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      contactResults: contactResults ?? this.contactResults,
    );
  }
}

class MessengerDemoController extends Notifier<MessengerDemoState> {
  static const _demoMe = ChatNuUser(
    id: 'me',
    username: 'chatnu_user',
    displayName: 'ChatNU User',
  );
  static const _demoLeila = ChatNuUser(
    id: 'leila',
    username: 'leila',
    displayName: 'Leila Farhadi',
  );
  static const _demoNavid = ChatNuUser(
    id: 'navid',
    username: 'navid',
    displayName: 'Navid Moradi',
  );
  static const _demoMona = ChatNuUser(
    id: 'mona',
    username: 'mona',
    displayName: 'Mona Rahimi',
  );

  MessengerRepository? _repository;
  StreamSubscription<Map<String, dynamic>>? _realtimeEvents;
  StreamSubscription<RealtimeConnectionStatus>? _realtimeStatus;
  bool _productionStarted = false;

  bool get _isDemo => ref.read(appModeProvider) == ChatNuAppMode.demo;

  @override
  MessengerDemoState build() {
    final mode = ref.watch(appModeProvider);
    if (mode == ChatNuAppMode.demo) return _demoState();

    final session = ref.watch(sessionProvider);
    final user =
        session.user ??
        const ChatNuUser(
          id: 'session-pending',
          username: 'session-pending',
          displayName: 'ChatNU',
        );
    if (session.isAuthenticated && !_productionStarted) {
      _productionStarted = true;
      Future<void>.microtask(_startProduction);
    }
    ref.onDispose(() {
      unawaited(_realtimeEvents?.cancel());
      unawaited(_realtimeStatus?.cancel());
      unawaited(_repository?.stopRealtime());
    });
    return MessengerDemoState(
      currentUser: user,
      destination: MessengerDestination.chats,
      conversations: const <ChatNuConversation>[],
      messagesByConversation: const <String, List<ChatNuMessage>>{},
      isLoading: session.isAuthenticated,
    );
  }

  Future<void> _startProduction() async {
    if (_isDemo || !ref.read(sessionProvider).isAuthenticated) return;
    final repository = MessengerRepository(
      api: ref.read(apiClientProvider),
      e2ee: ref.read(deviceE2eeProvider),
      vault: ref.read(credentialVaultProvider),
    );
    _repository = repository;
    _realtimeEvents = repository.realtime.events.listen(_handleRealtimeEvent);
    _realtimeStatus = repository.realtime.status.listen((status) {
      state = state.copyWith(realtimeStatus: status);
    });
    await refreshConversations();
    try {
      await repository.startRealtime();
    } catch (error) {
      state = state.copyWith(error: _readableError(error));
    }
  }

  Future<void> refreshConversations() async {
    if (_isDemo) return;
    final repository = _repository;
    if (repository == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final conversations = await repository.loadConversations();
      state = state.copyWith(
        conversations: _sortConversations(conversations),
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: _readableError(error));
    }
  }

  void setDestination(MessengerDestination destination) {
    state = state.copyWith(destination: destination);
  }

  void selectConversation(String conversationId) {
    final previousUnread = state.conversations
        .where((conversation) => conversation.id == conversationId)
        .map((conversation) => conversation.unreadCount)
        .firstOrNull;
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
    if (_isDemo) return;
    unawaited(loadMessages(conversationId));
    if ((previousUnread ?? 0) > 0) {
      unawaited(_markReadWithRollback(conversationId, previousUnread!));
    }
  }

  void clearConversationSelection() {
    state = state.copyWith(clearSelection: true);
  }

  Future<void> loadMessages(String conversationId) async {
    if (_isDemo) return;
    final repository = _repository;
    if (repository == null) return;
    try {
      final messages = await repository.loadMessages(conversationId);
      final map = Map<String, List<ChatNuMessage>>.from(
        state.messagesByConversation,
      );
      map[conversationId] = messages;
      state = state.copyWith(messagesByConversation: map, clearError: true);
    } catch (error) {
      state = state.copyWith(error: _readableError(error));
    }
  }

  void togglePin(String conversationId) {
    final target = state.conversations
        .where((conversation) => conversation.id == conversationId)
        .firstOrNull;
    if (target == null) return;
    final newValue = !target.isPinned;
    _replaceConversation(target.copyWith(isPinned: newValue), sort: true);
    if (_isDemo) return;
    unawaited(_setPinWithRollback(target, newValue));
  }

  void toggleMute(String conversationId) {
    final target = state.conversations
        .where((conversation) => conversation.id == conversationId)
        .firstOrNull;
    if (target == null) return;
    final newValue = !target.isMuted;
    _replaceConversation(target.copyWith(isMuted: newValue));
    if (_isDemo) return;
    unawaited(_setMuteWithRollback(target, newValue));
  }

  void sendText(String conversationId, String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return;
    if (_isDemo) {
      _sendDemoText(conversationId, text);
      return;
    }
    final repository = _repository;
    if (repository == null) return;

    final failedMatch = state.messagesByConversation[conversationId].orEmpty
        .lastWhereOrNull(
          (message) =>
              message.senderId == state.currentUser.id &&
              message.type == ChatNuMessageType.text &&
              message.deliveryState == MessageDeliveryState.failed &&
              message.body == text,
        );
    final optimistic = repository.optimisticText(
      conversationId: conversationId,
      senderId: state.currentUser.id,
      senderName: state.currentUser.displayName,
      text: text,
      clientId: failedMatch?.clientId ?? failedMatch?.id,
    );
    if (failedMatch == null) {
      _appendMessage(optimistic);
    } else {
      _replaceMessage(conversationId, failedMatch.id, optimistic);
    }
    _updateConversationPreview(conversationId, text, optimistic.sentAt);
    unawaited(_sendTextAwait(optimistic));
  }

  void retryMessage(ChatNuMessage message) {
    if (message.deliveryState != MessageDeliveryState.failed) return;
    sendText(message.conversationId, message.body);
  }

  Future<void> sendAttachment({
    required String conversationId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required ChatNuMessageType type,
    Map<String, dynamic> privateMetadata = const <String, dynamic>{},
  }) async {
    final repository = _repository;
    if (_isDemo || repository == null) return;
    final clientId = repository.newClientId();
    final optimistic = ChatNuMessage(
      id: clientId,
      clientId: clientId,
      conversationId: conversationId,
      senderId: state.currentUser.id,
      senderName: state.currentUser.displayName,
      body: fileName,
      sentAt: DateTime.now(),
      type: type,
      deliveryState: MessageDeliveryState.sending,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: bytes.length,
      mediaDurationMs: privateMetadata['durationMs'] is num
          ? (privateMetadata['durationMs'] as num).toInt()
          : null,
      isVideoNote: privateMetadata['videoNote'] == true,
    );
    _appendMessage(optimistic);
    _updateConversationPreview(conversationId, fileName, optimistic.sentAt);
    try {
      final sent = await repository.sendAttachment(
        conversationId: conversationId,
        clientId: clientId,
        plaintextBytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
        type: type,
        privateMetadata: privateMetadata,
      );
      _replaceMessage(conversationId, clientId, sent);
      await refreshConversations();
    } catch (error) {
      _replaceMessage(
        conversationId,
        clientId,
        optimistic.copyWith(deliveryState: MessageDeliveryState.failed),
      );
      state = state.copyWith(error: _readableError(error));
    }
  }

  Future<void> sendLocation({
    required String conversationId,
    required double latitude,
    required double longitude,
  }) async {
    final repository = _repository;
    if (_isDemo || repository == null) return;
    final clientId = repository.newClientId();
    final optimistic = ChatNuMessage(
      id: clientId,
      clientId: clientId,
      conversationId: conversationId,
      senderId: state.currentUser.id,
      senderName: state.currentUser.displayName,
      body: 'Shared location',
      sentAt: DateTime.now(),
      type: ChatNuMessageType.location,
      deliveryState: MessageDeliveryState.sending,
      locationLatitude: latitude,
      locationLongitude: longitude,
    );
    _appendMessage(optimistic);
    _updateConversationPreview(
      conversationId,
      'Shared location',
      optimistic.sentAt,
    );
    try {
      final sent = await repository.sendLocation(
        conversationId: conversationId,
        clientId: clientId,
        latitude: latitude,
        longitude: longitude,
      );
      _replaceMessage(conversationId, clientId, sent);
      await refreshConversations();
    } catch (error) {
      _replaceMessage(
        conversationId,
        clientId,
        optimistic.copyWith(deliveryState: MessageDeliveryState.failed),
      );
      state = state.copyWith(error: _readableError(error));
    }
  }

  Future<Uint8List?> downloadAttachment(ChatNuMessage message) async {
    final repository = _repository;
    if (_isDemo || repository == null) return null;
    try {
      return await repository.downloadAttachment(message);
    } catch (error) {
      state = state.copyWith(error: _readableError(error));
      return null;
    }
  }

  Future<List<ChatNuUser>> searchUsers(String query) async {
    final repository = _repository;
    if (_isDemo || repository == null) return const <ChatNuUser>[];
    try {
      final users = await repository.searchUsers(query);
      state = state.copyWith(contactResults: users, clearError: true);
      return users;
    } catch (error) {
      state = state.copyWith(error: _readableError(error));
      return const <ChatNuUser>[];
    }
  }

  Future<ChatNuConversation?> openDirect(String username) async {
    final repository = _repository;
    if (_isDemo || repository == null) return null;
    try {
      final conversation = await repository.openDirect(username);
      _replaceConversation(conversation, insertIfMissing: true, sort: true);
      selectConversation(conversation.id);
      return conversation;
    } catch (error) {
      state = state.copyWith(error: _readableError(error));
      return null;
    }
  }

  Future<ChatNuConversation?> createGroup({
    required String title,
    required List<String> usernames,
  }) async {
    final repository = _repository;
    if (_isDemo || repository == null) return null;
    try {
      final conversation = await repository.createGroup(
        title: title,
        usernames: usernames,
      );
      _replaceConversation(conversation, insertIfMissing: true, sort: true);
      selectConversation(conversation.id);
      return conversation;
    } catch (error) {
      state = state.copyWith(error: _readableError(error));
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> _sendTextAwait(ChatNuMessage optimistic) async {
    final repository = _repository;
    if (repository == null) return;
    try {
      final sent = await repository.sendText(
        conversationId: optimistic.conversationId,
        clientId: optimistic.clientId ?? optimistic.id,
        text: optimistic.body,
      );
      _replaceMessage(optimistic.conversationId, optimistic.id, sent);
      await refreshConversations();
    } catch (error) {
      _replaceMessage(
        optimistic.conversationId,
        optimistic.id,
        optimistic.copyWith(deliveryState: MessageDeliveryState.failed),
      );
      state = state.copyWith(error: _readableError(error));
    }
  }

  Future<void> _setPinWithRollback(
    ChatNuConversation original,
    bool newValue,
  ) async {
    try {
      await _repository?.setConversationPin(original.id, newValue);
    } catch (error) {
      _replaceConversation(original, sort: true);
      state = state.copyWith(error: _readableError(error));
    }
  }

  Future<void> _setMuteWithRollback(
    ChatNuConversation original,
    bool newValue,
  ) async {
    try {
      await _repository?.setConversationMute(original.id, newValue);
    } catch (error) {
      _replaceConversation(original);
      state = state.copyWith(error: _readableError(error));
    }
  }

  Future<void> _markReadWithRollback(
    String conversationId,
    int previousUnread,
  ) async {
    try {
      await _repository?.markRead(conversationId);
    } catch (error) {
      state = state.copyWith(
        conversations: state.conversations
            .map(
              (conversation) =>
                  conversation.id == conversationId &&
                      conversation.unreadCount == 0
                  ? conversation.copyWith(unreadCount: previousUnread)
                  : conversation,
            )
            .toList(growable: false),
        error: _readableError(error),
      );
    }
  }

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString() ?? '';
    if (type == 'message.created' && event['message'] is Map) {
      final raw = (event['message'] as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      );
      unawaited(_mergeRealtimeMessage(raw));
      return;
    }
    if (type == 'conversation.created') {
      unawaited(refreshConversations());
      return;
    }
    if (type == 'conversation.read') {
      final conversationId = event['conversationId']?.toString();
      if (conversationId != null) {
        state = state.copyWith(
          conversations: state.conversations
              .map(
                (conversation) => conversation.id == conversationId
                    ? conversation.copyWith(unreadCount: 0)
                    : conversation,
              )
              .toList(growable: false),
        );
      }
    }
  }

  Future<void> _mergeRealtimeMessage(Map<String, dynamic> raw) async {
    final repository = _repository;
    if (repository == null) return;
    try {
      final message = await repository.messageFromRealtime(raw);
      final existing =
          state.messagesByConversation[message.conversationId].orEmpty;
      final duplicate = existing.any(
        (item) =>
            item.id == message.id ||
            (message.clientId != null &&
                (item.clientId == message.clientId ||
                    item.id == message.clientId)),
      );
      if (!duplicate) {
        _appendMessage(message);
      } else if (message.clientId != null) {
        final local = existing.lastWhereOrNull(
          (item) =>
              item.clientId == message.clientId || item.id == message.clientId,
        );
        if (local != null) {
          _replaceMessage(message.conversationId, local.id, message);
        }
      }
      unawaited(refreshConversations());
    } catch (_) {
      // A malformed realtime event should not terminate the live connection.
    }
  }

  void _appendMessage(ChatNuMessage message) {
    final map = Map<String, List<ChatNuMessage>>.from(
      state.messagesByConversation,
    );
    map[message.conversationId] = <ChatNuMessage>[
      ...map[message.conversationId].orEmpty,
      message,
    ];
    state = state.copyWith(messagesByConversation: map);
  }

  void _replaceMessage(
    String conversationId,
    String oldId,
    ChatNuMessage replacement,
  ) {
    final map = Map<String, List<ChatNuMessage>>.from(
      state.messagesByConversation,
    );
    map[conversationId] = map[conversationId].orEmpty
        .map((message) => message.id == oldId ? replacement : message)
        .toList(growable: false);
    state = state.copyWith(messagesByConversation: map);
  }

  void _replaceConversation(
    ChatNuConversation replacement, {
    bool insertIfMissing = false,
    bool sort = false,
  }) {
    final exists = state.conversations.any(
      (conversation) => conversation.id == replacement.id,
    );
    var conversations = state.conversations
        .map(
          (conversation) =>
              conversation.id == replacement.id ? replacement : conversation,
        )
        .toList(growable: true);
    if (!exists && insertIfMissing) conversations.insert(0, replacement);
    if (sort) conversations = _sortConversations(conversations);
    state = state.copyWith(conversations: conversations);
  }

  void _updateConversationPreview(
    String conversationId,
    String preview,
    DateTime sentAt,
  ) {
    state = state.copyWith(
      conversations: _sortConversations(
        state.conversations
            .map(
              (conversation) => conversation.id == conversationId
                  ? conversation.copyWith(
                      lastMessagePreview: preview,
                      lastActivityAt: sentAt,
                    )
                  : conversation,
            )
            .toList(growable: false),
      ),
    );
  }

  List<ChatNuConversation> _sortConversations(
    List<ChatNuConversation> conversations,
  ) {
    final sorted = conversations.toList(growable: true);
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.lastActivityAt.compareTo(a.lastActivityAt);
    });
    return sorted;
  }

  void _sendDemoText(String conversationId, String text) {
    final now = DateTime.now();
    final message = ChatNuMessage(
      id: 'local-${now.microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: state.currentUser.id,
      senderName: state.currentUser.displayName,
      body: text,
      sentAt: now,
      deliveryState: MessageDeliveryState.queuedOffline,
    );
    _appendMessage(message);
    _updateConversationPreview(conversationId, text, now);
  }

  MessengerDemoState _demoState() {
    final conversations = <ChatNuConversation>[
      ChatNuConversation(
        id: 'direct-leila',
        title: 'Leila Farhadi',
        kind: ConversationKind.direct,
        members: const <ChatNuUser>[_demoMe, _demoLeila],
        lastMessagePreview: 'آره، نسخه جدید خیلی تمیزتر شده.',
        lastActivityAt: DateTime(2026, 8, 29, 10, 12),
        unreadCount: 2,
        isPinned: true,
      ),
      ChatNuConversation(
        id: 'group-design',
        title: 'Design team',
        kind: ConversationKind.group,
        members: const <ChatNuUser>[_demoMe, _demoNavid, _demoMona],
        lastMessagePreview: 'Mona: I pushed the updated prototype.',
        lastActivityAt: DateTime(2026, 8, 29, 9, 38),
        isMuted: true,
      ),
      ChatNuConversation(
        id: 'direct-navid',
        title: 'Navid Moradi',
        kind: ConversationKind.direct,
        members: const <ChatNuUser>[_demoMe, _demoNavid],
        lastMessagePreview: 'See you after lunch.',
        lastActivityAt: DateTime(2026, 8, 28, 18, 45),
      ),
    ];
    return MessengerDemoState(
      currentUser: _demoMe,
      destination: MessengerDestination.chats,
      conversations: conversations,
      messagesByConversation: <String, List<ChatNuMessage>>{
        'direct-leila': <ChatNuMessage>[
          ChatNuMessage(
            id: 'm1',
            conversationId: 'direct-leila',
            senderId: _demoLeila.id,
            senderName: _demoLeila.displayName,
            body: 'سلام، فایل طراحی رو دیدی؟',
            sentAt: DateTime(2026, 8, 29, 10, 8),
          ),
          ChatNuMessage(
            id: 'm2',
            conversationId: 'direct-leila',
            senderId: _demoMe.id,
            senderName: _demoMe.displayName,
            body: 'آره، نسخه جدید خیلی تمیزتر شده.',
            sentAt: DateTime(2026, 8, 29, 10, 12),
          ),
        ],
        'group-design': <ChatNuMessage>[
          ChatNuMessage(
            id: 'm3',
            conversationId: 'group-design',
            senderId: _demoNavid.id,
            senderName: _demoNavid.displayName,
            body: 'Can we keep the composer compact on tablets?',
            sentAt: DateTime(2026, 8, 29, 9, 31),
          ),
          ChatNuMessage(
            id: 'm4',
            conversationId: 'group-design',
            senderId: _demoMona.id,
            senderName: _demoMona.displayName,
            body: 'I pushed the updated prototype.',
            sentAt: DateTime(2026, 8, 29, 9, 38),
          ),
        ],
        'direct-navid': <ChatNuMessage>[
          ChatNuMessage(
            id: 'm5',
            conversationId: 'direct-navid',
            senderId: _demoNavid.id,
            senderName: _demoNavid.displayName,
            body: 'See you after lunch.',
            sentAt: DateTime(2026, 8, 28, 18, 45),
          ),
        ],
      },
    );
  }

  String _readableError(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}

final messengerDemoProvider =
    NotifierProvider<MessengerDemoController, MessengerDemoState>(
      MessengerDemoController.new,
    );

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }

  T? lastWhereOrNull(bool Function(T item) predicate) {
    T? result;
    for (final item in this) {
      if (predicate(item)) result = item;
    }
    return result;
  }
}

extension<T> on List<T>? {
  List<T> get orEmpty => this ?? <T>[];
}
