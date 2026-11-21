import 'package:flutter_test/flutter_test.dart';
import 'package:irshogram/auth/google_sign_in_error_message.dart';

void main() {
  group('googleSignInErrorMessage', () {
    test('explains missing Credential Manager provider and device checks', () {
      final message = googleSignInErrorMessage(
        code: 'providerConfigurationError',
        description: 'getCredentialAsync no provider dependencies found',
      );

      expect(message, contains('Google Play Services'));
      expect(message, contains('حساب Google'));
      expect(message, contains('SHA-1'));
      expect(message, contains('SHA-256'));
    });

    test('points OAuth configuration failures to the relevant settings', () {
      final message = googleSignInErrorMessage(
        code: 'clientConfigurationError',
      );

      expect(message, contains('OAuth'));
      expect(message, contains('Web Client ID'));
    });

    test('does not report user cancellation as a provider installation issue', () {
      final message = googleSignInErrorMessage(code: 'canceled');

      expect(message, contains('لغو شد'));
      expect(message, contains('OAuth'));
    });
  });
}
