import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneTestSignInScreen extends StatefulWidget {
  const PhoneTestSignInScreen({super.key});

  @override
  State<PhoneTestSignInScreen> createState() => _PhoneTestSignInScreenState();
}

class _PhoneTestSignInScreenState extends State<PhoneTestSignInScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(phone)) {
      setState(() => _message = 'شماره را با کد کشور و بدون فاصله وارد کنید؛ مانند +98912XXXXXXX');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _verificationId = null;
    });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (mounted) Navigator.of(context).pop();
          } on FirebaseAuthException catch (error) {
            if (mounted) setState(() { _busy = false; _message = 'ورود خودکار انجام نشد: ${error.code}'; });
          }
        },
        verificationFailed: (error) {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _message = 'ارسال/تأیید کد انجام نشد: ${error.code} — ${error.message ?? ''}';
          });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _busy = false;
            _message = 'کد آزمایشی ثابت را وارد کنید. برای شماره ثبت‌شده در Firebase پیامک واقعی ارسال نمی‌شود.';
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!mounted) return;
          setState(() => _verificationId = verificationId);
        },
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() { _busy = false; _message = 'خطای Firebase: ${error.code}'; });
    } catch (error) {
      if (mounted) setState(() { _busy = false; _message = 'خطا: $error'; });
    }
  }

  Future<void> _verifyCode() async {
    final id = _verificationId;
    final code = _codeController.text.trim();
    if (id == null || code.length != 6) {
      setState(() => _message = 'ابتدا شماره را تأیید کنید و کد شش‌رقمی را وارد کنید.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: id,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() { _busy = false; _message = 'کد پذیرفته نشد: ${error.code}'; });
    } catch (error) {
      if (mounted) setState(() { _busy = false; _message = 'خطا: $error'; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ورود آزمایشی با شماره')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.phone_android, size: 52, color: Color(0xFF8A2BE2)),
                const SizedBox(height: 16),
                const Text('فقط شماره‌هایی که در Firebase بخش Phone numbers for testing ثبت شده‌اند، بدون پیامک و هزینه قابل استفاده‌اند.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'شماره با کد کشور',
                    hintText: '+98912XXXXXXX',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : _requestCode,
                  child: const Text('دریافت کد آزمایشی'),
                ),
                if (_verificationId != null) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'کد شش‌رقمی آزمایشی',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _busy ? null : _verifyCode,
                    child: const Text('ورود به IrShoGram'),
                  ),
                ],
                if (_busy) const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8A2BE2))),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
