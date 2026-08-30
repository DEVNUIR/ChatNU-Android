import 'dart:async';
import 'dart:typed_data';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/network/chatnu_api_client.dart';
import 'package:chatnu/core/realtime/chatnu_realtime_client.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
import 'package:chatnu/features/auth/application/session_controller.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/home/data/messenger_repository.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MessengerDestination { chats, contacts, settings }

enum MessengerSyncStatus { idle, synchronizing, failed }

class ConversationLoadState {
  const ConversationLoadState({
    this.initialLoading = false,
    this.loadingOlder = false,
    this.hasMore = true,
    this.oldestLoadedAt,
    this.initialError,
    this.olderError,
    this.messageError,
  });

  final bool initialLoading;
  final bool loadingOlder;
  final bool hasMore;
  final DateTime? oldestLoadedAt;
  final String? initialError;
  final String? olderError;
  final String? messageError;

  ConversationLoadState copyWith({
    bool? initialLoading,
    bool? loadingOlder,
    bool? hasMore,
    DateTime? oldestLoadedAt,
    String? initialError,
    bool clearInitialError = false,
    String? olderError,
    bool clearOlderError = false,
    String? messageError,
    bool clearMessageError = false,
  }) {
    return ConversationLoadState(
      initialLoading: initialLoading ?? this.initialLoading,
      loadingOlder: loadingOlder ?? this.loadingOlder,
      hasMore: hasMore ?? this.hasMore,
      oldestLoadedAt: oldestLoadedAt ?? this.oldestLoadedAt,
      initialError: clearInitialError
          ? null
          : initialError ?? this.initialError,
      olderError: clearOlderError ? null : olderError ?? this.olderError,
      messageError: clearMessageError
          ? null
          : messageError ?? this.messageError,
    );
  }
}

class MessengerDemoState {
  const MessengerDemoState({
    required this.currentUser,
    required this.destination,
    required this.conversations,
    required this.messagesByConversation,
    this.selectedConversationId,
    this.realtimeStatus = RealtimeConnectionStatus.disconnected,
    this.syncStatus = MessengerSyncStatus.idle,
    this.syncError,
    this.conversationsLoading = false,
    this.conversationsError,
    this.conversationStates = const <String, ConversationLoadState>{},
    this.drafts = const <String, String>{},
    this.contactResults = const <ChatNuUser>[],
    this.contactSearchLoading = false,
    this.contactSearchError,
  });

  final ChatNuUser currentUser;
  final MessengerDestination destination;
  final List<ChatNuConversation> conversations;
  final Map<String, List<ChatNuMessage>> messagesByConversation;
  final String? selectedConversationId;
  final RealtimeConnectionStatus realtimeStatus;
  final MessengerSyncStatus syncStatus;
  final String? syncError;
  final bool conversationsLoading;
  final String? conversationsError;
  final Map<String, ConversationLoadState> conversationStates;
  final Map<String, String> drafts;
  final List<ChatNuUser> contactResults;
  final bool contactSearchLoading;
  final String? contactSearchError;

  // Transitional compatibility for retained surfaces. New messenger behavior must
  // use the scoped fields above instead of driving unrelated UI from these getters.
  bool get isLoading => conversationsLoading;
  String? get error => conversationsError ?? contactSearchError ?? syncError;

  ConversationLoadState conversationState(String conversationId) =>
      conversationStates[conversationId] ?? const ConversationLoadState();

  MessengerDemoState copyWith({
    ChatNuUser? currentUser,
    MessengerDestination? destination,
    List<ChatNuConversation>? conversations,
    Map<String, List<ChatNuMessage>>? messagesByConversation,
    String? selectedConversationId,
    bool clearSelection = false,
    RealtimeConnectionStatus? realtimeStatus,
    MessengerSyncStatus? syncStatus,
    String? syncError,
    bool clearSyncError = false,
    bool? conversationsLoading,
    String? conversationsError,
    bool clearConversationsError = false,
    Map<String, ConversationLoadState>? conversationStates,
    Map<String, String>? drafts,
    List<ChatNuUser>? contactResults,
    bool? contactSearchLoading,
    String? contactSearchError,
    bool clearContactSearchError = false,
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
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: clearSyncError ? null : syncError ?? this.syncError,
      conversationsLoading: conversationsLoading ?? this.conversationsLoading,
      conversationsError: clearConversationsError
          ? null
          : conversationsError ?? this.conversationsError,
      conversationStates: conversationStates ?? this.conversationStates,
      drafts: drafts ?? this.drafts,
      contactResults: contactResults ?? this.contactResults,
      contactSearchLoading: contactSearchLoading ?? this.contactSearchLoading,
      contactSearchError: clearContactSearchError
          ? null
          : contactSearchError ?? this.contactSearchError,
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
  bool _syncInProgress = false;

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
      conversationsLoading: session.isAuthenticated,
    );
  }

  Future<void> _startProduction() async {
    if (_isDemo || !ref.read(sessionProvider).isAuthenticated) return;
    final repository = ref.read(messengerRepositoryProvider);
    _repository = repository;
    _realtimeEvents = repository.realtime.events.listen(_handleRealtimeEvent);
    _realtimeStatus = repository.realtime.status.listen(
      (status) => _handleRealtimeStatus(status),
    );

    await _restoreCachedState();
    unawaited(refreshConversations());
    try {
      await repository.startRealtime();
    } catch (error) {
      state = state.copyWith(
        realtimeStatus: RealtimeConnectionStatus.disconnected,
        syncStatus: MessengerSyncStatus.failed,
        syncError: _readableError(error),
      );
    }
  }

  Future<void> _restoreCachedState() async {
    final repository = _repository;
    if (repository == null) return;
    try {
      final snapshot = await repository.loadCachedState();
      final pageStates = <String, ConversationLoadState>{};
      for (final entry in snapshot.paginationByConversation.entries) {
        pageStates[entry.key] = ConversationLoadState(
          hasMore: entry.value.hasMore,
          oldestLoadedAt: entry.value.oldestLoadedAt,
        );
      }
      state = state.copyWith(
        conversations: _sortConversations(snapshot.conversations),
        messagesByConversation: snapshot.messagesByConversation,
        drafts: snapshot.drafts,
        conversationStates: pageStates,
        conversationsLoading: snapshot.conversations.isEmpty,
      );
    } catch (_) {
      // A damaged cache must never prevent a normal remote session from starting.
      state = state.copyWith(conversationsLoading: true);
    }
  }

  Future<void> refreshConversations() async {
    if (_isDemo) return;
    final repository = _repository;
    if (repository == null) return;
    state = state.copyWith(
      conversationsLoading: true,
      clearConversationsError: true,
    );
    try {
      final conversations = await repository.loadConversations();
      state = state.copyWith(
        conversations: _sortConversations(conversations),
        conversationsLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        conversationsLoading: false,
        conversationsError: _readableError(error),
      );
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
    final updated = state.conversations
        .map(
          (conversation) => conversation.id == conversationId
              ? conversation.copyWith(unreadCount: 0)
              : conversation,
        )
        .toList(growable: false);
    state = state.copyWith(
      destination: MessengerDestination.chats,
      selectedConversationId: conversationId,
      conversations: updated,
    );
    final selected = updated
        .where((conversation) => conversation.id == conversationId)
        .firstOrNull;
    if (!_isDemo && selected != null) {
      unawaited(_repository?.persistConversation(selected));
    }
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
    final current = state.conversationState(conversationId);
    if (current.initialLoading) return;
    _setConversationState(
      conversationId,
      current.copyWith(
        initialLoading:
            state.messagesByConversation[conversationId].orEmpty.isEmpty,
        clearInitialError: true,
      ),
    );
    try {
      final page = await repository.loadInitialMessages(conversationId);
      final map = Map<String, List<ChatNuMessage>>.from(
        state.messagesByConversation,
      );
      map[conversationId] = page.messages;
      state = state.copyWith(messagesByConversation: map);
      _setConversationState(
        conversationId,
        state
            .conversationState(conversationId)
            .copyWith(
              initialLoading: false,
              hasMore: page.hasMore,
              oldestLoadedAt: page.oldestLoadedAt,
              clearInitialError: true,
            ),
      );
    } catch (error) {
      _setConversationState(
        conversationId,
        state
            .conversationState(conversationId)
            .copyWith(
              initialLoading: false,
              initialError: _readableError(error),
            ),
      );
    }
  }

  Future<void> loadOlderMessages(String conversationId) async {
    if (_isDemo) return;
    final repository = _repository;
    if (repository == null) return;
    final current = state.conversationState(conversationId);
    if (current.loadingOlder || !current.hasMore) return;
    _setConversationState(
      conversationId,
      current.copyWith(loadingOlder: true, clearOlderError: true),
    );
    try {
      final page = await repository.loadOlderMessages(conversationId);
      final map = Map<String, List<ChatNuMessage>>.from(
        state.messagesByConversation,
      );
      map[conversationId] = mergeMessageLists(
        map[conversationId].orEmpty,
        page.messages,
      );
      state = state.copyWith(messagesByConversation: map);
      _setConversationState(
        conversationId,
        state
            .conversationState(conversationId)
            .copyWith(
              loadingOlder: false,
              hasMore: page.hasMore,
              oldestLoadedAt: page.oldestLoadedAt,
              clearOlderError: true,
            ),
      );
    } catch (error) {
      _setConversationState(
        conversationId,
        state
            .conversationState(conversationId)
            .copyWith(loadingOlder: false, olderError: _readableError(error)),
      );
    }
  }

  void setDraft(String conversationId, String value) {
    final drafts = Map<String, String>.from(state.drafts);
    if (value.isEmpty) {
      drafts.remove(conversationId);
    } else {
      drafts[conversationId] = value;
    }
    state = state.copyWith(drafts: drafts);
    if (!_isDemo) unawaited(_repository?.saveDraft(conversationId, value));
  }

  void togglePin(String conversationId) {
    final target = state.conversations
        .where((conversation) => conversation.id == conversationId)
        .firstOrNull;
    if (target == null) return;
    final newValue = !target.isPinned;
    final updated = target.copyWith(isPinned: newValue);
    _replaceConversation(updated, sort: true);
    if (_isDemo) return;
    unawaited(_repository?.persistConversation(updated));
    unawaited(_setPinWithRollback(target, newValue));
  }

  void toggleMute(String conversationId) {
    final target = state.conversations
        .where((conversation) => conversation.id == conversationId)
        .firstOrNull;
    if (target == null) return;
    final newValue = !target.isMuted;
    final updated = target.copyWith(isMuted: newValue);
    _replaceConversation(updated);
    if (_isDemo) return;
    unawaited(_repository?.persistConversation(updated));
    unawaited(_setMuteWithRollback(target, newValue));
  }

  void sendText(String conversationId, String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return;
    if (_isDemo) {
      _sendDemoText(conversationId, text);
      setDraft(conversationId, '');
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
    _setConversationState(
      conversationId,
      state.conversationState(conversationId).copyWith(clearMessageError: true),
    );
    _updateConversationPreview(conversationId, text, optimistic.sentAt);
    setDraft(conversationId, '');
    unawaited(_sendTextAwait(optimistic, replaceId: failedMatch?.id));
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
    await repository.persistMessage(optimistic);
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
      final failed = optimistic.copyWith(
        deliveryState: MessageDeliveryState.failed,
      );
      _replaceMessage(conversationId, clientId, failed);
      await repository.persistMessage(failed, replaceId: clientId);
      _setConversationState(
        conversationId,
        state
            .conversationState(conversationId)
            .copyWith(messageError: _readableError(error)),
      );
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
    await repository.persistMessage(optimistic);
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
      final failed = optimistic.copyWith(
        deliveryState: MessageDeliveryState.failed,
      );
      _replaceMessage(conversationId, clientId, failed);
      await repository.persistMessage(failed, replaceId: clientId);
      _setConversationState(
        conversationId,
        state
            .conversationState(conversationId)
            .copyWith(messageError: _readableError(error)),
      );
    }
  }

  Future<Uint8List?> downloadAttachment(ChatNuMessage message) async {
    final repository = _repository;
    if (_isDemo || repository == null) return null;
    try {
      return await repository.downloadAttachment(message);
    } catch (error) {
      _setConversationState(
        message.conversationId,
        state
            .conversationState(message.conversationId)
            .copyWith(messageError: _readableError(error)),
      );
      return null;
    }
  }

  Future<List<ChatNuUser>> searchUsers(String query) async {
    final repository = _repository;
    if (_isDemo || repository == null) return const <ChatNuUser>[];
    state = state.copyWith(
      contactSearchLoading: query.trim().length >= 2,
      clearContactSearchError: true,
    );
    try {
      final users = await repository.searchUsers(query);
      state = state.copyWith(
        contactResults: users,
        contactSearchLoading: false,
      );
      return users;
    } catch (error) {
      state = state.copyWith(
        contactSearchLoading: false,
        contactSearchError: _readableError(error),
      );
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
      state = state.copyWith(contactSearchError: _readableError(error));
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
      state = state.copyWith(contactSearchError: _readableError(error));
      return null;
    }
  }

  void clearConversationError(String conversationId) {
    final current = state.conversationState(conversationId);
    _setConversationState(
      conversationId,
      current.copyWith(
        clearInitialError: true,
        clearOlderError: true,
        clearMessageError: true,
      ),
    );
  }

  void clearError() {
    final cleared = <String, ConversationLoadState>{};
    for (final entry in state.conversationStates.entries) {
      cleared[entry.key] = entry.value.copyWith(
        clearInitialError: true,
        clearOlderError: true,
        clearMessageError: true,
      );
    }
    state = state.copyWith(
      conversationStates: cleared,
      clearConversationsError: true,
      clearContactSearchError: true,
      clearSyncError: true,
    );
  }

  Future<void> retrySync() => _synchronizeAfterConnect();

  Future<void> _sendTextAwait(
    ChatNuMessage optimistic, {
    String? replaceId,
  }) async {
    final repository = _repository;
    if (repository == null) return;
    await repository.persistMessage(optimistic, replaceId: replaceId);
    try {
      final sent = await repository.sendText(
        conversationId: optimistic.conversationId,
        clientId: optimistic.clientId ?? optimistic.id,
        text: optimistic.body,
      );
      _replaceMessage(optimistic.conversationId, optimistic.id, sent);
      await refreshConversations();
    } catch (error) {
      final failed = optimistic.copyWith(
        deliveryState: MessageDeliveryState.failed,
      );
      _replaceMessage(optimistic.conversationId, optimistic.id, failed);
      await repository.persistMessage(failed, replaceId: optimistic.id);
      _setConversationState(
        optimistic.conversationId,
        state
            .conversationState(optimistic.conversationId)
            .copyWith(messageError: _readableError(error)),
      );
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
      await _repository?.persistConversation(original);
      state = state.copyWith(conversationsError: _readableError(error));
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
      await _repository?.persistConversation(original);
      state = state.copyWith(conversationsError: _readableError(error));
    }
  }

  Future<void> _markReadWithRollback(
    String conversationId,
    int previousUnread,
  ) async {
    try {
      await _repository?.markRead(conversationId);
    } catch (error) {
      final conversations = state.conversations
          .map(
            (conversation) =>
                conversation.id == conversationId &&
                    conversation.unreadCount == 0
                ? conversation.copyWith(unreadCount: previousUnread)
                : conversation,
          )
          .toList(growable: false);
      state = state.copyWith(
        conversations: conversations,
        conversationsError: _readableError(error),
      );
      final restored = conversations
          .where((conversation) => conversation.id == conversationId)
          .firstOrNull;
      if (restored != null) {
        await _repository?.persistConversation(restored);
      }
    }
  }

  void _handleRealtimeStatus(RealtimeConnectionStatus status) {
    if (status != RealtimeConnectionStatus.connected) {
      state = state.copyWith(realtimeStatus: status);
      return;
    }
    state = state.copyWith(realtimeStatus: status);
    unawaited(_synchronizeAfterConnect());
  }

  Future<void> _synchronizeAfterConnect() async {
    if (_isDemo || _syncInProgress) return;
    final repository = _repository;
    if (repository == null) return;
    _syncInProgress = true;
    state = state.copyWith(
      syncStatus: MessengerSyncStatus.synchronizing,
      clearSyncError: true,
    );
    try {
      final batch = await repository.catchUp();
      for (final message in batch.messages) {
        _mergeMessageIntoState(message);
      }
      state = state.copyWith(
        syncStatus: MessengerSyncStatus.idle,
        clearSyncError: true,
      );
      unawaited(refreshConversations());
    } catch (error) {
      state = state.copyWith(
        syncStatus: MessengerSyncStatus.failed,
        syncError: _readableError(error),
      );
    } finally {
      _syncInProgress = false;
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
      final userId = event['userId']?.toString();
      if (conversationId != null && userId == state.currentUser.id) {
        final conversations = state.conversations
            .map(
              (conversation) => conversation.id == conversationId
                  ? conversation.copyWith(unreadCount: 0)
                  : conversation,
            )
            .toList(growable: false);
        state = state.copyWith(conversations: conversations);
        final updated = conversations
            .where((conversation) => conversation.id == conversationId)
            .firstOrNull;
        if (updated != null) {
          unawaited(_repository?.persistConversation(updated));
        }
      }
    }
  }

  Future<void> _mergeRealtimeMessage(Map<String, dynamic> raw) async {
    final repository = _repository;
    if (repository == null) return;
    try {
      final message = await repository.messageFromRealtime(raw);
      final existed = _containsMessage(message);
      _mergeMessageIntoState(message);
      if (!existed) _applyRealtimeConversationUpdate(message);
    } catch (_) {
      // A malformed/decrypt-failed realtime event must not terminate the socket.
    }
  }

  bool _containsMessage(ChatNuMessage message) {
    return state.messagesByConversation[message.conversationId].orEmpty.any(
      (item) =>
          item.id == message.id ||
          (message.clientId != null &&
              (item.clientId == message.clientId ||
                  item.id == message.clientId)),
    );
  }

  void _mergeMessageIntoState(ChatNuMessage message) {
    final map = Map<String, List<ChatNuMessage>>.from(
      state.messagesByConversation,
    );
    map[message.conversationId] = mergeMessageLists(
      map[message.conversationId].orEmpty,
      <ChatNuMessage>[message],
    );
    state = state.copyWith(messagesByConversation: map);
    _updateConversationPreviewIfNewer(message);
  }

  void _applyRealtimeConversationUpdate(ChatNuMessage message) {
    final selected = state.selectedConversationId == message.conversationId;
    final mine = message.senderId == state.currentUser.id;
    final conversations = state.conversations
        .map((conversation) {
          if (conversation.id != message.conversationId) return conversation;
          return conversation.copyWith(
            lastMessagePreview: message.body,
            lastActivityAt: message.sentAt,
            unreadCount: mine || selected
                ? conversation.unreadCount
                : conversation.unreadCount + 1,
          );
        })
        .toList(growable: false);
    state = state.copyWith(conversations: _sortConversations(conversations));
    final updated = conversations
        .where((conversation) => conversation.id == message.conversationId)
        .firstOrNull;
    if (updated != null) {
      unawaited(_repository?.persistConversation(updated));
    } else {
      unawaited(refreshConversations());
    }
    if (selected && !mine) {
      unawaited(_repository?.markRead(message.conversationId));
    }
  }

  void _appendMessage(ChatNuMessage message) {
    final map = Map<String, List<ChatNuMessage>>.from(
      state.messagesByConversation,
    );
    map[message.conversationId] = mergeMessageLists(
      map[message.conversationId].orEmpty,
      <ChatNuMessage>[message],
    );
    state = state.copyWith(messagesByConversation: map);
  }

  void _replaceMessage(
    String conversationId,
    String oldId,
    ChatNuMessage replacement,
  ) {
    final existing = state.messagesByConversation[conversationId].orEmpty;
    final withoutOld = existing
        .where((message) => message.id != oldId)
        .toList(growable: false);
    final map = Map<String, List<ChatNuMessage>>.from(
      state.messagesByConversation,
    );
    map[conversationId] = mergeMessageLists(withoutOld, <ChatNuMessage>[
      replacement,
    ]);
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
    final conversations = _sortConversations(
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
    );
    state = state.copyWith(conversations: conversations);
    final updated = conversations
        .where((conversation) => conversation.id == conversationId)
        .firstOrNull;
    if (!_isDemo && updated != null) {
      unawaited(_repository?.persistConversation(updated));
    }
  }

  void _updateConversationPreviewIfNewer(ChatNuMessage message) {
    final target = state.conversations
        .where((conversation) => conversation.id == message.conversationId)
        .firstOrNull;
    if (target == null || message.sentAt.isBefore(target.lastActivityAt)) {
      return;
    }
    _updateConversationPreview(
      message.conversationId,
      message.body,
      message.sentAt,
    );
  }

  void _setConversationState(
    String conversationId,
    ConversationLoadState value,
  ) {
    final map = Map<String, ConversationLoadState>.from(
      state.conversationStates,
    );
    map[conversationId] = value;
    state = state.copyWith(conversationStates: map);
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
      clientId: 'local-${now.microsecondsSinceEpoch}',
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
    if (error is ChatNuApiException) {
      return switch (error.statusCode) {
        401 => 'Your session expired. Sign in again.',
        403 => 'This action is not available for your account.',
        404 => 'This conversation is no longer available.',
        429 => 'Too many requests. Try again shortly.',
        _ => 'Couldn’t reach ChatNU. Check your connection and try again.',
      };
    }
    if (error is StateError &&
        error.message.toString().contains('E2EE-capable')) {
      return 'Some people in this chat need to open the latest ChatNU before you can send securely.';
    }
    return 'Something went wrong. Try again.';
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
