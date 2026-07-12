class ChatParticipant {
  final String userId;
  final String? fullName;
  final String? profileImageUrl;

  const ChatParticipant({required this.userId, this.fullName, this.profileImageUrl});

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return ChatParticipant(
      userId: json['userId'] as String,
      fullName: user?['fullName'] as String?,
      profileImageUrl: user?['profileImageUrl'] as String?,
    );
  }
}

class ChatRoom {
  final String id;
  final DateTime createdAt;
  final List<ChatParticipant> participants;

  const ChatRoom({required this.id, required this.createdAt, this.participants = const []});

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      participants: (json['participants'] as List?)
              ?.map((p) => ChatParticipant.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// The other side of the conversation, relative to [currentUserId].
  ChatParticipant? otherParticipant(String currentUserId) {
    for (final p in participants) {
      if (p.userId != currentUserId) return p;
    }
    return null;
  }
}

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
