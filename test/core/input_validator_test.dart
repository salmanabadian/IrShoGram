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
      expect(InputValidator.bio('x' * 301), isNotNull);
      expect(InputValidator.caption('x' * 2200), isNull);
      expect(InputValidator.caption('x' * 2201), isNotNull);
    });

    test('rejects empty or oversized comments and messages', () {
      expect(InputValidator.comment(' سلام '), isNull);
      expect(InputValidator.comment('  '), isNotNull);
      expect(InputValidator.comment('x' * 2001), isNotNull);
      expect(InputValidator.message('سلام'), isNull);
      expect(InputValidator.message('x' * 5001), isNotNull);
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
