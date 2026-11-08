import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_sign_in_error_message.dart';

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  static const String _serverClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  final Future<void> _googleInitialization = GoogleSignIn.instance.initialize(
    serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
  );
  bool _busy = false;
  String? _error;

  String _firebaseErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'account-exists-with-different-credential' =>
        'این ایمیل قبلاً با روش ورود دیگری ثبت شده است. با پشتیبانی تماس بگیرید.',
      'invalid-credential' || 'credential-already-in-use' =>
        'اطلاعات ورود Google معتبر نیست. دوباره حساب خود را انتخاب کنید.',
      'operation-not-allowed' =>
        'ورود با Google در تنظیمات Firebase فعال نشده است.',
      'user-disabled' => 'این حساب کاربری غیرفعال شده است.',
      'too-many-requests' =>
        'تلاش‌های ورود بیش از حد بوده است. کمی بعد دوباره امتحان کنید.',
      'network-request-failed' =>
        'اتصال اینترنت برقرار نیست. اینترنت را بررسی و دوباره تلاش کنید.',
      'missing-google-id-token' =>
        'Google توکن ورود را برنگرداند. تنظیمات OAuth باید بررسی شود.',
      _ => 'ورود با Google انجام نشد. دوباره تلاش کنید.',
    };
  }

  String _googleErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('canceled') || message.contains('cancelled')) {
      return 'ورود با Google لغو شد.';
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return 'اتصال اینترنت برقرار نیست. اینترنت را بررسی و دوباره تلاش کنید.';
    }
    return 'ارتباط با Google برقرار نشد. دوباره تلاش کنید.';
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _googleInitialization;
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google did not return an ID token.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
      // AuthGate loads or creates the user's Firestore profile after sign-in.
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '${_firebaseErrorMessage(error)}\nکد فنی: ${error.code}';
      });
    } on GoogleSignInException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        final description = error.description?.trim();
        final guidance = googleSignInErrorMessage(
          code: error.code.name,
          description: description,
        );
        _error = '$guidance\nکد فنی: ${error.code.name}'
            '${description == null || description.isEmpty ? '' : '\nجزئیات: $description'}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '${_googleErrorMessage(error)}\nجزئیات فنی: ${error.runtimeType}: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 30,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 26),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF7B2FF7),
                          Color(0xFFE1306C),
                          Color(0xFFFF9A3D),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 62,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'IrShoGram',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.4,
                        color: Color(0xFF262626),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'برای ورود، حساب Google خود را انتخاب کنید',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8E8E8E)),
                    ),
                    const SizedBox(height: 32),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _busy ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF262626),
                          side: const BorderSide(
                            color: Color(0xFFDBDBDB),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'ادامه با Google',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ورود و ثبت‌نام فقط با حساب Google انجام می‌شود.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E8E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
