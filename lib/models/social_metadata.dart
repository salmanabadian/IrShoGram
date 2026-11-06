import '../core/firestore_value_parser.dart';

/// A user-authored comment stored under posts/{postId}/comments/{commentId}.
class PostComment {
  const PostComment({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory PostComment.fromMap(String id, Map<String, Object?> map) {
    final authorId = map['authorId'];
    final text = map['text'];
    if (authorId is! String || authorId.isEmpty || text is! String) {
      throw const FormatException('Invalid comment author or text.');
    }
    return PostComment(
      id: id,
      authorId: authorId,
      text: text,
      createdAt: parseDateTimeValue(map['createdAt'], fieldName: 'createdAt'),
      updatedAt: map['updatedAt'] == null
          ? null
          : parseDateTimeValue(map['updatedAt'], fieldName: 'updatedAt'),
    );
  }

  Map<String, Object?> toMap() => {
        'authorId': authorId,
        'text': text,
        'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}

enum NotificationType {
  like,
  comment,
  follow,
  mention,
  system;

  static NotificationType parse(Object? value) {
    return NotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw FormatException('Unsupported notification type: $value'),
    );
  }
}

/// Notification documents are created by trusted backend code.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.actorId,
    required this.recipientId,
    required this.createdAt,
    this.postId,
    this.read = false,
  });

  final String id;
  final NotificationType type;
  final String actorId;
  final String recipientId;
  final DateTime createdAt;
  final String? postId;
  final bool read;

  factory AppNotification.fromMap(String id, Map<String, Object?> map) {
    final actorId = map['actorId'];
    final recipientId = map['recipientId'];
    final read = map['read'] ?? false;
    if (actorId is! String ||
        actorId.isEmpty ||
        recipientId is! String ||
        recipientId.isEmpty ||
        read is! bool) {
      throw const FormatException('Invalid notification fields.');
    }
    final postId = map['postId'];
    if (postId != null && postId is! String) {
      throw const FormatException('Invalid notification post ID.');
    }
    return AppNotification(
      id: id,
      type: NotificationType.parse(map['type']),
      actorId: actorId,
      recipientId: recipientId,
      createdAt: parseDateTimeValue(map['createdAt'], fieldName: 'createdAt'),
      postId: postId as String?,
      read: read,
    );
  }

  Map<String, Object?> toMap() => {
        'type': type.name,
        'actorId': actorId,
        'recipientId': recipientId,
        'createdAt': createdAt,
        'postId': postId,
        'read': read,
      };
}
