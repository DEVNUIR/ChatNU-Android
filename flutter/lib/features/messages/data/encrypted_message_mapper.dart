import 'dart:convert';
import 'dart:typed_data';

import 'package:chatnu/core/crypto/device_e2ee.dart';
import 'package:chatnu/core/network/api_models.dart';
import 'package:chatnu/core/storage/credential_vault.dart';
import 'package:chatnu/features/messages/domain/message.dart';

class EncryptedMessageMapper {
  EncryptedMessageMapper({
    required DeviceE2ee e2ee,
    required CredentialVault vault,
  }) : _e2ee = e2ee,
       _vault = vault;

  final DeviceE2ee _e2ee;
  final CredentialVault _vault;

  Future<ChatNuMessage> toMessage(MessageDto dto) async {
    final payload = await decryptPayload(dto);
    return ChatNuMessage(
      id: dto.id,
      clientId: dto.clientId,
      conversationId: dto.conversationId,
      senderId: dto.senderId,
      senderName: dto.senderName,
      body: payload.displayText,
      sentAt: _date(dto.createdAt),
      type: messageTypeFromServer(dto.type),
      deliveryState: MessageDeliveryState.sentToServer,
      attachmentId: payload.attachmentId,
      fileName: payload.fileName,
      mimeType: payload.mimeType,
      sizeBytes: payload.sizeBytes,
      attachmentKeyBase64: payload.fileKey,
      attachmentNonceBase64: payload.fileNonce,
      locationLatitude: payload.latitude,
      locationLongitude: payload.longitude,
      mediaDurationMs: payload.durationMs,
      isVideoNote: payload.videoNote,
    );
  }

  Future<DecryptedPayload> decryptPayload(MessageDto message) async {
    try {
      if (message.protocolVersion != DeviceE2ee.protocolVersion) {
        return const DecryptedPayload(
          displayText: '🔒 Legacy encrypted message unavailable in Flutter',
        );
      }
      final account = _vault.cryptoAccount;
      final deviceId = _vault.deviceId;
      final clientId = message.clientId;
      if (account == null || deviceId == null || clientId == null) {
        throw StateError('Encrypted message session metadata is incomplete.');
      }
      final plainBytes = await _e2ee.decryptMessage(
        account: account,
        deviceId: deviceId,
        ciphertextBase64: message.ciphertext,
        nonceBase64: message.nonce ?? '',
        metadata: message.metadata,
        aad: messageAad(message.conversationId, clientId, message.type),
      );
      return parsePlaintext(utf8.decode(plainBytes));
    } catch (_) {
      return const DecryptedPayload(
        displayText: '🔒 Encrypted message unavailable on this device',
      );
    }
  }

  Future<E2eeEnvelope> encrypt({
    required String conversationId,
    required String clientId,
    required String serverType,
    required String plaintext,
    required List<DeviceKeyDto> deviceKeys,
  }) {
    return _e2ee.encryptMessage(
      plaintext: Uint8List.fromList(utf8.encode(plaintext)),
      recipientKeys: deviceKeys
          .map(
            (key) => RecipientDeviceKey(
              deviceId: key.deviceId,
              publicKeyBase64: key.publicKey,
            ),
          )
          .toList(growable: false),
      aad: messageAad(conversationId, clientId, serverType),
    );
  }

  static String messageAad(
    String conversationId,
    String clientId,
    String serverType,
  ) => '$conversationId|$clientId|$serverType';

  static String serverType(ChatNuMessageType type) => switch (type) {
    ChatNuMessageType.text => 'TEXT',
    ChatNuMessageType.image => 'IMAGE',
    ChatNuMessageType.video => 'VIDEO',
    ChatNuMessageType.voice => 'VOICE',
    ChatNuMessageType.file => 'FILE',
    ChatNuMessageType.location => 'LOCATION',
    ChatNuMessageType.liveLocation => 'LIVE_LOCATION',
    ChatNuMessageType.viewOnceImage => 'VIEW_ONCE_IMAGE',
    ChatNuMessageType.viewOnceVideo => 'VIEW_ONCE_VIDEO',
    ChatNuMessageType.system => 'SYSTEM',
  };

  static ChatNuMessageType messageTypeFromServer(String type) => switch (type) {
    'IMAGE' => ChatNuMessageType.image,
    'VIDEO' => ChatNuMessageType.video,
    'VOICE' => ChatNuMessageType.voice,
    'FILE' => ChatNuMessageType.file,
    'LOCATION' => ChatNuMessageType.location,
    'LIVE_LOCATION' => ChatNuMessageType.liveLocation,
    'VIEW_ONCE_IMAGE' => ChatNuMessageType.viewOnceImage,
    'VIEW_ONCE_VIDEO' => ChatNuMessageType.viewOnceVideo,
    'SYSTEM' => ChatNuMessageType.system,
    _ => ChatNuMessageType.text,
  };

  static DecryptedPayload parsePlaintext(String plain) {
    try {
      final decoded = jsonDecode(plain);
      if (decoded is! Map) return DecryptedPayload(displayText: plain);
      final json = decoded.map((key, value) => MapEntry(key.toString(), value));
      final kind = json['kind']?.toString();
      if (kind == 'attachment') {
        return DecryptedPayload(
          displayText: json['name']?.toString() ?? 'Attachment',
          attachmentId: json['attachmentId']?.toString(),
          fileName: json['name']?.toString() ?? 'Attachment',
          mimeType: json['mime']?.toString() ?? 'application/octet-stream',
          sizeBytes: _int(json['size']),
          fileKey: json['fileKey']?.toString(),
          fileNonce: json['fileNonce']?.toString(),
          durationMs: _int(json['durationMs']),
          videoNote: json['videoNote'] == true,
        );
      }
      if (kind == 'location') {
        final latitude = _double(json['lat']);
        final longitude = _double(json['lng']);
        if (latitude == null || longitude == null) {
          return const DecryptedPayload(displayText: 'Shared location');
        }
        return DecryptedPayload(
          displayText: json['label']?.toString() ?? 'Shared location',
          latitude: latitude,
          longitude: longitude,
        );
      }
      return DecryptedPayload(displayText: plain);
    } on FormatException {
      return DecryptedPayload(displayText: plain);
    }
  }

  static DateTime _date(String value) =>
      DateTime.tryParse(value)?.toLocal() ?? DateTime.now();

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class DecryptedPayload {
  const DecryptedPayload({
    required this.displayText,
    this.attachmentId,
    this.fileName,
    this.mimeType,
    this.sizeBytes,
    this.fileKey,
    this.fileNonce,
    this.latitude,
    this.longitude,
    this.durationMs,
    this.videoNote = false,
  });

  final String displayText;
  final String? attachmentId;
  final String? fileName;
  final String? mimeType;
  final int? sizeBytes;
  final String? fileKey;
  final String? fileNonce;
  final double? latitude;
  final double? longitude;
  final int? durationMs;
  final bool videoNote;
}
