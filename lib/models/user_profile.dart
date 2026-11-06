import '../core/firestore_value_parser.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.username,
    required this.displayName,
    this.bio = '',
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String username;
  final String displayName;
  final String bio;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.fromMap(Map<String, Object?> map) => UserProfile(
        uid: _requiredString(map, 'uid'),
        username: _requiredString(map, 'username'),
        displayName: _requiredString(map, 'displayName'),
        bio: map['bio'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        createdAt: parseDateTimeValue(map['createdAt'], fieldName: 'createdAt'),
        updatedAt: parseDateTimeValue(map['updatedAt'], fieldName: 'updatedAt'),
      );

  Map<String, Object?> toMap() => {
        'uid': uid,
        'username': username,
        'displayName': displayName,
        'bio': bio,
        'photoUrl': photoUrl,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String) throw FormatException('Missing or invalid "$key".');
  return value;
}
