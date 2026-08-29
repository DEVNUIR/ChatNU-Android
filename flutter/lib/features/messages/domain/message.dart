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
    this.type = ChatNuMessageType.text,
    this.deliveryState = MessageDeliveryState.sentToServer,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime sentAt;
  final ChatNuMessageType type;
  final MessageDeliveryState deliveryState;
}
