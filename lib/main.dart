// ignore_for_file: unnecessary_underscores, unused_element

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'auth/auth_gate.dart';
import 'features/online_feed.dart';
import 'services/local_social_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? firebaseError;
  try {
    await Firebase.initializeApp();
  } catch (error) {
    firebaseError = error;
  }
  runApp(IrShoGramApp(firebaseError: firebaseError));
}

const _purple = Color(0xFF0095F6);
const _igBlack = Color(0xFF262626);
const _igGrey = Color(0xFF8E8E8E);
const _igBorder = Color(0xFFDBDBDB);
const _people = <String>['ali.photo', 'mohammad', 'reza_daily', 'sara.art', 'amir', 'maryam'];

class IrShoGramApp extends StatefulWidget {
  const IrShoGramApp({super.key, this.firebaseError});
  final Object? firebaseError;

  @override
  State<IrShoGramApp> createState() => _IrShoGramAppState();
}

class _IrShoGramAppState extends State<IrShoGramApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'IrShoGram',
    debugShowCheckedModeBanner: false,
    themeMode: _mode,
    theme: ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF0095F6),
      scaffoldBackgroundColor: Colors.white,
      dividerColor: const Color(0xFFDBDBDB),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Color(0xFF262626), elevation: 0, centerTitle: true),
    ),
    darkTheme: ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB65CDE), brightness: Brightness.dark),
    ),
    home: widget.firebaseError == null
        ? AuthGate(child: MainShell(
      isDark: _mode == ThemeMode.dark,
      onThemeChanged: (dark) => setState(() => _mode = dark ? ThemeMode.dark : ThemeMode.light),
    ))
        : FirebaseSetupRequiredScreen(error: widget.firebaseError!),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.isDark, required this.onThemeChanged});
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _store = LocalSocialStore.instance;
  final _picker = ImagePicker();
  final _searchController = TextEditingController();
  final _captionController = TextEditingController();
  int _tab = 0;
  bool _loading = true;
  bool _busy = false;
  List<LocalPost> _posts = [];
  List<LocalStory> _stories = [];
  List<LocalMessage> _messages = [];
  List<String> _following = [];
  Map<String, String> _profile = {};
  final List<String> _notifications = [];

  String get _username => _profile['username'] ?? 'irshogram_user';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _store.loadPosts(),
      _store.loadStories(),
      _store.loadMessages(),
      _store.loadProfile(),
      _store.loadFollowing(),
    ]);
    if (!mounted) return;
    setState(() {
      _posts = results[0] as List<LocalPost>;
      _stories = results[1] as List<LocalStory>;
      _messages = results[2] as List<LocalMessage>;
      _profile = results[3] as Map<String, String>;
      _following = results[4] as List<String>;
    });
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final profileSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final profile = profileSnapshot.data() ?? <String, dynamic>{};
    final followingSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).collection('following').get();
    if (!mounted) return;
    setState(() {
      _profile = {
        'username': profile['username'] as String? ?? 'user_${uid.substring(0, 8)}',
        'name': profile['displayName'] as String? ?? 'کاربر ایرشوگرام',
        'bio': profile['bio'] as String? ?? '',
        'avatar': profile['photoUrl'] as String? ?? '',
      };
      _following = followingSnapshot.docs.map((doc) => doc.id).toList();
      _loading = false;
    });
  }

  Future<String> _keepFile(XFile picked) async {
    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${directory.path}/irshogram_media');
    if (!await mediaDir.exists()) await mediaDir.create(recursive: true);
    final extension = picked.name.contains('.') ? picked.name.split('.').last : 'bin';
    final destination = File('${mediaDir.path}/${_store.newId()}.$extension');
    await File(picked.path).copy(destination.path);
    return destination.path;
  }

  void _notice(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  Future<void> _chooseMedia({required String kind}) async {
    if (_busy) return;
    try {
      XFile? picked;
      final isVideo = kind == 'reel' || kind == 'storyVideo';
      if (isVideo) {
        picked = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 90));
      } else {
        picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 2400);
      }
      if (picked == null || !mounted) return;
      setState(() => _busy = true);
      final path = await _keepFile(picked);
      if (!mounted) return;
      final now = DateTime.now();
      if (kind == 'post') {
        _captionController.clear();
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (sheetContext) => StatefulBuilder(builder: (sheetContext, refresh) => Padding(
            padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('انتشار پست', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(path), height: 210, fit: BoxFit.cover)),
              const SizedBox(height: 12),
              TextField(controller: _captionController, maxLength: 2200, maxLines: 4, decoration: const InputDecoration(hintText: 'برای این پست توضیحی بنویسید...', border: OutlineInputBorder())),
              FilledButton(onPressed: () async {
                final post = LocalPost(id: _store.newId(), username: _username, caption: _captionController.text.trim(), mediaPath: path, isVideo: false, createdAt: now);
                setState(() => _posts.insert(0, post));
                await _store.savePosts(_posts);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                _notice('پست در همین دستگاه ذخیره شد.');
              }, child: const Text('انتشار')),
            ]),
          )),
        );
      } else if (kind == 'story' || kind == 'storyVideo') {
        final story = LocalStory(id: _store.newId(), username: _username, mediaPath: path, isVideo: isVideo, createdAt: now);
        setState(() => _stories.insert(0, story));
        await _store.saveStories(_stories);
        _notice('استوری به‌صورت محلی اضافه شد.');
      } else {
        _captionController.clear();
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (sheetContext) => Padding(
            padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('انتشار ریلز', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: _captionController, maxLength: 2200, maxLines: 3, decoration: const InputDecoration(hintText: 'توضیح ریلز...', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              FilledButton(onPressed: () async {
                final post = LocalPost(id: _store.newId(), username: _username, caption: _captionController.text.trim(), mediaPath: path, isVideo: true, createdAt: now);
                setState(() => _posts.insert(0, post));
                await _store.savePosts(_posts);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                _notice('ریلز در همین دستگاه ذخیره شد.');
              }, child: const Text('انتشار ریلز')),
            ]),
          ),
        );
      }
    } catch (error) {
      _notice('انتخاب رسانه انجام نشد: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('ایجاد محتوای جدید', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(dense: true, visualDensity: VisualDensity.compact, leading: const Icon(Icons.photo_outlined), title: const Text('ایجاد پست'), onTap: () { Navigator.pop(ctx); OnlinePostComposer.create(context); }),
          ListTile(dense: true, visualDensity: VisualDensity.compact, leading: const Icon(Icons.add_circle_outline), title: const Text('استوری عکس'), onTap: () { Navigator.pop(ctx); _chooseMedia(kind: 'story'); }),
          ListTile(dense: true, visualDensity: VisualDensity.compact, leading: const Icon(Icons.video_camera_back_outlined), title: const Text('استوری ویدیویی'), onTap: () { Navigator.pop(ctx); _chooseMedia(kind: 'storyVideo'); }),
          ListTile(dense: true, visualDensity: VisualDensity.compact, leading: const Icon(Icons.video_library_outlined), title: const Text('ساخت ریلز'), onTap: () { Navigator.pop(ctx); _chooseMedia(kind: 'reel'); }),
        ]),
      )),
    );
  }

  Future<void> _toggleLike(LocalPost post) async {
    final likes = [...post.likes];
    if (likes.contains(_username)) {
      likes.remove(_username);
    } else {
      likes.add(_username);
      if (post.username != _username) _notifications.insert(0, '$_username پست شما را پسندید.');
    }
    setState(() => _posts = _posts.map((p) => p.id == post.id ? p.copyWith(likes: likes) : p).toList());
    await _store.savePosts(_posts);
  }

  Future<void> _toggleSave(LocalPost post) async {
    setState(() => _posts = _posts.map((p) => p.id == post.id ? p.copyWith(savedByMe: !p.savedByMe) : p).toList());
    await _store.savePosts(_posts);
  }

  Future<void> _showComments(LocalPost post) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) {
        final current = _posts.firstWhere((p) => p.id == post.id);
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Center(child: Text('دیدگاه‌ها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            const SizedBox(height: 12),
            if (current.comments.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('هنوز دیدگاهی ثبت نشده است.', textAlign: TextAlign.center)),
            ...current.comments.map((comment) => ListTile(dense: true, leading: const CircleAvatar(child: Icon(Icons.person, size: 18)), title: Text(comment))),
            Row(children: [
              Expanded(child: TextField(controller: controller, maxLength: 2000, decoration: const InputDecoration(hintText: 'دیدگاه بنویسید...', counterText: ''))),
              IconButton(icon: const Icon(Icons.send), onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                final updated = current.copyWith(comments: [...current.comments, '$_username: $text']);
                setState(() => _posts = _posts.map((p) => p.id == post.id ? updated : p).toList());
                await _store.savePosts(_posts);
                controller.clear();
                refresh(() {});
              }),
            ]),
          ]),
        );
      }),
    );
    controller.dispose();
  }

  Future<void> _editProfile() async {
    final name = TextEditingController(text: _profile['name']);
    final username = TextEditingController(text: _profile['username']);
    final bio = TextEditingController(text: _profile['bio']);
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('ویرایش پروفایل'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'نام نمایشی')),
        TextField(controller: username, decoration: const InputDecoration(labelText: 'نام کاربری')),
        TextField(controller: bio, maxLength: 300, maxLines: 3, decoration: const InputDecoration(labelText: 'بیوگرافی')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
        FilledButton(onPressed: () async {
          final u = username.text.trim();
          if (u.length < 3 || !RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(u)) {
            _notice('نام کاربری باید حداقل ۳ حرف و شامل حروف انگلیسی، عدد، نقطه یا زیرخط باشد.');
            return;
          }
          _profile = {'name': name.text.trim(), 'username': u, 'bio': bio.text.trim(), 'avatar': _profile['avatar'] ?? ''};
          await _store.saveProfile(_profile);
          final uid = FirebaseAuth.instance.currentUser!.uid;
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'username': u,
            'displayName': name.text.trim(),
            'bio': bio.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          if (mounted) setState(() {});
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('ذخیره')),
      ],
    ));
    name.dispose();
    username.dispose();
    bio.dispose();
  }

  Future<void> _sendMessage(String peer, String text) async {
    final message = LocalMessage(id: _store.newId(), peer: peer, text: text, sentAt: DateTime.now());
    setState(() => _messages.add(message));
    await _store.saveMessages(_messages);
  }

  Widget _avatar(String label, {double radius = 22, Color? color}) => CircleAvatar(
    radius: radius,
    backgroundColor: color ?? _purple.withValues(alpha: .13),
    child: Text(label.isEmpty ? '?' : label.characters.first.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: color == null ? _purple : Colors.white)),
  );

  Widget _storiesStrip() {
    final mine = _stories.where((s) => s.username == _username).toList();
    final peers = _stories.where((s) => s.username != _username).toList();
    return SizedBox(height: 112, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), children: [
      GestureDetector(onTap: () => _chooseMedia(kind: 'story'), child: SizedBox(width: 76, child: Column(children: [
        Stack(children: [_avatar('شما', radius: 28, color: Theme.of(context).colorScheme.surfaceContainerHighest), const Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 10, backgroundColor: _purple, child: Icon(Icons.add, size: 15, color: Colors.white)))]),
        const SizedBox(height: 5), const Text('داستان شما', style: TextStyle(fontSize: 11)),
      ]))),
      for (final story in [...mine, ...peers]) GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewer(story: story))),
        child: SizedBox(width: 76, child: Column(children: [
          Container(padding: const EdgeInsets.all(2.5), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF8134AF), Color(0xFFE1306C), Color(0xFFFCAF45)])), child: _avatar(story.username, radius: 27)),
          const SizedBox(height: 5), Text(story.username == _username ? 'داستان شما' : story.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
        ])),
      ),
    ]));
  }

  Widget _postCard(LocalPost post) {
    final liked = post.likes.contains(_username);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), child: Row(children: [
        _avatar(post.username, radius: 17), const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(post.username, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _igBlack)),
          Text(_timeAgo(post.createdAt), style: const TextStyle(fontSize: 11, color: _igGrey)),
        ])),
        PopupMenuButton<String>(icon: const Icon(Icons.more_horiz, color: _igBlack), onSelected: (value) async {
          if (value == 'delete' && post.username == _username) {
            setState(() => _posts.removeWhere((p) => p.id == post.id)); await _store.savePosts(_posts);
          } else if (value == 'report') { _notice('گزارش فقط به‌صورت محلی ثبت شد؛ سامانه بررسی گزارش نیازمند سرور است.'); }
        }, itemBuilder: (_) => [
          if (post.username == _username) const PopupMenuItem(value: 'delete', child: Text('حذف پست')),
          const PopupMenuItem(value: 'report', child: Text('گزارش')),
        ]),
      ])),
      AspectRatio(aspectRatio: 1, child: post.isVideo ? LocalVideo(path: post.mediaPath) : Image.file(File(post.mediaPath), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12, child: Center(child: Icon(Icons.broken_image_outlined, size: 48))))),
      Padding(padding: const EdgeInsets.fromLTRB(4, 2, 4, 0), child: Row(children: [
        IconButton(onPressed: () => _toggleLike(post), icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.red : _igBlack, size: 27)),
        IconButton(onPressed: () => _showComments(post), icon: const Icon(Icons.mode_comment_outlined, color: _igBlack, size: 25)),
        IconButton(onPressed: () => _notice('اشتراک‌گذاری عمومی پس از اتصال سرویس فعال می‌شود.'), icon: const Icon(Icons.send_outlined, color: _igBlack, size: 25)),
        const Spacer(), IconButton(onPressed: () => _toggleSave(post), icon: Icon(post.savedByMe ? Icons.bookmark : Icons.bookmark_border, color: _igBlack, size: 26)),
      ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('${post.likes.length} پسند', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _igBlack))),
      if (post.caption.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(14, 5, 14, 12), child: Text.rich(TextSpan(children: [TextSpan(text: '${post.username}  ', style: const TextStyle(fontWeight: FontWeight.w700)), TextSpan(text: post.caption)]))),
      if (post.comments.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12), child: InkWell(onTap: () => _showComments(post), child: Text('مشاهده ${post.comments.length} دیدگاه', style: const TextStyle(color: _igGrey, fontSize: 13)))),
      const Divider(height: 1, color: _igBorder),
    ]);
  }

  Widget _homePage() => Column(children: [
    const OnlineStoriesStrip(),
    const Divider(height: 1, color: _igBorder),
    Expanded(child: OnlineFeedPage(
      onCreatePost: () => OnlinePostComposer.create(context),
    )),
  ]);

  Widget _searchPage() {
    final query = _searchController.text.trim().replaceFirst(RegExp(r'^@'), '');
    final usersQuery = FirebaseFirestore.instance.collection('users')
        .orderBy('username')
        .startAt([query])
        .endAt(['${query}\uf8ff'])
        .limit(30);
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 8), child: SizedBox(height: 40, child: TextField(
        controller: _searchController, onChanged: (_) => setState(() {}),
        decoration: InputDecoration(prefixIcon: const Icon(Icons.search, size: 21), hintText: 'جستجوی افراد', filled: true, fillColor: const Color(0xFFEFEFEF), contentPadding: EdgeInsets.zero, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          suffixIcon: query.isEmpty ? null : IconButton(icon: const Icon(Icons.close), onPressed: () { _searchController.clear(); setState(() {}); })),
      ))),
      Expanded(child: query.isEmpty
        ? const Center(child: Text('برای پیدا کردن حساب‌ها، نام کاربری را جستجو کنید.', style: TextStyle(color: _igGrey)))
        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: usersQuery.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('جستجو با خطا روبه‌رو شد.'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs.where((doc) => doc.id != FirebaseAuth.instance.currentUser!.uid).toList();
              if (docs.isEmpty) return const Center(child: Text('حسابی پیدا نشد.'));
              return ListView(children: docs.map((doc) {
                final data = doc.data();
                final username = data['username'] as String? ?? 'کاربر';
                final name = data['displayName'] as String? ?? '';
                final following = _following.contains(doc.id);
                return ListTile(
                  leading: CircleAvatar(backgroundImage: (data['photoUrl'] as String?)?.isNotEmpty == true
                    ? NetworkImage(data['photoUrl'] as String) : null,
                    child: (data['photoUrl'] as String?)?.isNotEmpty == true ? null : Text(username.isEmpty ? '?' : username[0].toUpperCase())),
                  title: Text(username, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(name.isEmpty ? 'حساب IrShoGram' : name),
                  trailing: SizedBox(height: 32, child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: following ? const Color(0xFFEFEFEF) : const Color(0xFF0095F6), foregroundColor: following ? _igBlack : Colors.white, elevation: 0),
                    onPressed: () async {
                      final ref = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).collection('following').doc(doc.id);
                      try {
                        if (following) {
                          await ref.delete();
                        } else {
                          await ref.set({'createdAt': FieldValue.serverTimestamp(), 'targetUid': doc.id});
                        }
                        if (mounted) setState(() { if (following) { _following.remove(doc.id); } else { _following.add(doc.id); } });
                      } catch (error) { _notice('تغییر دنبال‌کردن انجام نشد: $error'); }
                    },
                    child: Text(following ? 'دنبال می‌کنید' : 'دنبال کردن'),
                  )),
                  onTap: () => _openChat(username),
                );
              }).toList());
            },
          )),
    ]);
  }

  void _openChat(String peer) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LocalChatPage(
      peer: peer,
      initialMessages: _messages.where((m) => m.peer == peer).toList(),
      onSend: (text) => _sendMessage(peer, text),
    )));
  }

  Widget _messagesPage() {
    final peers = _messages.map((m) => m.peer).toSet().toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 8), child: Row(children: [
        Expanded(child: Text(_username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _igBlack))),
        IconButton(onPressed: () => _notice('گفتگوی جدید را از بخش جستجو شروع کنید.'), icon: const Icon(Icons.edit_square, color: _igBlack)),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 10), child: SizedBox(height: 38, child: TextField(
        decoration: InputDecoration(prefixIcon: const Icon(Icons.search, size: 20), hintText: 'جستجو', filled: true, fillColor: const Color(0xFFEFEFEF), contentPadding: EdgeInsets.zero, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
      ))),
      Expanded(child: peers.isEmpty
        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.send_outlined, size: 58, color: _igBlack), SizedBox(height: 12),
            Text('پیام‌هایت را ارسال کن', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 6), Text('به دوستانت پیام خصوصی بده.', style: TextStyle(color: _igGrey)),
          ]))
        : ListView(children: [
            const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 8), child: Text('پیام‌ها', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            for (final peer in peers.reversed) ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              leading: _avatar(peer, radius: 25), title: Text(peer, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_messages.lastWhere((m) => m.peer == peer).text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _igGrey)),
              trailing: const Icon(Icons.camera_alt_outlined, color: _igBlack), onTap: () => _openChat(peer)),
          ])),
    ]);
  }

  Widget _reelsPage() {
    final reels = _posts.where((p) => p.isVideo).toList();
    if (reels.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.video_collection_outlined, size: 62, color: Colors.grey),
      const SizedBox(height: 12),
      const Text('هنوز ریلزی وجود ندارد.'),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: () => _chooseMedia(kind: 'reel'), icon: const Icon(Icons.add), label: const Text('ساخت ریلز')),
      ]));
    }
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: reels.length,
      itemBuilder: (ctx, index) {
        final reel = reels[index];
        return Stack(fit: StackFit.expand, children: [
          LocalVideo(path: reel.mediaPath, autoplay: true),
          DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: .15), Colors.transparent, Colors.black.withValues(alpha: .72)]))),
          Positioned(left: 16, right: 16, bottom: 26, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('@${reel.username}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(reel.caption, style: const TextStyle(color: Colors.white)),
            ])),
            Column(children: [
              IconButton(onPressed: () => _toggleLike(reel), icon: Icon(reel.likes.contains(_username) ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 30)),
              Text('${reel.likes.length}', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 14),
              IconButton(onPressed: () => _showComments(reel), icon: const Icon(Icons.mode_comment_outlined, color: Colors.white, size: 28)),
              Text('${reel.comments.length}', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 14),
              const Icon(Icons.more_horiz, color: Colors.white, size: 28),
            ]),
          ])),
        ]);
      },
    );
  }

  Widget _profilePage() {
    final ownPosts = _posts.where((p) => p.username == _username).toList();
    final saved = _posts.where((p) => p.savedByMe).toList();
    return ListView(padding: EdgeInsets.zero, children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 12), child: Row(children: [
        Text(_username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _igBlack)),
        const Spacer(),
        IconButton(tooltip: 'ایجاد پست', onPressed: _createMenu, icon: const Icon(Icons.add_box_outlined, size: 27, color: _igBlack)),
        PopupMenuButton<String>(icon: const Icon(Icons.menu, size: 27, color: _igBlack), onSelected: (value) {
          if (value == 'saved') Navigator.push(context, MaterialPageRoute(builder: (_) => SavedPostsPage(posts: saved)));
          if (value == 'settings') Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
          if (value == 'accounts') _notice('مدیریت حساب اینترنتی به سرویس احراز هویت نیاز دارد.');
          if (value == 'theme') widget.onThemeChanged(!widget.isDark);
        }, itemBuilder: (_) => [
          const PopupMenuItem(value: 'saved', child: Text('ذخیره‌شده‌ها')),
          const PopupMenuItem(value: 'accounts', child: Text('مدیریت حساب‌ها')),
          const PopupMenuItem(value: 'settings', child: Text('تنظیمات و حریم خصوصی')),
          PopupMenuItem(value: 'theme', child: Text(widget.isDark ? 'حالت روشن' : 'حالت تاریک')),
        ]),
      ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
        _avatar(_username, radius: 42), const SizedBox(width: 25),
        Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _stat(ownPosts.length.toString(), 'پست'), _stat('—', 'دنبال‌کننده'), _stat(_following.length.toString(), 'دنبال‌شونده'),
        ])),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_profile['name'] ?? 'کاربر ایرشوگرام', style: const TextStyle(fontWeight: FontWeight.w700, color: _igBlack)),
        if ((_profile['bio'] ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: Text(_profile['bio']!, style: const TextStyle(color: _igBlack))),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 12), child: Row(children: [
        Expanded(child: SizedBox(height: 34, child: OutlinedButton(onPressed: _editProfile, style: OutlinedButton.styleFrom(foregroundColor: _igBlack, side: const BorderSide(color: _igBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)), padding: EdgeInsets.zero), child: const Text('ویرایش پروفایل', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))))),
        const SizedBox(width: 7),
        Expanded(child: SizedBox(height: 34, child: OutlinedButton(onPressed: () => _notice('اشتراک‌گذاری پروفایل پس از اتصال سرویس فعال می‌شود.'), style: OutlinedButton.styleFrom(foregroundColor: _igBlack, side: const BorderSide(color: _igBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)), padding: EdgeInsets.zero), child: const Text('اشتراک‌گذاری پروفایل', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))))),
      ])),
      SizedBox(height: 94, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), children: [
        Column(children: [
          Container(width: 62, height: 62, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _igBorder)), child: const Center(child: Icon(Icons.add, size: 28, color: _igBlack))),
          const SizedBox(height: 6), const Text('جدید', style: TextStyle(fontSize: 11, color: _igBlack)),
        ]),
      ])),
      const Divider(height: 1, color: _igBorder),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Padding(padding: EdgeInsets.symmetric(vertical: 11), child: Icon(Icons.grid_on_outlined, color: _igBlack, size: 23)),
        Padding(padding: EdgeInsets.symmetric(vertical: 11), child: Icon(Icons.video_library_outlined, color: _igGrey, size: 23)),
        Padding(padding: EdgeInsets.symmetric(vertical: 11), child: Icon(Icons.person_pin_outlined, color: _igGrey, size: 23)),
      ]),
      if (ownPosts.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 45), child: Column(children: [
        Icon(Icons.camera_alt_outlined, size: 45, color: _igBlack), SizedBox(height: 10),
        Text('هنوز پستی منتشر نکرده‌اید.', style: TextStyle(fontWeight: FontWeight.w600, color: _igBlack)),
      ])) else GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: ownPosts.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
        itemBuilder: (_, i) => Stack(fit: StackFit.expand, children: [
          ownPosts[i].isVideo ? Container(color: Colors.black, child: const Icon(Icons.play_arrow, color: Colors.white)) : Image.file(File(ownPosts[i].mediaPath), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
          if (ownPosts[i].isVideo) const Positioned(top: 5, right: 5, child: Icon(Icons.play_arrow, color: Colors.white, size: 18)),
        ]),
      ),
    ]);
  }

  Widget _stat(String number, String label) => Column(children: [Text(number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text(label, style: const TextStyle(fontSize: 12))]);

  void _showNotifications() {
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (ctx) => SafeArea(child: SizedBox(height: 340, child: Column(children: [
      const Padding(padding: EdgeInsets.all(16), child: Text('اعلان‌ها', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
      Expanded(child: _notifications.isEmpty
        ? const Center(child: Text('اعلان تازه‌ای ندارید.'))
        : ListView(children: _notifications.map((n) => ListTile(leading: const Icon(Icons.favorite, color: Colors.pink), title: Text(n))).toList())),
    ]))));
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'همین الان';
    if (diff.inHours < 1) return '${diff.inMinutes} دقیقه پیش';
    if (diff.inDays < 1) return '${diff.inHours} ساعت پیش';
    return '${diff.inDays} روز پیش';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final pages = [_homePage(), _searchPage(), _messagesPage(), _reelsPage(), _profilePage()];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_tab == 0 ? 'IrShoGram' : (_tab == 4 ? _username : const ['IrShoGram', 'جستجو', 'دایرکت', 'ریلز', 'پروفایل'][_tab]),
          style: TextStyle(fontSize: _tab == 0 ? 27 : 19, fontWeight: FontWeight.w800, fontStyle: _tab == 0 ? FontStyle.italic : FontStyle.normal, letterSpacing: _tab == 0 ? -.9 : 0, color: _igBlack)),
        centerTitle: true,
        leading: _tab == 0 ? IconButton(tooltip: 'اعلان‌ها', onPressed: _showNotifications, icon: const Icon(Icons.favorite_border, color: _igBlack, size: 27)) : null,
        actions: _tab == 0 ? [IconButton(tooltip: 'ایجاد', onPressed: () => OnlinePostComposer.create(context), icon: const Icon(Icons.add, size: 29, color: _igBlack))] : null,
      ),
      body: Directionality(textDirection: TextDirection.rtl, child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: SafeArea(top: false, child: Container(
        height: 52,
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: _igBorder, width: .7))),
        child: Row(textDirection: TextDirection.ltr, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _navIcon(0, Icons.home_outlined, Icons.home_filled),
          _navIcon(1, Icons.search, Icons.search),
          _navIcon(2, Icons.send_outlined, Icons.send),
          _navIcon(3, Icons.video_library_outlined, Icons.video_library),
          _navIcon(4, Icons.person_outline, Icons.person),
        ]),
      )),
      floatingActionButton: _busy ? const FloatingActionButton(onPressed: null, child: CircularProgressIndicator()) : null,
    );
  }

  Widget _navIcon(int index, IconData icon, IconData selectedIcon) => IconButton(
    onPressed: () => setState(() => _tab = index),
    tooltip: const ['خانه', 'جستجو', 'دایرکت', 'ریلز', 'پروفایل'][index],
    icon: Icon(_tab == index ? selectedIcon : icon, size: 27, color: _igBlack),
  );

}

class LocalVideo extends StatefulWidget {
  const LocalVideo({super.key, required this.path, this.autoplay = false});
  final String path;
  final bool autoplay;

  @override
  State<LocalVideo> createState() => _LocalVideoState();
}

class _LocalVideoState extends State<LocalVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.file(File(widget.path));
      _controller = controller;
      await controller.initialize();
      controller.setLooping(true);
      if (widget.autoplay) await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const ColoredBox(color: Colors.black, child: Center(child: Icon(Icons.videocam_off_outlined, color: Colors.white, size: 48)));
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return const ColoredBox(color: Colors.black, child: Center(child: CircularProgressIndicator(color: Colors.white)));
    return GestureDetector(
      onTap: () => setState(() => controller.value.isPlaying ? controller.pause() : controller.play()),
      child: Stack(fit: StackFit.expand, alignment: Alignment.center, children: [
        FittedBox(fit: BoxFit.cover, child: SizedBox(width: controller.value.size.width, height: controller.value.size.height, child: VideoPlayer(controller))),
        if (!controller.value.isPlaying) const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 62)),
      ]),
    );
  }
}

class StoryViewer extends StatelessWidget {
  const StoryViewer({super.key, required this.story});
  final LocalStory story;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(child: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Stack(fit: StackFit.expand, children: [
        story.isVideo ? LocalVideo(path: story.mediaPath, autoplay: true) : Image.file(File(story.mediaPath), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white))),
        Positioned(top: 12, left: 12, right: 12, child: Container(height: 3, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
        Positioned(top: 28, right: 14, child: Row(children: [
          CircleAvatar(radius: 17, child: Text(story.username.characters.first.toUpperCase())),
          const SizedBox(width: 8),
          Text(story.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ])),
        const Positioned(top: 28, left: 14, child: Icon(Icons.close, color: Colors.white)),
      ]),
    )),
  );
}

class LocalChatPage extends StatefulWidget {
  const LocalChatPage({super.key, required this.peer, required this.initialMessages, required this.onSend});
  final String peer;
  final List<LocalMessage> initialMessages;
  final Future<void> Function(String) onSend;

  @override
  State<LocalChatPage> createState() => _LocalChatPageState();
}

class _LocalChatPageState extends State<LocalChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<LocalMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.addAll(widget.initialMessages);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await widget.onSend(text);
    if (!mounted) return;
    setState(() => _messages.add(LocalMessage(id: DateTime.now().microsecondsSinceEpoch.toString(), peer: widget.peer, text: text, sentAt: DateTime.now())));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Row(children: [const CircleAvatar(child: Icon(Icons.person)), const SizedBox(width: 10), Text(widget.peer)])),
    body: Column(children: [
      Expanded(child: _messages.isEmpty
        ? const Center(child: Text('هنوز پیامی وجود ندارد.'))
        : ListView(controller: _scroll, padding: const EdgeInsets.all(14), children: _messages.map((m) => Align(alignment: m.mine ? Alignment.centerLeft : Alignment.centerRight, child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12), constraints: const BoxConstraints(maxWidth: 290), decoration: BoxDecoration(color: m.mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)), child: Text(m.text)))).toList())),
      SafeArea(child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: TextField(controller: _controller, maxLength: 5000, decoration: const InputDecoration(counterText: '', hintText: 'پیام بنویسید...', border: OutlineInputBorder()))),
        IconButton(onPressed: _send, icon: const Icon(Icons.send)),
      ]))),
    ]),
  );
}

class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key, required this.posts});
  final List<LocalPost> posts;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ذخیره‌شده‌ها')),
    body: posts.isEmpty ? const Center(child: Text('مورد ذخیره‌شده‌ای وجود ندارد.'))
      : GridView.builder(padding: const EdgeInsets.all(3), itemCount: posts.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3), itemBuilder: (_, i) => posts[i].isVideo ? Container(color: Colors.black, child: const Icon(Icons.play_arrow, color: Colors.white)) : Image.file(File(posts[i].mediaPath), fit: BoxFit.cover)),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  Widget _section(String title, List<Widget> items) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 22, 16, 7), child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _igBlack))),
    ...items,
  ]);
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('تنظیمات و فعالیت‌ها', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
    body: ListView(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'جستجو در تنظیمات', filled: true, fillColor: const Color(0xFFEFEFEF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
      _section('حساب شما', [
        const ListTile(leading: Icon(Icons.account_circle_outlined), title: Text('مرکز حساب‌ها'), subtitle: Text('رمز عبور، امنیت و اطلاعات شخصی'), trailing: Icon(Icons.chevron_right)),
        const ListTile(leading: Icon(Icons.person_outline), title: Text('جزئیات شخصی'), trailing: Icon(Icons.chevron_right)),
        const ListTile(leading: Icon(Icons.lock_outline), title: Text('حریم خصوصی حساب'), subtitle: Text('مدیریت خصوصی یا عمومی بودن حساب'), trailing: Icon(Icons.chevron_right)),
      ]),
      _section('نحوه استفاده از IrShoGram', [
        const ListTile(leading: Icon(Icons.bookmark_border), title: Text('ذخیره‌شده‌ها'), trailing: Icon(Icons.chevron_right)),
        const ListTile(leading: Icon(Icons.archive_outlined), title: Text('بایگانی'), trailing: Icon(Icons.chevron_right)),
        const ListTile(leading: Icon(Icons.access_time), title: Text('فعالیت‌های شما'), trailing: Icon(Icons.chevron_right)),
        const ListTile(leading: Icon(Icons.notifications_none), title: Text('اعلان‌ها'), trailing: Icon(Icons.chevron_right)),
      ]),
      _section('چه کسی می‌تواند محتوای شما را ببیند؟', [
        const ListTile(leading: Icon(Icons.block_outlined), title: Text('مسدودشده‌ها'), trailing: Icon(Icons.chevron_right)),
        const ListTile(leading: Icon(Icons.visibility_outlined), title: Text('مخفی‌کردن استوری و لایو'), trailing: Icon(Icons.chevron_right)),
        const ListTile(leading: Icon(Icons.comment_outlined), title: Text('دیدگاه‌ها'), trailing: Icon(Icons.chevron_right)),
        const ListTile(leading: Icon(Icons.alternate_email), title: Text('برچسب‌ها و اشاره‌ها'), trailing: Icon(Icons.chevron_right)),
      ]),
      _section('بیشتر', [
        const ListTile(leading: Icon(Icons.help_outline), title: Text('راهنما'), trailing: Icon(Icons.chevron_right)),
        const ListTile(leading: Icon(Icons.info_outline), title: Text('درباره IrShoGram'), subtitle: Text('نسخه اولیه محلی؛ قابلیت‌های آنلاین پس از اتصال سرور فعال می‌شوند.')),
      ]),
      const Padding(padding: EdgeInsets.fromLTRB(16, 22, 16, 30), child: Text('IrShoGram', style: TextStyle(color: _igGrey, fontWeight: FontWeight.w600))),
    ]),
  );
}
