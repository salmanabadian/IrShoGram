import '../core/input_validator.dart';
import '../models/messaging.dart';
import '../models/social_content.dart';
import '../repositories/social_repository.dart';

/// Validates user actions before they reach the backend adapter.
///
/// This layer contains no demo data and does not pretend to persist anything:
/// persistence is performed only by the injected repository implementation.
class SocialActions {
  const SocialActions(this._repository);

  final SocialRepository _repository;

  Future<void> follow({
    required String currentUid,
    required String targetUid,
  }) async {
    if (currentUid.isEmpty || targetUid.isEmpty) {
      throw ArgumentError('User IDs must not be empty.');
    }
    if (currentUid == targetUid) {
      throw ArgumentError('A user cannot follow their own account.');
    }
    if (!await _repository.isFollowing(currentUid, targetUid)) {
      await _repository.followUser(currentUid, targetUid);
    }
  }

  Future<void> unfollow({
    required String currentUid,
    required String targetUid,
  }) async {
    if (currentUid.isEmpty || targetUid.isEmpty) {
      throw ArgumentError('User IDs must not be empty.');
    }
    if (currentUid == targetUid) {
      throw ArgumentError('A user cannot unfollow their own account.');
    }
    if (await _repository.isFollowing(currentUid, targetUid)) {
      await _repository.unfollowUser(currentUid, targetUid);
    }
  }

  Future<String> comment({
    required String postId,
    required String currentUid,
    required String text,
  }) {
    final error = InputValidator.comment(text);
    if (error != null) throw ArgumentError.value(text, 'text', error);
    if (postId.isEmpty || currentUid.isEmpty) {
      throw ArgumentError('Post and user IDs must not be empty.');
    }
    return _repository.addComment(
      postId: postId,
      authorId: currentUid,
      text: text.trim(),
    );
  }

  Future<void> editComment({
    required String postId,
    required String commentId,
    required String currentUid,
    required String text,
  }) {
    final error = InputValidator.comment(text);
    if (error != null) throw ArgumentError.value(text, 'text', error);
    return _repository.editComment(
      postId: postId,
      commentId: commentId,
      authorId: currentUid,
      text: text.trim(),
    );
  }

  Future<String> sendTextMessage({
    required String conversationId,
    required String currentUid,
    required String text,
  }) {
    final error = InputValidator.message(text);
    if (error != null) throw ArgumentError.value(text, 'text', error);
    if (conversationId.isEmpty || currentUid.isEmpty) {
      throw ArgumentError('Conversation and user IDs must not be empty.');
    }
    return _repository.sendMessage(
      conversationId,
      DirectMessage(
        id: '',
        senderId: currentUid,
        text: text.trim(),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<String> createPost(SocialPost post) {
    final captionError = InputValidator.caption(post.caption);
    if (captionError != null) {
      throw ArgumentError.value(post.caption, 'caption', captionError);
    }
    if (post.authorId.isEmpty || post.mediaUrl.trim().isEmpty) {
      throw ArgumentError('A post requires an author and uploaded media URL.');
    }
    return _repository.createPost(post);
  }

  Future<String> createStory(Story story) {
    if (story.authorId.isEmpty || story.mediaUrl.trim().isEmpty) {
      throw ArgumentError('A story requires an author and uploaded media URL.');
    }
    if (!story.expiresAt.isAfter(story.createdAt)) {
      throw ArgumentError('Story expiry must be later than its creation time.');
    }
    return _repository.createStory(story);
  }

  Future<String> createReel(Reel reel) {
    final captionError = InputValidator.caption(reel.caption);
    if (captionError != null) {
      throw ArgumentError.value(reel.caption, 'caption', captionError);
    }
    if (reel.authorId.isEmpty || reel.mediaUrl.trim().isEmpty) {
      throw ArgumentError('A reel requires an author and uploaded video URL.');
    }
    return _repository.createReel(reel);
  }

  void validateConversation({
    required List<String> participantIds,
    required String currentUid,
  }) {
    final error = InputValidator.validateConversationParticipants(
      participantIds,
      currentUid,
    );
    if (error != null) {
      throw ArgumentError.value(participantIds, 'participantIds', error);
    }
  }
}
