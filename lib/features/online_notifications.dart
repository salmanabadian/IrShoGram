import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

/// Displays notifications stored under the signed-in user's Firestore profile.
/// Notification creation remains restricted to trusted backend code.
class OnlineNotificationsSheet {
  static Future<void> show(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OnlineNotificationsList(uid: uid),
    );
  }
}

class _OnlineNotificationsList extends StatelessWidget {
  const _OnlineNotificationsList({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final notifications = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'اعلان‌ها',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: notifications,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'دریافت اعلان‌ها از سرور انجام نشد. اتصال اینترنت را بررسی کنید.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final documents = snapshot.data!.docs;
                  if (documents.isEmpty) {
                    return const Center(child: Text('اعلان تازه‌ای ندارید.'));
                  }

                  return ListView.separated(
                    itemCount: documents.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = documents[index];
                      final data = notification.data();
                      final actorId = data['actorId'] is String
                          ? data['actorId'] as String
                          : '';
                      final type = data['type'] is String
                          ? data['type'] as String
                          : 'system';
                      final isRead = data['read'] == true;

                      return ListTile(
                        tileColor: isRead
                            ? null
                            : const Color(0xFFF2F8FF),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEAF5FF),
                          child: Icon(
                            _iconFor(type),
                            color: _colorFor(type),
                          ),
                        ),
                        title: Text(_messageFor(type)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (actorId.isNotEmpty)
                              FutureBuilder<
                                  DocumentSnapshot<Map<String, dynamic>>>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(actorId)
                                    .get(),
                                builder: (context, actor) {
                                  final username = actor.data?.data()?['username'];
                                  if (username is! String || username.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text('@$username');
                                },
                              ),
                            Text(_timeLabel(data['createdAt'])),
                          ],
                        ),
                        trailing: isRead
                            ? null
                            : const Icon(
                                Icons.circle,
                                size: 9,
                                color: Color(0xFF0095F6),
                              ),
                        onTap: isRead
                            ? null
                            : () async {
                                try {
                                  await notification.reference.update({
                                    'read': true,
                                  });
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('علامت‌گذاری اعلان انجام نشد.'),
                                    ),
                                  );
                                }
                              },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String type) => switch (type) {
        'like' => Icons.favorite,
        'comment' => Icons.mode_comment_outlined,
        'follow' => Icons.person_add_alt_1,
        'mention' => Icons.alternate_email,
        _ => Icons.notifications_outlined,
      };

  static Color _colorFor(String type) =>
      type == 'like' ? Colors.pink : const Color(0xFF0095F6);

  static String _messageFor(String type) => switch (type) {
        'like' => 'پست شما را پسندید.',
        'comment' => 'برای پست شما دیدگاه نوشت.',
        'follow' => 'شما را دنبال کرد.',
        'mention' => 'در یک محتوا از شما نام برد.',
        _ => 'اعلان جدیدی برای شما ثبت شده است.',
      };

  static String _timeLabel(Object? value) {
    if (value is! Timestamp) return '';
    final difference = DateTime.now().difference(value.toDate());
    if (difference.isNegative || difference.inMinutes < 1) return 'همین الان';
    if (difference.inHours < 1) return '${difference.inMinutes} دقیقه پیش';
    if (difference.inDays < 1) return '${difference.inHours} ساعت پیش';
    return '${difference.inDays} روز پیش';
  }
}
