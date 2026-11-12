// ignore_for_file: unnecessary_underscores

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';

import '../models/messaging.dart';
import '../repositories/firebase_social_repository.dart';

const _blue = Color(0xFF0095F6);
const _ink = Color(0xFF262626);
const _muted = Color(0xFF8E8E8E);

class OnlineFeedPage extends StatelessWidget {
  const OnlineFeedPage({super.key, this.onCreatePost});
  final VoidCallback? onCreatePost;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance.collection('posts')
        .orderBy('createdAt', descending: true).limit(50).snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('بارگذاری پست‌ها از سرور انجام نشد.\n${snapshot.error}', textAlign: TextAlign.center),
          ));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.photo_library_outlined, size: 54, color: _muted),
            const SizedBox(height: 14),
            const Text('هنوز پستی منتشر نشده است.', style: TextStyle(fontWeight: FontWeight.w600, color: _ink)),
            const SizedBox(height: 6),
            const Text('اولین عکس یا ویدیوی خود را به اشتراک بگذارید.', style: TextStyle(color: _muted)),
            const SizedBox(height: 14),
            FilledButton(onPressed: onCreatePost, child: const Text('ایجاد پست')),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) => _OnlinePostCard(post: docs[index]),
        );
      },
    );
  }
}

class _OnlinePostCard extends StatelessWidget {
  const _OnlinePostCard({required this.post});
  final QueryDocumentSnapshot<Map<String, dynamic>> post;

  @override
  Widget build(BuildContext context) {
    final data = post.data();
    final uid = data['authorId'] as String? ?? '';
    final mediaUrl = data['mediaUrl'] as String? ?? '';
    final isVideo = data['mediaType'] == 'video';
    final created = data['createdAt'];
    final date = created is Timestamp ? created.toDate() : DateTime.now();
    final userFuture = FirebaseFirestore.instance.collection('users').doc(uid).get();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(children: [
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: userFuture,
            builder: (context, user) {
              final name = user.data?.data()?['username'] as String? ?? 'کاربر';
              return CircleAvatar(radius: 17, backgroundColor: const Color(0xFFEAF5FF),
                child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(color: _blue, fontWeight: FontWeight.bold)));
            },
          ),
          const SizedBox(width: 9),
          Expanded(child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: userFuture,
            builder: (context, user) {
              final name = user.data?.data()?['username'] as String? ?? 'کاربر ایرشوگرام';
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _ink)),
                Text(_relativeTime(date), style: const TextStyle(fontSize: 11, color: _muted)),
              ]);
            },
          )),
          if (uid == FirebaseAuth.instance.currentUser?.uid)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  await FirebaseFirestore.instance.collection('posts').doc(post.id).delete();
                }
              },
              itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('حذف پست'))],
            ),
        ]),
      ),
      if (mediaUrl.isNotEmpty)
        AspectRatio(
          aspectRatio: 1,
          child: isVideo ? _NetworkPostVideo(url: mediaUrl) : Image.network(
            mediaUrl, fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFEFEFEF), child: Center(child: Icon(Icons.broken_image_outlined, size: 48))),
          ),
        )
      else
        const AspectRatio(aspectRatio: 1, child: ColoredBox(color: Color(0xFFEFEFEF), child: Center(child: Icon(Icons.broken_image_outlined)))),
      _OnlinePostActions(postId: post.id, authorId: uid, caption: data['caption'] as String? ?? ''),
      const Divider(height: 1, color: Color(0xFFDBDBDB)),
    ]);
  }
}

class _OnlinePostActions extends StatelessWidget {
  const _OnlinePostActions({required this.postId, required this.authorId, required this.caption});
  final String postId;
  final String authorId;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final likes = FirebaseFirestore.instance.collection('posts').doc(postId).collection('likes');
    final myLike = likes.doc(uid).snapshots();
    final likeCount = likes.snapshots();
    final comments = FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
        child: Row(children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: myLike,
            builder: (context, mine) => IconButton(
              onPressed: () async {
                final ref = likes.doc(uid);
                if (mine.data?.exists == true) {
                  await ref.delete();
                } else {
                  await ref.set({'createdAt': FieldValue.serverTimestamp()});
                }
              },
              icon: Icon(mine.data?.exists == true ? Icons.favorite : Icons.favorite_border,
                color: mine.data?.exists == true ? Colors.red : _ink, size: 27),
            ),
          ),
          IconButton(onPressed: () => _showComments(context, comments), icon: const Icon(Icons.mode_comment_outlined, color: _ink, size: 25)),
          const Spacer(),
          IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('اشتراک‌گذاری پست به‌زودی اضافه می‌شود.'))),
            icon: const Icon(Icons.send_outlined, color: _ink, size: 25)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: likeCount,
          builder: (context, snapshot) => Text('${snapshot.data?.docs.length ?? 0} پسند',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _ink)),
        ),
      ),
      if (caption.isNotEmpty)
        Padding(padding: const EdgeInsets.fromLTRB(14, 5, 14, 12), child: Text(caption)),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: comments.orderBy('createdAt', descending: true).limit(1).snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.data?.docs.length ?? 0;
          return count == 0 ? const SizedBox.shrink() : Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: InkWell(onTap: () => _showComments(context, comments),
              child: const Text('مشاهده دیدگاه‌ها', style: TextStyle(color: _muted, fontSize: 13))),
          );
        },
      ),
    ]);
  }

  Future<void> _showComments(BuildContext context, CollectionReference<Map<String, dynamic>> comments) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
        child: SizedBox(height: 420, child: Column(children: [
          const Text('دیدگاه‌ها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: comments.orderBy('createdAt', descending: true).limit(50).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) return const Center(child: Text('هنوز دیدگاهی ثبت نشده است.'));
              return ListView(children: snapshot.data!.docs.map((doc) {
                final value = doc.data();
                return ListTile(dense: true, leading: const CircleAvatar(child: Icon(Icons.person, size: 18)),
                  title: Text(value['text'] as String? ?? ''));
              }).toList());
            },
          )),
          Row(children: [
            Expanded(child: TextField(controller: controller, maxLength: 2000, decoration: const InputDecoration(hintText: 'دیدگاه بنویسید...', counterText: ''))),
            IconButton(icon: const Icon(Icons.send), onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              final user = FirebaseAuth.instance.currentUser!;
              await comments.add({'authorId': user.uid, 'text': text, 'createdAt': FieldValue.serverTimestamp()});
              controller.clear();
            }),
          ]),
        ])),
      ),
    );
    controller.dispose();
  }
}

class _NetworkPostVideo extends StatefulWidget {
  const _NetworkPostVideo({required this.url});
  final String url;

  @override
  State<_NetworkPostVideo> createState() => _NetworkPostVideoState();
}

class _NetworkPostVideoState extends State<_NetworkPostVideo> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _failed = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant _NetworkPostVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url) return;

    _loadGeneration++;
    final previous = _controller;
    _controller = null;
    previous?.removeListener(_handleControllerUpdate);
    previous?.dispose();
    _loading = true;
    _failed = false;
    _initialize();
  }

  Future<void> _initialize() async {
    final generation = ++_loadGeneration;
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    controller.addListener(_handleControllerUpdate);

    try {
      await controller.initialize();
      if (!mounted ||
          generation != _loadGeneration ||
          !identical(_controller, controller)) {
        return;
      }
      setState(() => _loading = false);
    } catch (_) {
      if (!identical(_controller, controller)) return;
      controller.removeListener(_handleControllerUpdate);
      _controller = null;
      await controller.dispose();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _handleControllerUpdate() {
    if (!mounted || _failed || _controller?.value.hasError != true) return;
    setState(() => _failed = true);
  }

  Future<void> _retry() async {
    final previous = _controller;
    _controller = null;
    previous?.removeListener(_handleControllerUpdate);
    await previous?.dispose();
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    await _initialize();
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _failed) {
      return;
    }
    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    final controller = _controller;
    controller?.removeListener(_handleControllerUpdate);
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed || controller?.value.hasError == true) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, color: Colors.white70, size: 34),
              const SizedBox(height: 8),
              const Text(
                'پخش ویدیو انجام نشد',
                style: TextStyle(color: Colors.white),
              ),
              TextButton(
                onPressed: _loading ? null : _retry,
                child: const Text('تلاش دوباره'),
              ),
            ],
          ),
        ),
      );
    }
    if (_loading || controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return GestureDetector(
      onTap: _togglePlayback,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

String _relativeTime(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'همین الان';
  if (difference.inHours < 1) return '${difference.inMinutes} دقیقه پیش';
  if (difference.inDays < 1) return '${difference.inHours} ساعت پیش';
  return '${difference.inDays} روز پیش';
}

class OnlinePostComposer {
  static Future<void> create(BuildContext context, {bool asReel = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final picker = ImagePicker();
    final picked = asReel
        ? await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 90))
        : await picker.pickMedia(imageQuality: 88, maxWidth: 2400);
    if (picked == null || !context.mounted) return;
    final isVideo = asReel || picked.mimeType?.startsWith('video/') == true;
    final caption = TextEditingController();
    final accepted = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(asReel ? 'انتشار ریلز' : 'انتشار پست', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (!isVideo) ClipRRect(borderRadius: BorderRadius.circular(12),
            child: Image.file(File(picked.path), height: 200, fit: BoxFit.cover)),
          if (isVideo) const ListTile(leading: Icon(Icons.video_file), title: Text('ویدیوی انتخاب‌شده')),
          TextField(controller: caption, maxLength: 2200, maxLines: 3,
            decoration: const InputDecoration(hintText: 'برای این پست توضیحی بنویسید...', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => Navigator.pop(sheetContext, true), child: Text(asReel ? 'انتشار ریلز' : 'انتشار')),
        ]),
      ),
    );
    if (accepted != true || !context.mounted) { caption.dispose(); return; }
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('در حال بارگذاری رسانه و انتشار پست...')));
    try {
      final extension = picked.name.contains('.') ? picked.name.split('.').last.toLowerCase() : (isVideo ? 'mp4' : 'jpg');
      final path = '${asReel ? 'reels' : 'posts'}/${user.uid}/${const Uuid().v4()}.$extension';
      final storageRef = FirebaseStorage.instance.ref().child(path);
      final metadata = SettableMetadata(contentType: picked.mimeType ?? (isVideo ? 'video/mp4' : 'image/jpeg'));
      await storageRef.putFile(File(picked.path), metadata);
      final url = await storageRef.getDownloadURL();
      final collection = FirebaseFirestore.instance.collection(asReel ? 'reels' : 'posts');
      final post = collection.doc();
      await post.set({
        'authorId': user.uid,
        'caption': caption.text.trim(),
        'mediaUrl': url,
        if (!asReel) 'mediaType': isVideo ? 'video' : 'image',
        'createdAt': FieldValue.serverTimestamp(),
        if (!asReel) 'updatedAt': FieldValue.serverTimestamp(),
      });
      messenger.showSnackBar(SnackBar(content: Text(asReel
        ? 'ریلز با موفقیت در سرور منتشر شد.'
        : 'پست با موفقیت در سرور منتشر شد.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('انتشار پست ناموفق بود: $error')));
    } finally {
      caption.dispose();
    }
  }
}


class OnlineStoriesStrip extends StatelessWidget {
  const OnlineStoriesStrip({super.key});

  static Future<void> createStory(BuildContext context) => _createStory(context);

  @override
  Widget build(BuildContext context) {
    final stories = FirebaseFirestore.instance.collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt').orderBy('createdAt', descending: true).limit(50).snapshots();
    return SizedBox(
      height: 112,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stories,
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            children: [
              GestureDetector(
                onTap: () => _createStory(context),
                child: SizedBox(width: 76, child: Column(children: [
                  Stack(children: [
                    const CircleAvatar(radius: 28, backgroundColor: Color(0xFFEFEFEF),
                      child: Icon(Icons.person, color: _muted, size: 30)),
                    const Positioned(right: 0, bottom: 0,
                      child: CircleAvatar(radius: 10, backgroundColor: _blue,
                        child: Icon(Icons.add, size: 15, color: Colors.white))),
                  ]),
                  const SizedBox(height: 5),
                  const Text('داستان شما', style: TextStyle(fontSize: 11)),
                ])),
              ),
              for (final doc in docs)
                _OnlineStoryAvatar(story: doc),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _createStory(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickMedia(imageQuality: 88, maxWidth: 1920);
    if (picked == null || !context.mounted) return;
    final isVideo = picked.mimeType?.startsWith('video/') == true;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('در حال بارگذاری استوری...')));
    try {
      final ext = picked.name.contains('.') ? picked.name.split('.').last.toLowerCase() : (isVideo ? 'mp4' : 'jpg');
      final storagePath = 'stories/${user.uid}/${const Uuid().v4()}.$ext';
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.putFile(File(picked.path), SettableMetadata(
        contentType: picked.mimeType ?? (isVideo ? 'video/mp4' : 'image/jpeg'),
      ));
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('stories').add({
        'authorId': user.uid,
        'mediaUrl': url,
        'mediaType': isVideo ? 'video' : 'image',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
      });
      messenger.showSnackBar(const SnackBar(content: Text('استوری برای ۲۴ ساعت منتشر شد.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('انتشار استوری ناموفق بود: $error')));
    }
  }
}

class _OnlineStoryAvatar extends StatelessWidget {
  const _OnlineStoryAvatar({required this.story});
  final QueryDocumentSnapshot<Map<String, dynamic>> story;

  @override
  Widget build(BuildContext context) {
    final uid = story.data()['authorId'] as String? ?? '';
    final user = FirebaseFirestore.instance.collection('users').doc(uid).get();
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: user,
      builder: (context, snapshot) {
        final username = snapshot.data?.data()?['username'] as String? ?? 'کاربر';
        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => _OnlineStoryViewer(story: story, username: username),
          )),
          child: SizedBox(width: 76, child: Column(children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(
                colors: [Color(0xFF8134AF), Color(0xFFE1306C), Color(0xFFFCAF45)],
              )),
              child: CircleAvatar(radius: 27, backgroundColor: const Color(0xFFEAF5FF),
                child: Text(username.isEmpty ? '?' : username[0].toUpperCase(),
                  style: const TextStyle(color: _blue, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 5),
            Text(username, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11)),
          ])),
        );
      },
    );
  }
}

class _OnlineStoryViewer extends StatelessWidget {
  const _OnlineStoryViewer({required this.story, required this.username});
  final QueryDocumentSnapshot<Map<String, dynamic>> story;
  final String username;

  @override
  Widget build(BuildContext context) {
    final data = story.data();
    final url = data['mediaUrl'] as String? ?? '';
    final isVideo = data['mediaType'] == 'video';
    final own = data['authorId'] == FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(fit: StackFit.expand, children: [
          if (isVideo) _NetworkPostVideo(url: url)
          else Image.network(url, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white))),
          Positioned(top: 12, left: 12, right: 12, child: Container(height: 3,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
          Positioned(top: 28, right: 14, child: Row(children: [
            const CircleAvatar(radius: 17, child: Icon(Icons.person, size: 18)),
            const SizedBox(width: 8),
            Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ])),
          Positioned(top: 22, left: 10, child: Row(children: [
            if (own) IconButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('stories').doc(story.id).delete();
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            IconButton(onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white)),
          ])),
        ]),
      )),
    );
  }
}


class OnlineReelsPage extends StatelessWidget {
  const OnlineReelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reels = FirebaseFirestore.instance.collection('reels')
        .orderBy('createdAt', descending: true).limit(50).snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: reels,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('بارگذاری ریلزها ناموفق بود: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) { return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.video_collection_outlined, size: 62, color: _muted),
          const SizedBox(height: 12),
          const Text('هنوز ریلزی منتشر نشده است.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => OnlinePostComposer.create(context, asReel: true),
            icon: const Icon(Icons.add), label: const Text('ساخت ریلز'),
          ),
        ])); }
        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final uid = data['authorId'] as String? ?? '';
            final url = data['mediaUrl'] as String? ?? '';
            final caption = data['caption'] as String? ?? '';
            return Stack(fit: StackFit.expand, children: [
              if (url.isNotEmpty) _NetworkPostVideo(url: url)
              else const ColoredBox(color: Colors.black),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.transparent, Colors.black87],
              ))),
              Positioned(left: 16, right: 16, bottom: 28, child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                builder: (context, user) {
                  final username = user.data?.data()?['username'] as String? ?? 'کاربر';
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('@$username', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (caption.isNotEmpty) Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(caption, style: const TextStyle(color: Colors.white)),
                    ),
                  ]);
                },
              )),
              Positioned(top: 12, right: 12, child: Text('Reels', style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 18, fontWeight: FontWeight.bold))),
            ]);
          },
        );
      },
    );
  }
}


class OnlineMessagesPage extends StatelessWidget {
  const OnlineMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final conversations = FirebaseFirestore.instance.collection('conversations')
        .where('participantIds', arrayContains: uid)
        .orderBy('updatedAt', descending: true).snapshots();
    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Align(alignment: Alignment.centerRight,
          child: Text('پیام‌ها', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink))),
      ),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: conversations,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('بارگذاری پیام‌ها ناموفق بود: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) { return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.send_outlined, size: 58, color: _ink),
            SizedBox(height: 12),
            Text('پیام‌هایت را ارسال کن', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text('برای شروع گفتگو، یک حساب را از بخش جستجو انتخاب کن.', style: TextStyle(color: _muted)),
          ])); }
          return ListView(children: docs.map((doc) {
            final participants = List<String>.from(doc.data()['participantIds'] as List? ?? const []);
            final otherUid = participants.firstWhere((id) => id != uid, orElse: () => '');
            return _ConversationTile(conversationId: doc.id, otherUid: otherUid);
          }).toList());
        },
      )),
    ]);
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversationId, required this.otherUid});
  final String conversationId;
  final String otherUid;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseFirestore.instance.collection('users').doc(otherUid).get();
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: user,
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final username = data['username'] as String? ?? 'کاربر';
        return ListTile(
          leading: CircleAvatar(backgroundColor: const Color(0xFFEAF5FF),
            child: Text(username.isEmpty ? '?' : username[0].toUpperCase(), style: const TextStyle(color: _blue))),
          title: Text(username, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('برای مشاهده پیام‌ها وارد گفتگو شوید.', style: TextStyle(color: _muted)),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => OnlineChatPage(conversationId: conversationId, peerName: username),
          )),
        );
      },
    );
  }
}

class OnlineChatPage extends StatefulWidget {
  const OnlineChatPage({super.key, required this.conversationId, required this.peerName});
  final String conversationId;
  final String peerName;

  static Future<void> open(BuildContext context, String otherUid, String peerName) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    if (otherUid == currentUid) return;
    final ids = [currentUid, otherUid]..sort();
    final id = ids.join('_');
    final ref = FirebaseFirestore.instance.collection('conversations').doc(id);
    final existing = await ref.get();
    if (!existing.exists) {
      await ref.set({
        'participantIds': ids,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OnlineChatPage(conversationId: id, peerName: peerName),
    ));
  }

  @override
  State<OnlineChatPage> createState() => _OnlineChatPageState();
}

class _OnlineChatPageState extends State<OnlineChatPage> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw StateError('برای ارسال پیام باید وارد حساب شوید.');
      }
      await FirebaseSocialRepository().sendMessage(
        widget.conversationId,
        DirectMessage(
          id: '',
          senderId: uid,
          text: text,
          createdAt: DateTime.now(),
        ),
      );
      _controller.clear();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ارسال پیام ناموفق بود: $error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final messages = FirebaseFirestore.instance.collection('conversations')
        .doc(widget.conversationId).collection('messages')
        .orderBy('createdAt', descending: true).limit(100).snapshots();
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: messages,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('دریافت پیام‌ها ناموفق بود: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('هنوز پیامی وجود ندارد. اولین پیام را بفرستید.'));
            return ListView.builder(
              reverse: true, padding: const EdgeInsets.all(14), itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final mine = data['senderId'] == uid;
                return Align(
                  alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 290),
                    decoration: BoxDecoration(
                      color: mine ? const Color(0xFFE4F1FF) : const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(data['text'] as String? ?? ''),
                  ),
                );
              },
            );
          },
        )),
        SafeArea(child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Expanded(child: TextField(controller: _controller, maxLength: 5000,
              decoration: const InputDecoration(counterText: '', hintText: 'پیام بنویسید...', border: OutlineInputBorder()),
              onSubmitted: (_) => _send())),
            IconButton(onPressed: _sending ? null : _send,
              icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send)),
          ]),
        )),
      ]),
    );
  }
}
