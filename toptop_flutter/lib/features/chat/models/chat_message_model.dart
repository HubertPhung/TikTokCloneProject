/// Model tin nhắn chat - ánh xạ từ Realtime Database node "Chats/{roomId}/{messageId}"
/// Port từ ChatMessage.java trong Android project
class ChatMessageModel {
  final String senderId;
  final String receiverId;
  final String message;
  final int timestamp;
  final String type; // "text", "image", "video"

  ChatMessageModel({
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.type = 'text',
  });

  factory ChatMessageModel.fromMap(Map<dynamic, dynamic> map) {
    return ChatMessageModel(
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      message: map['message'] as String? ?? '',
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
      type: map['type'] as String? ?? 'text',
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'timestamp': timestamp,
        'type': type,
      };

  ChatMessageModel copyWith({
    String? senderId,
    String? receiverId,
    String? message,
    int? timestamp,
    String? type,
  }) {
    return ChatMessageModel(
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }
}
