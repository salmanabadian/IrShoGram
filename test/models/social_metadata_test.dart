import 'package:flutter_test/flutter_test.dart';
import 'package:irshogram/models/social_metadata.dart';

void main() {
  final now = DateTime.utc(2026, 11, 6);

  test('PostComment round-trips the Firestore comment fields', () {
    final comment = PostComment(
      id: 'comment-1',
      authorId: 'user-1',
      text: 'A useful comment',
      createdAt: now,
    );

    final restored = PostComment.fromMap(comment.id, comment.toMap());
    expect(restored.authorId, 'user-1');
    expect(restored.text, 'A useful comment');
    expect(restored.createdAt, now);
  });

  test('AppNotification round-trips read state and optional post ID', () {
    final notification = AppNotification(
      id: 'notification-1',
      type: NotificationType.comment,
      actorId: 'user-2',
      recipientId: 'user-1',
      postId: 'post-1',
      createdAt: now,
      read: true,
    );

    final restored = AppNotification.fromMap(
      notification.id,
      notification.toMap(),
    );
    expect(restored.type, NotificationType.comment);
    expect(restored.actorId, 'user-2');
    expect(restored.recipientId, 'user-1');
    expect(restored.postId, 'post-1');
    expect(restored.read, isTrue);
  });

  test('AppNotification rejects unknown notification types', () {
    expect(
      () => AppNotification.fromMap('notification-1', {
        'type': 'unknown',
        'actorId': 'user-2',
        'recipientId': 'user-1',
        'createdAt': now,
        'read': false,
      }),
      throwsFormatException,
    );
  });
}
