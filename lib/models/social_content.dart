import '../core/firestore_value_parser.dart';

enum MediaType { image, video }

extension MediaTypeValue on MediaType {
  String get value => name;

  static MediaType parse(Object? value) {
    switch (value) {
      case 'image':
        return MediaType.image;
      case 'video':
        return MediaType.video;
      default:
        throw FormatException('Unsupported media type: $value');
    }
  }
}

String _stringFromMap(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String) return value;
  throw FormatException('Missing or invalid "$key".');
}

class SocialPost {
  const SocialPost({
    required this.id,
    required this.authorId,
    required this.caption,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String authorId;
  final String caption;
  final String mediaUrl;
  final MediaType mediaType;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SocialPost.fromMap(String id, Map<String, Object?> map) =>
      SocialPost(
        id: id,
        authorId: _stringFromMap(map, 'authorId'),
        caption: _stringFromMap(map, 'caption'),
        mediaUrl: _stringFromMap(map, 'mediaUrl'),
        mediaType: MediaTypeValue.parse(map['mediaType']),
        createdAt: parseDateTimeValue(map['createdAt'], fieldName: 'createdAt'),
        updatedAt: parseDateTimeValue(map['updatedAt'], fieldName: 'updatedAt'),
      );

  Map<String, Object?> toMap() => {
        'authorId': authorId,
        'caption': caption,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType.value,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class Story {
  const Story({
    required this.id,
    required this.authorId,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String authorId;
  final String mediaUrl;
  final MediaType mediaType;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool isExpiredAt(DateTime time) => !expiresAt.isAfter(time);

  factory Story.fromMap(String id, Map<String, Object?> map) => Story(
        id: id,
        authorId: _stringFromMap(map, 'authorId'),
        mediaUrl: _stringFromMap(map, 'mediaUrl'),
        mediaType: MediaTypeValue.parse(map['mediaType']),
        createdAt: _dateFromMap(map, 'createdAt'),
        expiresAt: parseDateTimeValue(map['expiresAt'], fieldName: 'expiresAt'),
      );

  Map<String, Object?> toMap() => {
        'authorId': authorId,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType.value,
        'createdAt': createdAt,
        'expiresAt': expiresAt,
      };
}

class Reel {
  const Reel({
    required this.id,
    required this.authorId,
    required this.caption,
    required this.mediaUrl,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String caption;
  final String mediaUrl;
  final DateTime createdAt;

  factory Reel.fromMap(String id, Map<String, Object?> map) => Reel(
        id: id,
        authorId: _stringFromMap(map, 'authorId'),
        caption: _stringFromMap(map, 'caption'),
        mediaUrl: _stringFromMap(map, 'mediaUrl'),
        createdAt: _dateFromMap(map, 'createdAt'),
      );

  Map<String, Object?> toMap() => {
        'authorId': authorId,
        'caption': caption,
        'mediaUrl': mediaUrl,
        'createdAt': createdAt,
      };
}
