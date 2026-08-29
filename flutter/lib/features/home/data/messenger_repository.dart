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
import 'package:chatnu/features/messages/data/encrypted_message_mapper.dart';
import 'package:chatnu/features/messages/domain/message.dart';

class MessengerRepository {
  MessengerRepository({
    required ChatNuApiClient api,
    required DeviceE2ee e2ee,
    required CredentialVault vault,
  }) : _api = api,
       _e2ee = e2ee,
       _vault = vault,
       _mapper = EncryptedMessageMapper(e2ee: e2ee, vault: vault),
       realtime = ChatNuRealtimeClient(endpoint: api.endpoint, vault: vault);

  static const maxAttachmentPlaintextBytes = 24 * 1024 * 1024;

  final ChatNuApiClient _api;
  final DeviceE2ee _e2ee;
  final CredentialVault _vault;
  final EncryptedMessageMapper _mapper;
  final ChatNuRealtimeClient realtime;

  Future<List<ChatNuConversation>> loadConversations() async {
    final dtos = await _api.conversations();
    return Future.wait(dtos.map(_conversationFromDto));
  }

  Future<List<ChatNuMessage>> loadMessages(String conversationId) async {
    final dtos = await _api.messages(conversationId, limit: 100);
    return Future.wait(dtos.map(_mapper.toMessage));
  }

  Future<List<ChatNuUser>> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const <ChatNuUser>[];
    final users = await _api.searchUsers(trimmed);
    return users.map(_userFromDto).toList(growable: false);
  }

  Future<ChatNuConversation> openDirect(String username) async {
    final dto = await _api.createDirect(username.trim().toLowerCase());
    return _conversationFromDto(dto);
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
    return _conversationFromDto(dto);
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
    });
    return _sendEncryptedPayload(
      conversationId: conversationId,
      clientId: clientId,
      type: type,
      plaintext: payload,
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

  Future<ChatNuMessage> messageFromRealtime(Map<String, dynamic> json) =>
      _mapper.toMessage(MessageDto.fromJson(json));

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
    return _mapper.toMessage(dto);
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
