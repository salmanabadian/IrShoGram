import 'package:cloud_firestore/cloud_firestore.dart';

final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9._]{3,30}$');

String _usernameClaimId(String username) => username.toLowerCase();

void _validateUsername(String username) {
  if (!_usernamePattern.hasMatch(username)) {
    throw ArgumentError.value(username, 'username', 'Invalid username.');
  }
}

/// Ensures the signed-in user's profile has an exclusive username reservation.
///
/// Existing profiles keep their current username; this also backfills the
/// reservation for profiles created before username claims were introduced.
Future<void> ensureUserProfileWithUsernameClaim({
  required FirebaseFirestore firestore,
  required String uid,
  required Map<String, Object?> initialProfile,
}) async {
  final userRef = firestore.collection('users').doc(uid);

  await firestore.runTransaction((transaction) async {
    final userSnapshot = await transaction.get(userRef);
    final currentUsername = userSnapshot.data()?['username'];
    final username = currentUsername is String
        ? currentUsername
        : initialProfile['username'];

    if (username is! String) {
      throw StateError('PROFILE_USERNAME_MISSING');
    }
    _validateUsername(username);

    final claimRef = firestore
        .collection('usernames')
        .doc(_usernameClaimId(username));
    final claimSnapshot = await transaction.get(claimRef);
    if (claimSnapshot.exists && claimSnapshot.data()?['uid'] != uid) {
      throw StateError('USERNAME_TAKEN');
    }

    if (!userSnapshot.exists) {
      transaction.set(userRef, <String, Object?>{
        ...initialProfile,
        'uid': uid,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    if (!claimSnapshot.exists) {
      transaction.set(claimRef, <String, Object?>{'uid': uid});
    }
  });
}

/// Updates profile fields and moves the username reservation atomically.
Future<void> updateUserProfileWithUsernameClaim({
  required FirebaseFirestore firestore,
  required String uid,
  required Map<String, Object?> changes,
}) async {
  final userRef = firestore.collection('users').doc(uid);

  await firestore.runTransaction((transaction) async {
    final userSnapshot = await transaction.get(userRef);
    final currentData = userSnapshot.data();
    if (!userSnapshot.exists || currentData == null) {
      throw StateError('PROFILE_NOT_FOUND');
    }

    final currentUsername = currentData['username'];
    if (currentUsername is! String) {
      throw StateError('PROFILE_USERNAME_MISSING');
    }
    final requestedUsername = changes['username'] ?? currentUsername;
    if (requestedUsername is! String) {
      throw ArgumentError.value(requestedUsername, 'username');
    }
    _validateUsername(requestedUsername);

    final newClaimRef = firestore
        .collection('usernames')
        .doc(_usernameClaimId(requestedUsername));
    final oldClaimRef = firestore
        .collection('usernames')
        .doc(_usernameClaimId(currentUsername));
    final newClaimSnapshot = await transaction.get(newClaimRef);
    final oldClaimSnapshot = oldClaimRef.path == newClaimRef.path
        ? newClaimSnapshot
        : await transaction.get(oldClaimRef);

    if (newClaimSnapshot.exists && newClaimSnapshot.data()?['uid'] != uid) {
      throw StateError('USERNAME_TAKEN');
    }

    transaction.update(userRef, <String, Object?>{
      ...changes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!newClaimSnapshot.exists) {
      transaction.set(newClaimRef, <String, Object?>{'uid': uid});
    }
    if (oldClaimRef.path != newClaimRef.path &&
        oldClaimSnapshot.exists &&
        oldClaimSnapshot.data()?['uid'] == uid) {
      transaction.delete(oldClaimRef);
    }
  });
}
