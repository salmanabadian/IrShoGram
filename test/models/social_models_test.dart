import 'package:irshogram/core/firestore_value_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irshogram/models/messaging.dart';
import 'package:irshogram/models/social_content.dart';
import 'package:irshogram/models/user_profile.dart';

void main() {
  final now = DateTime.utc(2026, 11, 6);

  test('UserProfile serializes the Firestore user document fields', () {
    final profile = UserProfile(
      uid: 'user-1',
      username: 'irsho',
      displayName: 'IrSho',
      createdAt: now,
      updatedAt: now,
    );

    final restored = UserProfile.fromMap(profile.toMap());
    expect(restored.uid, 'user-1');
    expect(restored.username, 'irsho');
    expect(restored.createdAt, now);
  });

  test('SocialPost serializes supported media types', () {
    final post = SocialPost(
      id: 'post-1',
      authorId: 'user-1',
      caption: 'caption',
      mediaUrl: 'https://example.test/photo.jpg',
      mediaType: MediaType.image,
      createdAt: now,
      updatedAt: now,
    );

    final restored = SocialPost.fromMap(post.id, post.toMap());
    expect(restored.mediaType, MediaType.image);
    expect(restored.authorId, 'user-1');
  });

  test('Story expiry is evaluated against the supplied clock', () {
    final story = Story(
      id: 'story-1',
      authorId: 'user-1',
      mediaUrl: 'https://example.test/story.jpg',
      mediaType: MediaType.image,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );

    expect(story.isExpiredAt(now), isFalse);
    expect(story.isExpiredAt(now.add(const Duration(hours: 25))), isTrue);
  });

  test('Conversation requires a list of participant IDs', () {
    final conversation = Conversation.fromMap('chat-1', {
      'participantIds': ['user-1', 'user-2'],
      'createdAt': now,
      'updatedAt': now,
    });
    expect(conversation.includes('user-2'), isTrue);
    expect(conversation.participantIds, hasLength(2));
  });

  test('DirectMessage preserves optional media URL', () {
    final message = DirectMessage(
      id: 'message-1',
      senderId: 'user-1',
      text: 'hello',
      mediaUrl: 'https://example.test/image.jpg',
      createdAt: now,
    );

    final restored = DirectMessage.fromMap(message.id, message.toMap());
    expect(restored.mediaUrl, message.mediaUrl);
    expect(restored.text, 'hello');
  });
  test('date parser accepts Firebase Timestamp-like values', () {
    final timestamp = _FakeFirestoreTimestamp(now);
    expect(
      parseDateTimeValue(timestamp, fieldName: 'createdAt'),
      now,
    );
  });

}

class _FakeFirestoreTimestamp {
  const _FakeFirestoreTimestamp(this.value);

  final DateTime value;

  DateTime toDate() => value;
}
