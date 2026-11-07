import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  final Future<void> _googleInitialization =
      GoogleSignIn.instance.initialize();
  bool _busy = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _googleInitialization;
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google did not return an ID token.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
      // AuthGate loads or creates the user's Firestore profile after sign-in.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'خطای ورود Google (${e.code}): '
            '${e.message ?? 'جزئیات بیشتری از Firebase دریافت نشد.'}';
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().toLowerCase();
      setState(() {
        _busy = false;
        _error = message.contains('canceled') ||
                message.contains('cancelled')
            ? 'ورود با Google لغو شد.'
            : 'خطای Google: $e';
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
