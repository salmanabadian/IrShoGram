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
        createdAt: _requiredDate(map, 'createdAt'),
        updatedAt: _requiredDate(map, 'updatedAt'),
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

DateTime _requiredDate(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Missing or invalid "$key".');
}
