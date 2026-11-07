import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneSignInScreen extends StatefulWidget {
  const PhoneSignInScreen({super.key});
  @override
  State<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends State<PhoneSignInScreen> {
  final _phone = TextEditingController(text: '+98');
  final _code = TextEditingController();
  String? _verificationId;
  int? _resendToken;
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number': return 'شماره تلفن معتبر نیست.';
      case 'invalid-verification-code': return 'کد تأیید اشتباه است.';
      case 'session-expired': return 'مهلت کد تمام شده است؛ کد تازه بگیرید.';
      case 'too-many-requests': return 'درخواست‌های زیادی ارسال شده؛ کمی بعد تلاش کنید.';
      case 'quota-exceeded': return 'سهمیه ارسال پیامک Firebase تمام شده است.';
      case 'app-not-authorized': return 'این نسخه اندروید در Firebase مجاز نشده؛ SHA را بررسی کنید.';
      case 'operation-not-allowed': return 'ورود با شماره تلفن در Firebase فعال نیست.';
      default: return 'ورود انجام نشد: ${e.message ?? e.code}';
    }
  }

  Future<void> _sendCode({bool resend = false}) async {
    final phone = _phone.text.trim().replaceAll(' ', '');
    if (!RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(phone)) {
      setState(() => _error = 'شماره را با کد کشور وارد کنید؛ مانند +989121234567');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resend ? _resendToken : null,
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          if (mounted) {
            setState(() { _busy = false; _error = _message(e); });
          }
        },
        codeSent: (id, token) {
          if (mounted) {
            setState(() {
            _verificationId = id;
            _resendToken = token;
            _codeSent = true;
            _busy = false;
            });
          }
        },
        codeAutoRetrievalTimeout: (id) => _verificationId = id,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _busy = false; _error = _message(e); });
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'ارسال کد انجام نشد. اتصال اینترنت را بررسی کنید.'; });
    }
  }

  Future<void> _verify() async {
    final id = _verificationId;
    final code = _code.text.trim();
    if (id == null || code.length != 6) {
      setState(() => _error = 'کد شش‌رقمی پیامک را وارد کنید.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final credential = PhoneAuthProvider.credential(verificationId: id, smsCode: code);
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _busy = false; _error = _message(e); });
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'تأیید کد انجام نشد. دوباره تلاش کنید.'; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 26),
          const Icon(Icons.camera_alt_outlined, size: 58, color: Color(0xFF262626)),
          const SizedBox(height: 18),
          const Text('IrShoGram', textAlign: TextAlign.center, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, letterSpacing: -1.4, color: Color(0xFF262626))),
          const SizedBox(height: 12),
          Text(_codeSent ? 'کد ارسال‌شده را وارد کنید' : 'با شماره تلفن خود وارد شوید یا حساب بسازید', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8E8E8E))),
          const SizedBox(height: 28),
          if (!_codeSent)
            TextField(controller: _phone, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'شماره تلفن همراه', hintText: '+989121234567', border: OutlineInputBorder()))
          else ...[
            TextField(controller: _code, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, maxLength: 6, decoration: const InputDecoration(labelText: 'کد تأیید پیامکی', border: OutlineInputBorder(), counterText: '')),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _busy ? null : () => _sendCode(resend: true), child: const Text('ارسال دوباره کد'))),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 18),
          SizedBox(height: 48, child: FilledButton(
            onPressed: _busy ? null : (_codeSent ? _verify : _sendCode),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0095F6)),
            child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_codeSent ? 'تأیید و ورود' : 'دریافت کد ورود'),
          )),
          const SizedBox(height: 18),
          const Text('با ادامه، کد ورود از طریق پیامک ارسال می‌شود.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF8E8E8E))),
        ],
      )),
    ))),
  );
}
