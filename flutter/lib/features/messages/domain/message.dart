enum ChatNuMessageType {
  text,
  image,
  video,
  voice,
  file,
  location,
  liveLocation,
  viewOnceImage,
  viewOnceVideo,
  system,
}

enum MessageDeliveryState {
  queuedOffline,
  sending,
  sentToServer,
  deliveredToRecipientDevice,
  read,
  failed,
}

class ChatNuMessage {
  const ChatNuMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.sentAt,
    this.clientId,
    this.type = ChatNuMessageType.text,
    this.deliveryState = MessageDeliveryState.sentToServer,
    this.attachmentId,
    this.fileName,
    this.mimeType,
    this.sizeBytes,
    this.attachmentKeyBase64,
    this.attachmentNonceBase64,
    this.locationLatitude,
    this.locationLongitude,
    this.mediaDurationMs,
    this.isVideoNote = false,
  });

  final String id;
  final String? clientId;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime sentAt;
  final ChatNuMessageType type;
  final MessageDeliveryState deliveryState;
  final String? attachmentId;
  final String? fileName;
  final String? mimeType;
  final int? sizeBytes;
  final String? attachmentKeyBase64;
  final String? attachmentNonceBase64;
  final double? locationLatitude;
  final double? locationLongitude;
  final int? mediaDurationMs;
  final bool isVideoNote;

  bool get hasAttachment => attachmentId != null;
  bool get hasLocation => locationLatitude != null && locationLongitude != null;
  bool get isPlayableAudio =>
      type == ChatNuMessageType.voice ||
      (mimeType?.toLowerCase().startsWith('audio/') ?? false);

  ChatNuMessage copyWith({
    String? id,
    String? clientId,
    String? body,
    DateTime? sentAt,
    ChatNuMessageType? type,
    MessageDeliveryState? deliveryState,
    String? attachmentId,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    String? attachmentKeyBase64,
    String? attachmentNonceBase64,
    double? locationLatitude,
    double? locationLongitude,
    int? mediaDurationMs,
    bool? isVideoNote,
  }) {
    return ChatNuMessage(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      type: type ?? this.type,
      deliveryState: deliveryState ?? this.deliveryState,
      attachmentId: attachmentId ?? this.attachmentId,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      attachmentKeyBase64: attachmentKeyBase64 ?? this.attachmentKeyBase64,
      attachmentNonceBase64:
          attachmentNonceBase64 ?? this.attachmentNonceBase64,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      mediaDurationMs: mediaDurationMs ?? this.mediaDurationMs,
      isVideoNote: isVideoNote ?? this.isVideoNote,
    );
  }
}
