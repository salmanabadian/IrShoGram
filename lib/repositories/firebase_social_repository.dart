import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/messaging.dart';
import '../models/social_content.dart';
import '../models/social_metadata.dart';
import '../models/user_profile.dart';
import 'social_repository.dart';

/// Firestore and Firebase Storage implementation of the app's backend
/// contracts. All operations rely on Firebase Security Rules for authorization.
class FirebaseSocialRepository implements SocialRepository, MediaStorageRepository {
  FirebaseSocialRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _posts => _db.collection('posts');

  @override
  Future<UserProfile?> getUser(String uid) async {
    final snapshot = await _users.doc(uid).get();
    final data = snapshot.data();
    return data == null ? null : UserProfile.fromMap(data);
  }

  @override
  Future<void> createUser(UserProfile profile) async {
    await _users.doc(profile.uid).set(profile.toMap());
  }

  @override
  Future<void> updateUser(UserProfile profile) async {
    await _users.doc(profile.uid).update(profile.toMap());
  }

  @override
  Future<List<UserProfile>> searchUsers(String query, {int limit = 20}) async {
    final normalized = query.trim().replaceFirst(RegExp(r'^@'), '');
    if (normalized.isEmpty) return const [];
    final result = await _users
        .orderBy('username')
        .startAt([normalized])
        .endAt(['$normalized\uf8ff'])
        .limit(limit.clamp(1, 50).toInt())
        .get();
    return result.docs.map((doc) => UserProfile.fromMap(doc.data())).toList();
  }

  @override
  Future<void> followUser(String currentUid, String targetUid) async {
    if (currentUid == targetUid) {
      throw ArgumentError('A user cannot follow their own account.');
    }
    final target = await _users.doc(targetUid).get();
    if (!target.exists) throw StateError('The target user does not exist.');
    await _users.doc(currentUid).collection('following').doc(targetUid).set({
      'createdAt': FieldValue.serverTimestamp(),
      'targetUid': targetUid,
    });
  }

  @override
  Future<void> unfollowUser(String currentUid, String targetUid) async {
    await _users.doc(currentUid).collection('following').doc(targetUid).delete();
  }

  @override
  Future<bool> isFollowing(String currentUid, String targetUid) async {
    final doc = await _users.doc(currentUid).collection('following').doc(targetUid).get();
    return doc.exists;
  }

  @override
  Future<int> followerCount(String uid) async {
    final result = await _db.collectionGroup('following')
        .where('targetUid', isEqualTo: uid)
        .count()
        .get();
    return result.count ?? 0;
  }

  @override
  Future<int> followingCount(String uid) async {
    final result = await _users.doc(uid).collection('following').count().get();
    return result.count ?? 0;
  }

  @override
  Future<String> createPost(SocialPost post) async {
    await _posts.doc(post.id).set(post.toMap());
    return post.id;
  }

  @override
  Future<void> updatePostCaption(String postId, String authorId, String caption) async {
    await _posts.doc(postId).update({
      'caption': caption,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deletePost(String postId, String authorId) async {
    final ref = _posts.doc(postId);
    final snapshot = await ref.get();
    if (snapshot.data()?['authorId'] != authorId) {
      throw StateError('Only the post owner can delete this post.');
    }
    await ref.delete();
  }

  @override
  Future<List<SocialPost>> getUserPosts(String uid, {int limit = 20}) async {
    final result = await _posts.where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit.clamp(1, 100).toInt())
        .get();
    return result.docs.map((doc) => SocialPost.fromMap(doc.id, doc.data())).toList();
  }

  @override
  Future<void> likePost(String postId, String uid) async {
    await _posts.doc(postId).collection('likes').doc(uid).set({
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unlikePost(String postId, String uid) async {
    await _posts.doc(postId).collection('likes').doc(uid).delete();
  }

  @override
  Future<bool> isPostLiked(String postId, String uid) async {
    final doc = await _posts.doc(postId).collection('likes').doc(uid).get();
    return doc.exists;
  }

  @override
  Future<void> savePost(String postId, String uid) async {
    await _users.doc(uid).collection('savedPosts').doc(postId).set({
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unsavePost(String postId, String uid) async {
    await _users.doc(uid).collection('savedPosts').doc(postId).delete();
  }

  @override
  Future<List<String>> getSavedPostIds(String uid) async {
    final result = await _users.doc(uid).collection('savedPosts').get();
    return result.docs.map((doc) => doc.id).toList();
  }

  @override
  Future<String> addComment({
    required String postId,
    required String authorId,
    required String text,
  }) async {
    final ref = _posts.doc(postId).collection('comments').doc();
    await ref.set({
      'authorId': authorId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  @override
  Future<void> editComment({
    required String postId,
    required String commentId,
    required String authorId,
    required String text,
  }) async {
    final ref = _posts.doc(postId).collection('comments').doc(commentId);
    final snapshot = await ref.get();
    if (snapshot.data()?['authorId'] != authorId) {
      throw StateError('Only the comment owner can edit this comment.');
    }
    await ref.update({'text': text});
  }

  @override
  Future<void> deleteComment({
    required String postId,
    required String commentId,
    required String authorId,
  }) async {
    final ref = _posts.doc(postId).collection('comments').doc(commentId);
    final snapshot = await ref.get();
    if (snapshot.data()?['authorId'] != authorId) {
      throw StateError('Only the comment owner can delete this comment.');
    }
    await ref.delete();
  }

  @override
  Future<List<PostComment>> getComments(String postId, {int limit = 50}) async {
    final result = await _posts.doc(postId).collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(limit.clamp(1, 100).toInt())
        .get();
    return result.docs.map((doc) => PostComment.fromMap(doc.id, doc.data())).toList();
  }

  @override
  Future<List<AppNotification>> getNotifications(String uid, {int limit = 50}) async {
    final result = await _users.doc(uid).collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit.clamp(1, 100).toInt())
        .get();
    return result.docs.map((doc) => AppNotification.fromMap(doc.id, doc.data())).toList();
  }

  @override
  Future<void> markNotificationRead(String uid, String notificationId) async {
    await _users.doc(uid).collection('notifications').doc(notificationId).update({'read': true});
  }

  @override
  Future<String> createStory(Story story) async {
    await _db.collection('stories').doc(story.id).set(story.toMap());
    return story.id;
  }

  @override
  Future<List<Story>> getActiveStories({int limit = 50}) async {
    final result = await _db.collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .limit(limit.clamp(1, 100).toInt())
        .get();
    return result.docs.map((doc) => Story.fromMap(doc.id, doc.data())).toList();
  }

  @override
  Future<void> deleteStory(String storyId, String authorId) async {
    final ref = _db.collection('stories').doc(storyId);
    final snapshot = await ref.get();
    if (snapshot.data()?['authorId'] != authorId) {
      throw StateError('Only the story owner can delete this story.');
    }
    await ref.delete();
  }

  @override
  Future<String> createReel(Reel reel) async {
    await _db.collection('reels').doc(reel.id).set(reel.toMap());
    return reel.id;
  }

  @override
  Future<List<Reel>> getReels({int limit = 20}) async {
    final result = await _db.collection('reels')
        .orderBy('createdAt', descending: true)
        .limit(limit.clamp(1, 50).toInt())
        .get();
    return result.docs.map((doc) => Reel.fromMap(doc.id, doc.data())).toList();
  }

  String _conversationId(String firstUid, String secondUid) {
    final ids = [firstUid, secondUid]..sort();
    if (ids[0] == ids[1]) throw ArgumentError('A conversation requires two different users.');
    return ids.join('_');
  }

  @override
  Future<String> getOrCreateConversation(String currentUid, String otherUid) async {
    final id = _conversationId(currentUid, otherUid);
    final ref = _db.collection('conversations').doc(id);
    final existing = await ref.get();
    if (!existing.exists) {
      final now = FieldValue.serverTimestamp();
      await ref.set({
        'participantIds': ([currentUid, otherUid]..sort()),
        'createdAt': now,
        'updatedAt': now,
      });
    }
    return id;
  }

  @override
  Future<List<Conversation>> getConversations(String uid) async {
    final result = await _db.collection('conversations')
        .where('participantIds', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .get();
    return result.docs.map((doc) => Conversation.fromMap(doc.id, doc.data())).toList();
  }

  @override
  Future<String> sendMessage(String conversationId, DirectMessage message) async {
    final conversation = _db.collection('conversations').doc(conversationId);
    final ref = conversation.collection('messages').doc(message.id);
    await _db.runTransaction((transaction) async {
      transaction.set(ref, {
        ...message.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(conversation, {'updatedAt': FieldValue.serverTimestamp()});
    });
    return ref.id;
  }

  @override
  Stream<List<DirectMessage>> watchMessages(String conversationId, {int limit = 50}) {
    return _db.collection('conversations').doc(conversationId).collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit.clamp(1, 100).toInt())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DirectMessage.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<String> uploadImage({
    required String ownerUid,
    required String storagePath,
    required List<int> bytes,
  }) => _upload(ownerUid, storagePath, bytes, isVideo: false);

  @override
  Future<String> uploadVideo({
    required String ownerUid,
    required String storagePath,
    required List<int> bytes,
  }) => _upload(ownerUid, storagePath, bytes, isVideo: true);

  Future<String> _upload(String ownerUid, String storagePath, List<int> bytes, {required bool isVideo}) async {
    final segments = storagePath.split('/');
    if (segments.length < 3 || segments[1] != ownerUid) {
      throw ArgumentError('Storage paths must be scoped to the authenticated owner.');
    }
    final extension = storagePath.split('.').last.toLowerCase();
    final contentType = isVideo
        ? (extension == 'mov' ? 'video/quicktime' : 'video/mp4')
        : (extension == 'png' ? 'image/png' : extension == 'webp' ? 'image/webp' : 'image/jpeg');
    final reference = _storage.ref().child(storagePath);
    await reference.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: contentType),
    );
    return reference.getDownloadURL();
  }

  @override
  Future<void> deleteMedia(String storagePath) async {
    await _storage.ref().child(storagePath).delete();
  }
}
