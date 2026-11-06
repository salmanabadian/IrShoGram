import '../models/messaging.dart';
import '../models/social_content.dart';
import '../models/social_metadata.dart';
import '../models/user_profile.dart';

/// Contract for the real backend implementation.
///
/// Implementations must propagate authentication, permission, and network
/// errors. UI code must not silently fall back to local demo data.
abstract class SocialRepository {
  Future<UserProfile?> getUser(String uid);
  Future<void> createUser(UserProfile profile);
  Future<void> updateUser(UserProfile profile);
  Future<List<UserProfile>> searchUsers(String query, {int limit = 20});

  Future<void> followUser(String currentUid, String targetUid);
  Future<void> unfollowUser(String currentUid, String targetUid);
  Future<bool> isFollowing(String currentUid, String targetUid);
  Future<int> followerCount(String uid);
  Future<int> followingCount(String uid);

  Future<String> createPost(SocialPost post);
  Future<void> updatePostCaption(String postId, String authorId, String caption);
  Future<void> deletePost(String postId, String authorId);
  Future<List<SocialPost>> getUserPosts(String uid, {int limit = 20});

  Future<void> likePost(String postId, String uid);
  Future<void> unlikePost(String postId, String uid);
  Future<bool> isPostLiked(String postId, String uid);
  Future<void> savePost(String postId, String uid);
  Future<void> unsavePost(String postId, String uid);
  Future<List<String>> getSavedPostIds(String uid);

  Future<String> addComment({
    required String postId,
    required String authorId,
    required String text,
  });
  Future<void> editComment({
    required String postId,
    required String commentId,
    required String authorId,
    required String text,
  });
  Future<void> deleteComment({
    required String postId,
    required String commentId,
    required String authorId,
  });
  Future<List<PostComment>> getComments(String postId, {int limit = 50});

  Future<List<AppNotification>> getNotifications(String uid, {int limit = 50});
  Future<void> markNotificationRead(String uid, String notificationId);

  Future<String> createStory(Story story);
  Future<List<Story>> getActiveStories({int limit = 50});
  Future<void> deleteStory(String storyId, String authorId);

  Future<String> createReel(Reel reel);
  Future<List<Reel>> getReels({int limit = 20});

  Future<String> getOrCreateConversation(String currentUid, String otherUid);
  Future<List<Conversation>> getConversations(String uid);
  Future<String> sendMessage(String conversationId, DirectMessage message);
  Stream<List<DirectMessage>> watchMessages(String conversationId, {int limit = 50});
}

/// Storage adapter contract. The Firebase implementation will validate the
/// authenticated owner and return a download URL after a successful upload.
abstract class MediaStorageRepository {
  Future<String> uploadImage({
    required String ownerUid,
    required String storagePath,
    required List<int> bytes,
  });

  Future<String> uploadVideo({
    required String ownerUid,
    required String storagePath,
    required List<int> bytes,
  });

  Future<void> deleteMedia(String storagePath);
}
