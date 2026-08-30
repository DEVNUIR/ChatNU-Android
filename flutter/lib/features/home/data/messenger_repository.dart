import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:chatnu/core/crypto/device_e2ee.dart';
import 'package:chatnu/core/network/api_models.dart';
import 'package:chatnu/core/network/chatnu_api_client.dart';
import 'package:chatnu/core/realtime/chatnu_realtime_client.dart';
import 'package:chatnu/core/storage/credential_vault.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/home/data/messenger_local_store.dart';
import 'package:chatnu/features/messages/data/encrypted_message_mapper.dart';
import 'package:chatnu/features/messages/domain/message.dart';

class MessageHistoryPage {
  const MessageHistoryPage({
    required this.messages,
    required this.hasMore,
    this.oldestLoadedAt,
  });

  final List<ChatNuMessage> messages;
  final bool hasMore;
  final DateTime? oldestLoadedAt;
}

class MessengerSyncBatch {
  const MessengerSyncBatch({required this.messages, required this.cursor});

  final List<ChatNuMessage> messages;
  final String cursor;
}

class MessengerRepository {
  MessengerRepository({
    required ChatNuApiClient api,
    required DeviceE2ee e2ee,
    required CredentialVault vault,
    required MessengerLocalStore localStore,
  }) : _api = api,
       _e2ee = e2ee,
       _vault = vault,
       _localStore = localStore,
       _mapper = EncryptedMessageMapper(e2ee: e2ee, vault: vault),
       realtime = ChatNuRealtimeClient(endpoint: api.endpoint, vault: vault);

  static const maxAttachmentPlaintextBytes = 24 * 1024 * 1024;
  static const messagePageSize = 50;
  static const syncPageSize = 500;

  final ChatNuApiClient _api;
  final DeviceE2ee _e2ee;
  final CredentialVault _vault;
  final MessengerLocalStore _localStore;
  final EncryptedMessageMapper _mapper;
  final ChatNuRealtimeClient realtime;

  String get _scope {
    final account = _vault.session?.user.id ?? _vault.cryptoAccount ?? 'unknown';
    return '${_api.endpoint.identityNamespace}|$account';
  }

  Future<MessengerCacheSnapshot> loadCachedState() =>
      _localStore.readSnapshot(_scope);

  Future<List<ChatNuConversation>> loadConversations() async {
    final dtos = await _api.conversations();
    final conversations = await Future.wait(dtos.map(_conversationFromDto));
    await _localStore.replaceConversations(_scope, conversations);
    return conversations;
  }

  Future<MessageHistoryPage> loadInitialMessages(String conversationId) async {
    final previousPage = await _localStore.readPagination(_scope, conversationId);
    final dtos = await _api.messages(
      conversationId,
      limit: messagePageSize,
    );
    final remote = await Future.wait(dtos.map(_mapper.toMessage));
    await _localStore.upsertMessages(_scope, remote);

    final cached = await _localStore.readMessages(_scope, conversationId);
    final merged = mergeMessageLists(cached, remote);
    final oldest = merged.isEmpty ? null : merged.first.sentAt;
    final page = CachedConversationPage(
      hasMore: dtos.length == messagePageSize || (previousPage?.hasMore ?? false),
      oldestLoadedAt: oldest,
    );
    await _localStore.savePagination(_scope, conversationId, page);
    return MessageHistoryPage(
      messages: merged,
      hasMore: page.hasMore,
      oldestLoadedAt: oldest,
    );
  }

  Future<List<ChatNuMessage>> loadMessages(String conversationId) async {
    return (await loadInitialMessages(conversationId)).messages;
  }

  Future<MessageHistoryPage> loadOlderMessages(String conversationId) async {
    final cached = await _localStore.readMessages(_scope, conversationId);
    final storedPage = await _localStore.readPagination(_scope, conversationId);
    if (storedPage?.hasMore == false) {
      return MessageHistoryPage(
        messages: const <ChatNuMessage>[],
        hasMore: false,
        oldestLoadedAt: storedPage?.oldestLoadedAt,
      );
    }

    final oldest = storedPage?.oldestLoadedAt ??
        (cached.isEmpty ? null : cached.first.sentAt);
    if (oldest == null) return loadInitialMessages(conversationId);

    final dtos = await _api.messages(
      conversationId,
      before: oldest.toUtc().toIso8601String(),
      limit: messagePageSize,
    );
    final older = await Future.wait(dtos.map(_mapper.toMessage));
    await _localStore.upsertMessages(_scope, older);
    final nextOldest = older.isEmpty ? oldest : older.first.sentAt;
    final page = CachedConversationPage(
      hasMore: dtos.length == messagePageSize,
      oldestLoadedAt: nextOldest,
    );
    await _localStore.savePagination(_scope, conversationId, page);
    return MessageHistoryPage(
      messages: older,
      hasMore: page.hasMore,
      oldestLoadedAt: nextOldest,
    );
  }

  Future<List<ChatNuUser>> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const <ChatNuUser>[];
    final users = await _api.searchUsers(trimmed);
    return users.map(_userFromDto).toList(growable: false);
  }

  Future<ChatNuConversation> openDirect(String username) async {
    final dto = await _api.createDirect(username.trim().toLowerCase());
    final conversation = await _conversationFromDto(dto);
    await _localStore.upsertConversation(_scope, conversation);
    return conversation;
  }

  Future<ChatNuConversation> createGroup({
    required String title,
    required List<String> usernames,
  }) async {
    final dto = await _api.createGroup(
      title: title.trim(),
      usernames: usernames
          .map((value) => value.trim().toLowerCase())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
    );
    final conversation = await _conversationFromDto(dto);
    await _localStore.upsertConversation(_scope, conversation);
    return conversation;
  }

  ChatNuMessage optimisticText({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
    String? clientId,
  }) {
    final id = clientId ?? newClientId();
    return ChatNuMessage(
      id: id,
      clientId: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      body: text.trim(),
      sentAt: DateTime.now(),
      deliveryState: MessageDeliveryState.sending,
    );
  }

  Future<void> persistMessage(
    ChatNuMessage message, {
    String? replaceId,
  }) async {
    if (replaceId == null) {
      await _localStore.upsertMessages(_scope, <ChatNuMessage>[message]);
    } else {
      await _localStore.replaceMessage(
        _scope,
        message.conversationId,
        replaceId,
        message,
      );
    }
  }

  Future<void> persistConversation(ChatNuConversation conversation) =>
      _localStore.upsertConversation(_scope, conversation);

  Future<void> saveDraft(String conversationId, String text) =>
      _localStore.saveDraft(_scope, conversationId, text);

  Future<ChatNuMessage> sendText({
    required String conversationId,
    required String clientId,
    required String text,
  }) async {
    return _sendEncryptedPayload(
      conversationId: conversationId,
      clientId: clientId,
      type: ChatNuMessageType.text,
      plaintext: text.trim(),
    );
  }

  Future<ChatNuMessage> sendAttachment({
    required String conversationId,
    required String clientId,
    required Uint8List plaintextBytes,
    required String fileName,
    required String mimeType,
    required ChatNuMessageType type,
    Map<String, dynamic> privateMetadata = const <String, dynamic>{},
  }) async {
    if (plaintextBytes.length > maxAttachmentPlaintextBytes) {
      throw StateError('Attachment is larger than 24 MiB.');
    }
    final encrypted = _e2ee.encryptAttachment(plaintextBytes);
    final uploaded = await _api.uploadAttachment(
      conversationId: conversationId,
      encryptedBytes: encrypted.ciphertext,
    );
    final payload = jsonEncode(<String, dynamic>{
      'kind': 'attachment',
      'attachmentId': uploaded.id,
      'name': _sanitizeFileName(fileName),
      'mime': mimeType,
      'size': plaintextBytes.length,
      'fileKey': encrypted.keyBase64,
      'fileNonce': encrypted.nonceBase64,
      ...privateMetadata,
    });
    return _sendEncryptedPayload(
      conversationId: conversationId,
      clientId: clientId,
      type: type,
      plaintext: payload,
    );
  }

  Future<ChatNuMessage> sendLocation({
    required String conversationId,
    required String clientId,
    required double latitude,
    required double longitude,
    String? label,
  }) {
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError('Invalid location coordinates.');
    }
    return _sendEncryptedPayload(
      conversationId: conversationId,
      clientId: clientId,
      type: ChatNuMessageType.location,
      plaintext: jsonEncode(<String, dynamic>{
        'kind': 'location',
        'lat': latitude,
        'lng': longitude,
        if (label?.trim().isNotEmpty == true) 'label': label!.trim(),
      }),
    );
  }

  Future<Uint8List> downloadAttachment(ChatNuMessage message) async {
    final attachmentId = message.attachmentId;
    final key = message.attachmentKeyBase64;
    final nonce = message.attachmentNonceBase64;
    if (attachmentId == null || key == null || nonce == null) {
      throw StateError('Attachment decryption metadata is unavailable.');
    }
    final ciphertext = await _api.downloadAttachment(attachmentId);
    return _e2ee.decryptAttachment(
      ciphertext: ciphertext,
      keyBase64: key,
      nonceBase64: nonce,
    );
  }

  Future<void> setConversationPin(String conversationId, bool value) =>
      _api.updateConversationPreferences(conversationId, isPinned: value);

  Future<void> setConversationMute(String conversationId, bool value) =>
      _api.updateConversationPreferences(conversationId, isMuted: value);

  Future<void> markRead(String conversationId) => _api.markRead(conversationId);

  Future<void> startRealtime() => realtime.start();

  Future<void> stopRealtime() => realtime.stop();

  Future<List<PendingCallDto>> pendingCalls() => _api.pendingCalls();

  Future<RtcConfigResponse> rtcConfig() => _api.rtcConfig();

  Future<ChatNuMessage> messageFromRealtime(Map<String, dynamic> json) async {
    final message = await _mapper.toMessage(MessageDto.fromJson(json));
    await _localStore.upsertMessages(_scope, <ChatNuMessage>[message]);
    return message;
  }

  Future<MessengerSyncBatch> catchUp() async {
    final persistedCursor = await _localStore.readSyncCursor(_scope);
    String? requestCursor = persistedCursor;
    String? completedCursor;
    final caughtUp = <ChatNuMessage>[];

    for (var page = 0; page < 100; page += 1) {
      final response = await _api.sync(
        cursor: requestCursor,
        limit: syncPageSize,
      );
      final pageMessages = <ChatNuMessage>[];
      for (final event in response.events) {
        if (event.type != 'message.created' || event.message == null) continue;
        pageMessages.add(await _mapper.toMessage(event.message!));
      }
      if (pageMessages.isNotEmpty) {
        await _localStore.upsertMessages(_scope, pageMessages);
        caughtUp.addAll(pageMessages);
      }

      completedCursor = response.nextCursor;
      if (response.events.length < syncPageSize) break;
      if (response.nextCursor == requestCursor) {
        throw StateError('Realtime synchronization cursor did not advance.');
      }
      requestCursor = response.nextCursor;
    }

    final cursor = completedCursor ?? persistedCursor ?? DateTime.now().toUtc().toIso8601String();
    await _localStore.saveSyncCursor(_scope, cursor);
    return MessengerSyncBatch(
      messages: mergeMessageLists(const <ChatNuMessage>[], caughtUp),
      cursor: cursor,
    );
  }

  Future<ChatNuMessage> _sendEncryptedPayload({
    required String conversationId,
    required String clientId,
    required ChatNuMessageType type,
    required String plaintext,
  }) async {
    final keys = await _api.conversationKeys(conversationId);
    if (keys.missingUserIds.isNotEmpty) {
      throw StateError(
        'Some members must open an E2EE-capable ChatNU client before encrypted messages can be sent.',
      );
    }
    final serverType = EncryptedMessageMapper.serverType(type);
    final envelope = await _mapper.encrypt(
      conversationId: conversationId,
      clientId: clientId,
      serverType: serverType,
      plaintext: plaintext,
      deviceKeys: keys.devices,
    );
    final dto = await _api.sendMessage(
      conversationId: conversationId,
      clientId: clientId,
      type: serverType,
      ciphertext: envelope.ciphertextBase64,
      nonce: envelope.nonceBase64,
      protocolVersion: envelope.protocolVersion,
      metadata: <String, dynamic>{
        'wrappedKeys': envelope.wrappedKeys,
        'senderDeviceId': _vault.deviceId,
        'e2ee': true,
      },
    );
    final sent = await _mapper.toMessage(dto);
    await _localStore.replaceMessage(
      _scope,
      conversationId,
      clientId,
      sent,
    );
    return sent;
  }

  Future<ChatNuConversation> _conversationFromDto(ConversationDto dto) async {
    final preview = dto.lastMessage == null
        ? ''
        : (await _mapper.decryptPayload(dto.lastMessage!)).displayText;
    final activity = DateTime.tryParse(
      dto.lastMessage?.createdAt ?? dto.updatedAt ?? '',
    );
    return ChatNuConversation(
      id: dto.id,
      title: dto.title,
      kind: dto.type == 'GROUP'
          ? ConversationKind.group
          : ConversationKind.direct,
      members: dto.members.map(_userFromDto).toList(growable: false),
      lastMessagePreview: preview,
      lastActivityAt:
          activity?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0),
      avatarUrl: dto.avatarUrl,
      unreadCount: dto.unreadCount,
      isPinned: dto.isPinned,
      isMuted: dto.isMuted,
    );
  }

  ChatNuUser _userFromDto(UserDto dto) => ChatNuUser(
    id: dto.id,
    username: dto.username,
    displayName: dto.displayName,
    avatarUrl: dto.avatarUrl,
    bio: dto.bio,
  );

  String newClientId() {
    final random = Random.secure();
    final bytes = List<int>.generate(12, (_) => random.nextInt(256));
    final entropy = base64Url.encode(bytes).replaceAll('=', '');
    return '${DateTime.now().microsecondsSinceEpoch}-$entropy';
  }

  String _sanitizeFileName(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[\\/:*?"<>|\u0000-\u001F]'), '_')
        .trim();
    if (cleaned.isEmpty) return 'attachment';
    return cleaned.length > 120 ? cleaned.substring(0, 120) : cleaned;
  }
}

List<ChatNuMessage> mergeMessageLists(
  Iterable<ChatNuMessage> existing,
  Iterable<ChatNuMessage> incoming,
) {
  final byIdentity = LinkedHashMap<String, ChatNuMessage>();
  for (final message in existing) {
    byIdentity[_messageIdentity(message)] = message;
  }
  for (final message in incoming) {
    byIdentity[_messageIdentity(message)] = message;
  }
  final merged = byIdentity.values.toList(growable: true)
    ..sort((a, b) {
      final byTime = a.sentAt.compareTo(b.sentAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  return merged;
}

String _messageIdentity(ChatNuMessage message) {
  final clientId = message.clientId;
  return clientId == null || clientId.isEmpty
      ? 'id:${message.id}'
      : 'client:$clientId';
}
