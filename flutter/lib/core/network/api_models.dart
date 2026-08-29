class UserDto {
  const UserDto({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.lastSeenAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final String? lastSeenAt;

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    id: _string(json, 'id'),
    username: _string(json, 'username'),
    displayName: _string(json, 'displayName'),
    avatarUrl: _nullableString(json['avatarUrl']),
    bio: _nullableString(json['bio']),
    lastSeenAt: _nullableString(json['lastSeenAt']),
  );
}

class AuthResponse {
  const AuthResponse({
    required this.user,
    required this.deviceId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.recoveryCode,
  });

  final UserDto user;
  final String deviceId;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String? recoveryCode;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    user: UserDto.fromJson(_map(json['user'])),
    deviceId: _string(json, 'deviceId'),
    accessToken: _string(json, 'accessToken'),
    refreshToken: _string(json, 'refreshToken'),
    expiresIn: _integer(json['expiresIn']),
    recoveryCode: _nullableString(json['recoveryCode']),
  );
}

class RefreshResponse {
  const RefreshResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  factory RefreshResponse.fromJson(Map<String, dynamic> json) =>
      RefreshResponse(
        accessToken: _string(json, 'accessToken'),
        refreshToken: _string(json, 'refreshToken'),
        expiresIn: _integer(json['expiresIn']),
      );
}

class SessionResponse {
  const SessionResponse({
    required this.deviceId,
    required this.userId,
    required this.deviceName,
    required this.hasIdentityKey,
    required this.pushConfigured,
  });

  final String deviceId;
  final String userId;
  final String deviceName;
  final bool hasIdentityKey;
  final bool pushConfigured;

  factory SessionResponse.fromJson(Map<String, dynamic> json) =>
      SessionResponse(
        deviceId: _string(json, 'deviceId'),
        userId: _string(json, 'userId'),
        deviceName: _string(json, 'deviceName'),
        hasIdentityKey: json['hasIdentityKey'] == true,
        pushConfigured: json['pushConfigured'] == true,
      );
}

class ConversationDto {
  const ConversationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.members,
    required this.isPinned,
    required this.isMuted,
    required this.unreadCount,
    this.avatarUrl,
    this.updatedAt,
    this.lastMessage,
  });

  final String id;
  final String type;
  final String title;
  final String? avatarUrl;
  final List<UserDto> members;
  final bool isPinned;
  final bool isMuted;
  final int unreadCount;
  final String? updatedAt;
  final MessageDto? lastMessage;

  factory ConversationDto.fromJson(Map<String, dynamic> json) =>
      ConversationDto(
        id: _string(json, 'id'),
        type: _string(json, 'type'),
        title: _string(json, 'title'),
        avatarUrl: _nullableString(json['avatarUrl']),
        members: _list(
          json['members'],
        ).map((item) => UserDto.fromJson(_map(item))).toList(growable: false),
        isPinned: json['isPinned'] == true,
        isMuted: json['isMuted'] == true,
        unreadCount: _integer(json['unreadCount']),
        updatedAt: _nullableString(json['updatedAt']),
        lastMessage: json['lastMessage'] is Map
            ? MessageDto.fromJson(_map(json['lastMessage']))
            : null,
      );
}

class DeviceKeyDto {
  const DeviceKeyDto({
    required this.deviceId,
    required this.userId,
    required this.publicKey,
  });

  final String deviceId;
  final String userId;
  final String publicKey;

  factory DeviceKeyDto.fromJson(Map<String, dynamic> json) => DeviceKeyDto(
    deviceId: _string(json, 'deviceId'),
    userId: _string(json, 'userId'),
    publicKey: _string(json, 'publicKey'),
  );
}

class ConversationKeysResponse {
  const ConversationKeysResponse({
    required this.devices,
    required this.missingUserIds,
  });

  final List<DeviceKeyDto> devices;
  final List<String> missingUserIds;

  factory ConversationKeysResponse.fromJson(Map<String, dynamic> json) =>
      ConversationKeysResponse(
        devices: _list(json['devices'])
            .map((item) => DeviceKeyDto.fromJson(_map(item)))
            .toList(growable: false),
        missingUserIds: _list(
          json['missingUserIds'],
        ).map((item) => item.toString()).toList(growable: false),
      );
}

class MessageDto {
  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.ciphertext,
    required this.createdAt,
    this.clientId,
    this.senderUsername,
    this.nonce,
    this.protocolVersion,
    this.metadata,
  });

  final String id;
  final String? clientId;
  final String conversationId;
  final String senderId;
  final String? senderUsername;
  final String senderName;
  final String type;
  final String ciphertext;
  final String? nonce;
  final String? protocolVersion;
  final Map<String, dynamic>? metadata;
  final String createdAt;

  factory MessageDto.fromJson(Map<String, dynamic> json) => MessageDto(
    id: _string(json, 'id'),
    clientId: _nullableString(json['clientId']),
    conversationId: _string(json, 'conversationId'),
    senderId: _string(json, 'senderId'),
    senderUsername: _nullableString(json['senderUsername']),
    senderName: _nullableString(json['senderName']) ?? 'Unknown',
    type: _nullableString(json['type']) ?? 'TEXT',
    ciphertext: _string(json, 'ciphertext'),
    nonce: _nullableString(json['nonce']),
    protocolVersion: _nullableString(json['protocolVersion']),
    metadata: json['metadata'] is Map ? _map(json['metadata']) : null,
    createdAt: _nullableString(json['createdAt']) ?? '',
  );
}

class AttachmentDto {
  const AttachmentDto({
    required this.id,
    required this.contentType,
    required this.sizeBytes,
    this.fileName,
  });

  final String id;
  final String? fileName;
  final String contentType;
  final int sizeBytes;

  factory AttachmentDto.fromJson(Map<String, dynamic> json) => AttachmentDto(
    id: _string(json, 'id'),
    fileName: _nullableString(json['fileName']),
    contentType: _string(json, 'contentType'),
    sizeBytes: _integer(json['sizeBytes']),
  );
}

class IceServerDto {
  const IceServerDto({required this.urls, this.username, this.credential});

  final List<String> urls;
  final String? username;
  final String? credential;

  factory IceServerDto.fromJson(Map<String, dynamic> json) => IceServerDto(
    urls: _list(json['urls']).map((item) => item.toString()).toList(),
    username: _nullableString(json['username']),
    credential: _nullableString(json['credential']),
  );
}

class RtcConfigResponse {
  const RtcConfigResponse({required this.iceServers, this.realm});

  final List<IceServerDto> iceServers;
  final String? realm;

  factory RtcConfigResponse.fromJson(Map<String, dynamic> json) =>
      RtcConfigResponse(
        iceServers: _list(json['iceServers'])
            .map((item) => IceServerDto.fromJson(_map(item)))
            .toList(growable: false),
        realm: _nullableString(json['realm']),
      );
}

class PendingCallDto {
  const PendingCallDto({
    required this.type,
    required this.callId,
    required this.conversationId,
    required this.targetUserId,
    required this.fromUserId,
    required this.video,
    this.fromDeviceId,
    this.sdp,
    this.sentAt,
  });

  final String type;
  final String callId;
  final String conversationId;
  final String targetUserId;
  final String fromUserId;
  final String? fromDeviceId;
  final String? sdp;
  final bool video;
  final String? sentAt;

  factory PendingCallDto.fromJson(Map<String, dynamic> json) => PendingCallDto(
    type: _string(json, 'type'),
    callId: _string(json, 'callId'),
    conversationId: _string(json, 'conversationId'),
    targetUserId: _string(json, 'targetUserId'),
    fromUserId: _string(json, 'fromUserId'),
    fromDeviceId: _nullableString(json['fromDeviceId']),
    sdp: _nullableString(json['sdp']),
    video: json['video'] == true,
    sentAt: _nullableString(json['sentAt']),
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) throw const FormatException('Expected a JSON object.');
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<dynamic> _list(Object? value) => value is List ? value : const <dynamic>[];

String _string(Map<String, dynamic> json, String key) {
  final value = _nullableString(json[key]);
  if (value == null) throw FormatException('Missing $key.');
  return value;
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty || text == 'null' ? null : text;
}

int _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
