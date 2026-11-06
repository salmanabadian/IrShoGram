// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalPost {
  const LocalPost({
    required this.id,
    required this.username,
    required this.caption,
    required this.mediaPath,
    required this.isVideo,
    required this.createdAt,
    this.likes = const [],
    this.comments = const [],
    this.savedByMe = false,
  });

  final String id;
  final String username;
  final String caption;
  final String mediaPath;
  final bool isVideo;
  final DateTime createdAt;
  final List<String> likes;
  final List<String> comments;
  final bool savedByMe;

  LocalPost copyWith({
    String? caption,
    List<String>? likes,
    List<String>? comments,
    bool? savedByMe,
  }) => LocalPost(
    id: id,
    username: username,
    caption: caption ?? this.caption,
    mediaPath: mediaPath,
    isVideo: isVideo,
    createdAt: createdAt,
    likes: likes ?? this.likes,
    comments: comments ?? this.comments,
    savedByMe: savedByMe ?? this.savedByMe,
  );

  Map<String, Object?> toJson() => {
    'id': id, 'username': username, 'caption': caption,
    'mediaPath': mediaPath, 'isVideo': isVideo,
    'createdAt': createdAt.toIso8601String(),
    'likes': likes, 'comments': comments, 'savedByMe': savedByMe,
  };

  factory LocalPost.fromJson(Map<String, dynamic> json) => LocalPost(
    id: json['id'] as String,
    username: json['username'] as String,
    caption: json['caption'] as String? ?? '',
    mediaPath: json['mediaPath'] as String,
    isVideo: json['isVideo'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    likes: List<String>.from(json['likes'] as List? ?? const []),
    comments: List<String>.from(json['comments'] as List? ?? const []),
    savedByMe: json['savedByMe'] as bool? ?? false,
  );
}

class LocalStory {
  const LocalStory({
    required this.id,
    required this.username,
    required this.mediaPath,
    required this.isVideo,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String mediaPath;
  final bool isVideo;
  final DateTime createdAt;

  bool get expired => DateTime.now().difference(createdAt).inHours >= 24;

  Map<String, Object?> toJson() => {
    'id': id, 'username': username, 'mediaPath': mediaPath,
    'isVideo': isVideo, 'createdAt': createdAt.toIso8601String(),
  };

  factory LocalStory.fromJson(Map<String, dynamic> json) => LocalStory(
    id: json['id'] as String,
    username: json['username'] as String,
    mediaPath: json['mediaPath'] as String,
    isVideo: json['isVideo'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class LocalMessage {
  const LocalMessage({
    required this.id,
    required this.peer,
    required this.text,
    required this.sentAt,
    this.mine = true,
  });

  final String id;
  final String peer;
  final String text;
  final DateTime sentAt;
  final bool mine;

  Map<String, Object?> toJson() => {
    'id': id, 'peer': peer, 'text': text,
    'sentAt': sentAt.toIso8601String(), 'mine': mine,
  };

  factory LocalMessage.fromJson(Map<String, dynamic> json) => LocalMessage(
    id: json['id'] as String,
    peer: json['peer'] as String,
    text: json['text'] as String,
    sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ?? DateTime.now(),
    mine: json['mine'] as bool? ?? true,
  );
}

/// Device-local persistence used until a real authenticated backend is configured.
/// This deliberately does not claim cross-device or multi-user synchronization.
class LocalSocialStore {
  LocalSocialStore._();
  static final LocalSocialStore instance = LocalSocialStore._();
  static const _uuid = Uuid();

  static const _postsKey = 'irshogram.local.posts.v1';
  static const _storiesKey = 'irshogram.local.stories.v1';
  static const _messagesKey = 'irshogram.local.messages.v1';
  static const _profileKey = 'irshogram.local.profile.v1';
  static const _followingKey = 'irshogram.local.following.v1';

  Future<List<LocalPost>> loadPosts() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_postsKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => LocalPost.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> savePosts(List<LocalPost> posts) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_postsKey, jsonEncode(posts.map((e) => e.toJson()).toList()));
  }

  Future<List<LocalStory>> loadStories() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_storiesKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => LocalStory.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((e) => !e.expired)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveStories(List<LocalStory> stories) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_storiesKey, jsonEncode(stories.where((e) => !e.expired).map((e) => e.toJson()).toList()));
  }

  Future<List<LocalMessage>> loadMessages() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_messagesKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => LocalMessage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMessages(List<LocalMessage> messages) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_messagesKey, jsonEncode(messages.map((e) => e.toJson()).toList()));
  }

  Future<Map<String, String>> loadProfile() async {
    final p = await SharedPreferences.getInstance();
    return {
      'username': p.getString('${_profileKey}.username') ?? 'irshogram_user',
      'name': p.getString('${_profileKey}.name') ?? 'کاربر ایرشوگرام',
      'bio': p.getString('${_profileKey}.bio') ?? 'به صفحه من خوش آمدید.',
      'avatar': p.getString('${_profileKey}.avatar') ?? '',
    };
  }

  Future<void> saveProfile(Map<String, String> profile) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('${_profileKey}.username', profile['username'] ?? 'irshogram_user');
    await p.setString('${_profileKey}.name', profile['name'] ?? '');
    await p.setString('${_profileKey}.bio', profile['bio'] ?? '');
    await p.setString('${_profileKey}.avatar', profile['avatar'] ?? '');
  }

  Future<List<String>> loadFollowing() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_followingKey) ?? [];
  }

  Future<void> saveFollowing(List<String> usernames) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_followingKey, usernames);
  }

  String newId() => _uuid.v4();
}
