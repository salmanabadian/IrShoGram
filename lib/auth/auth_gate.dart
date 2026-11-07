import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'phone_sign_in_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _profileUid;
  Future<void>? _profileFuture;

  Future<void> _ensureProfile(User user) async {
    final reference = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await reference.get();
    if (snapshot.exists) return;
    await reference.set({
      'uid': user.uid,
      'username': 'user_${user.uid.substring(0, 8)}',
      'displayName': 'کاربر ایرشوگرام',
      'bio': '',
      'photoUrl': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, auth) {
      if (auth.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = auth.data;
      if (user == null) {
        _profileUid = null;
        _profileFuture = null;
        return const PhoneSignInScreen();
      }
      if (_profileUid != user.uid) {
        _profileUid = user.uid;
        _profileFuture = _ensureProfile(user);
      }
      return FutureBuilder<void>(
        future: _profileFuture,
        builder: (context, profile) {
          if (profile.hasError) {
            return Scaffold(body: Center(child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text('ساخت پروفایل در Firebase انجام نشد. اتصال اینترنت و قوانین Firestore را بررسی کنید.\n${profile.error}', textAlign: TextAlign.center),
            )));
          }
          if (profile.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return widget.child;
        },
      );
    },
  );
}

class FirebaseSetupRequiredScreen extends StatelessWidget {
  const FirebaseSetupRequiredScreen({super.key, required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(child: Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, size: 54, color: Color(0xFF8E8E8E)),
        const SizedBox(height: 18),
        const Text('اتصال Firebase کامل نشده است', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        const Text('فایل تنظیمات Android با شناسه com.irshogram.app باید در مسیر android/app/google-services.json قرار بگیرد و ورود با Phone در Firebase فعال باشد.', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(error.toString(), style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
      ]),
    ))),
  );
}
