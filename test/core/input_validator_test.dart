import 'package:flutter_test/flutter_test.dart';
import 'package:irshogram/core/input_validator.dart';

void main() {
  group('InputValidator', () {
    test('accepts valid usernames and rejects invalid values', () {
      expect(InputValidator.username('irsho.user_01'), isNull);
      expect(InputValidator.username('ab'), isNotNull);
      expect(InputValidator.username('bad name'), isNotNull);
    });

    test('enforces profile and content limits', () {
      expect(InputValidator.displayName('کاربر'), isNull);
      expect(InputValidator.displayName(''), isNotNull);
      expect(InputValidator.bio(List<String>.filled(301, 'x').join()), isNotNull);
      expect(InputValidator.caption(List<String>.filled(2200, 'x').join()), isNull);
      expect(InputValidator.caption(List<String>.filled(2201, 'x').join()), isNotNull);
    });

    test('rejects empty or oversized comments and messages', () {
      expect(InputValidator.comment(' سلام '), isNull);
      expect(InputValidator.comment('  '), isNotNull);
      expect(InputValidator.comment(List<String>.filled(2001, 'x').join()), isNotNull);
      expect(InputValidator.message('سلام'), isNull);
      expect(InputValidator.message(List<String>.filled(5001, 'x').join()), isNotNull);
    });

    test('requires exactly two distinct conversation participants', () {
      expect(
        InputValidator.validateConversationParticipants(['a', 'b'], 'a'),
        isNull,
      );
      expect(
        InputValidator.validateConversationParticipants(['a', 'a'], 'a'),
        isNotNull,
      );
      expect(
        InputValidator.validateConversationParticipants(['a', 'b', 'c'], 'a'),
        isNotNull,
      );
    });
  });
}
