DateTime _messageDate(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Missing or invalid "$key".');
}

class Conversation {
  const Conversation({
    required this.id,
    required this.participantIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool includes(String uid) => participantIds.contains(uid);

  factory Conversation.fromMap(String id, Map<String, Object?> map) {
    final participants = map['participantIds'];
    if (participants is! List || participants.any((value) => value is! String)) {
      throw const FormatException('Invalid conversation participants.');
    }
    return Conversation(
      id: id,
      participantIds: List<String>.unmodifiable(participants.cast<String>()),
      createdAt: _messageDate(map, 'createdAt'),
      updatedAt: _messageDate(map, 'updatedAt'),
    );
  }

  Map<String, Object?> toMap() => {
        'participantIds': participantIds,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class DirectMessage {
  const DirectMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    required this.createdAt,
    this.type = 'text',
  });

  final String id;
  final String senderId;
  final String text;
  final String? mediaUrl;
  final DateTime createdAt;
  final String type;

  factory DirectMessage.fromMap(String id, Map<String, Object?> map) =>
      DirectMessage(
        id: id,
        senderId: map['senderId'] as String,
        text: map['text'] as String,
        mediaUrl: map['mediaUrl'] as String?,
        createdAt: _messageDate(map, 'createdAt'),
        type: map['type'] as String? ?? 'text',
      );

  Map<String, Object?> toMap() => {
        'senderId': senderId,
        'text': text,
        'mediaUrl': mediaUrl,
        'createdAt': createdAt,
        'type': type,
      };
}
