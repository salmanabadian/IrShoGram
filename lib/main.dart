// ignore_for_file: unnecessary_underscores

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'services/local_social_store.dart';

void main() => runApp(const IrShoGramApp());

const _purple = Color(0xFF8E3DB8);
const _people = <String>['ali.photo', 'mohammad', 'reza_daily', 'sara.art', 'amir', 'maryam'];

class IrShoGramApp extends StatefulWidget {
  const IrShoGramApp({super.key});

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
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _purple, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFAFAFA), surfaceTintColor: Colors.transparent),
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB65CDE), brightness: Brightness.dark),
    ),
    home: MainShell(
      isDark: _mode == ThemeMode.dark,
      onThemeChanged: (dark) => setState(() => _mode = dark ? ThemeMode.dark : ThemeMode.light),
    ),
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
          ListTile(leading: const Icon(Icons.photo_outlined), title: const Text('ایجاد پست'), onTap: () { Navigator.pop(ctx); _chooseMedia(kind: 'post'); }),
          ListTile(leading: const Icon(Icons.add_circle_outline), title: const Text('استوری عکس'), onTap: () { Navigator.pop(ctx); _chooseMedia(kind: 'story'); }),
          ListTile(leading: const Icon(Icons.video_camera_back_outlined), title: const Text('استوری ویدیویی'), onTap: () { Navigator.pop(ctx); _chooseMedia(kind: 'storyVideo'); }),
          ListTile(leading: const Icon(Icons.video_library_outlined), title: const Text('ساخت ریلز'), onTap: () { Navigator.pop(ctx); _chooseMedia(kind: 'reel'); }),
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
    return SizedBox(height: 112, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), children: [
      GestureDetector(onTap: () => _chooseMedia(kind: 'story'), child: SizedBox(width: 76, child: Column(children: [
        Stack(children: [_avatar('شما', radius: 30, color: Theme.of(context).colorScheme.surfaceContainerHighest), const Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 10, backgroundColor: _purple, child: Icon(Icons.add, size: 15, color: Colors.white)))]),
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
      ListTile(
        leading: _avatar(post.username),
        title: Text(post.username, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(_timeAgo(post.createdAt), style: const TextStyle(fontSize: 11)),
        trailing: PopupMenuButton<String>(onSelected: (value) async {
          if (value == 'delete' && post.username == _username) {
            setState(() => _posts.removeWhere((p) => p.id == post.id));
            await _store.savePosts(_posts);
          } else if (value == 'report') {
            _notice('گزارش فقط به‌صورت محلی ثبت شد؛ سامانه بررسی گزارش نیازمند سرور است.');
          }
        }, itemBuilder: (_) => [
          if (post.username == _username) const PopupMenuItem(value: 'delete', child: Text('حذف پست')),
          const PopupMenuItem(value: 'report', child: Text('گزارش')),
        ]),
      ),
      AspectRatio(aspectRatio: 1, child: post.isVideo
        ? LocalVideo(path: post.mediaPath)
        : Image.file(File(post.mediaPath), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12, child: Center(child: Icon(Icons.broken_image_outlined, size: 48))))),
      Row(children: [
        IconButton(onPressed: () => _toggleLike(post), icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.red : null)),
        IconButton(onPressed: () => _showComments(post), icon: const Icon(Icons.mode_comment_outlined)),
        IconButton(onPressed: () => _notice('اشتراک‌گذاری عمومی پس از اتصال سرویس فعال می‌شود.'), icon: const Icon(Icons.send_outlined)),
        const Spacer(),
        IconButton(onPressed: () => _toggleSave(post), icon: Icon(post.savedByMe ? Icons.bookmark : Icons.bookmark_border)),
      ]),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('${post.likes.length} پسند', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      if (post.caption.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(14, 5, 14, 14), child: Text.rich(TextSpan(children: [TextSpan(text: '${post.username}  ', style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: post.caption)]))),
      if (post.comments.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12), child: InkWell(onTap: () => _showComments(post), child: Text('مشاهده ${post.comments.length} دیدگاه', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)))),
      const Divider(height: 1),
    ]);
  }

  Widget _homePage() => _posts.isEmpty
    ? ListView(children: [
        _storiesStrip(),
        const SizedBox(height: 50),
        const Icon(Icons.photo_library_outlined, size: 58, color: Colors.grey),
        const SizedBox(height: 12),
        const Center(child: Text('هنوز پستی منتشر نشده است.', style: TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(height: 6),
        const Center(child: Text('اولین عکس یا ویدیوی خود را به اشتراک بگذارید.')),
        const SizedBox(height: 14),
        Center(child: FilledButton.icon(onPressed: _createMenu, icon: const Icon(Icons.add), label: const Text('ایجاد پست'))),
      ])
    : ListView(padding: const EdgeInsets.only(bottom: 18), children: [
        _storiesStrip(),
        const Divider(height: 1),
        for (final post in _posts) _postCard(post),
      ]);

  Widget _searchPage() {
    final query = _searchController.text.trim().toLowerCase();
    final results = _people.where((name) => name.toLowerCase().contains(query)).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'جستجوی نام کاربری', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () { _searchController.clear(); setState(() {}); })),
      )),
      Expanded(child: query.isEmpty
        ? const Center(child: Text('برای جستجو، نام کاربری را وارد کنید.'))
        : results.isEmpty ? const Center(child: Text('نتیجه‌ای پیدا نشد.'))
        : ListView(children: results.map((name) => ListTile(
            leading: _avatar(name),
            title: Text(name),
            subtitle: const Text('حساب نمونه محلی'),
            trailing: FilledButton.tonal(
              onPressed: () async {
                setState(() => _following.contains(name) ? _following.remove(name) : _following.add(name));
                await _store.saveFollowing(_following);
              },
              child: Text(_following.contains(name) ? 'دنبال می‌کنید' : 'دنبال کردن'),
            ),
            onTap: () => _openChat(name),
          )).toList())),
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
    return ListView(children: [
      const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('پیام‌ها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'جستجو در گفتگوها', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)))),
      if (peers.isEmpty) const Padding(padding: EdgeInsets.all(45), child: Column(children: [Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey), SizedBox(height: 12), Text('هنوز گفتگویی ندارید.'), Text('از بخش جستجو یک گفتگو را شروع کنید.', style: TextStyle(color: Colors.grey))])),
      for (final peer in peers.reversed) ListTile(
        leading: _avatar(peer),
        title: Text(peer),
        subtitle: Text(_messages.lastWhere((m) => m.peer == peer).text, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () => _openChat(peer),
      ),
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
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        _avatar(_username, radius: 42),
        const SizedBox(width: 24),
        Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _stat(ownPosts.length.toString(), 'پست'),
          _stat('—', 'دنبال‌کننده'),
          _stat(_following.length.toString(), 'دنبال‌شونده'),
        ])),
      ]),
      const SizedBox(height: 14),
      Text(_profile['name'] ?? 'کاربر ایرشوگرام', style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(_profile['bio'] ?? '', maxLines: 4),
      const SizedBox(height: 14),
      OutlinedButton(onPressed: _editProfile, child: const Text('ویرایش پروفایل')),
      const Divider(height: 28),
      ListTile(leading: const Icon(Icons.bookmark_border), title: const Text('ذخیره‌شده‌ها'), trailing: Text(saved.length.toString()), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SavedPostsPage(posts: saved)))),
      ListTile(leading: const Icon(Icons.person_add_alt), title: const Text('مدیریت حساب‌ها'), subtitle: const Text('حساب محلی این دستگاه؛ ورود چندکاربره پس از اتصال سرور'), onTap: () => _notice('مدیریت حساب اینترنتی به سرویس احراز هویت نیاز دارد.')),
      SwitchListTile(value: widget.isDark, onChanged: widget.onThemeChanged, secondary: const Icon(Icons.dark_mode_outlined), title: const Text('حالت تاریک')),
      ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('تنظیمات و حریم خصوصی'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
      const SizedBox(height: 12),
      const Text('پست‌های من', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      if (ownPosts.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('هنوز پستی منتشر نکرده‌اید.'))),
      if (ownPosts.isNotEmpty) GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ownPosts.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3),
        itemBuilder: (_, i) => ownPosts[i].isVideo
          ? Container(color: Colors.black, child: const Icon(Icons.play_arrow, color: Colors.white))
          : Image.file(File(ownPosts[i].mediaPath), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
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
    const titles = ['IrShoGram', 'جستجو', 'دایرکت', 'ریلز', 'پروفایل'];
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final pages = [_homePage(), _searchPage(), _messagesPage(), _reelsPage(), _profilePage()];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(titles[_tab], style: TextStyle(fontSize: _tab == 0 ? 27 : 20, fontWeight: FontWeight.w800, fontStyle: _tab == 0 ? FontStyle.italic : FontStyle.normal, letterSpacing: _tab == 0 ? -.8 : 0)),
        centerTitle: true,
        leading: _tab == 0 ? IconButton(tooltip: 'اعلان‌ها', onPressed: _showNotifications, icon: const Icon(Icons.favorite_border)) : null,
        actions: _tab == 0 ? [IconButton(tooltip: 'ایجاد', onPressed: _createMenu, icon: const Icon(Icons.add, size: 30))] : null,
      ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.search), label: 'جستجو'),
          NavigationDestination(icon: Icon(Icons.send_outlined), selectedIcon: Icon(Icons.send), label: 'دایرکت'),
          NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library), label: 'ریلز'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'پروفایل'),
        ],
      ),
      floatingActionButton: _busy ? const FloatingActionButton(onPressed: null, child: CircularProgressIndicator()) : null,
    ));
  }
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تنظیمات و حریم خصوصی')),
    body: ListView(children: const [
      ListTile(leading: Icon(Icons.lock_outline), title: Text('حریم خصوصی حساب'), subtitle: Text('تنظیمات حریم خصوصی ابری پس از اتصال حساب فعال می‌شود.')),
      ListTile(leading: Icon(Icons.notifications_outlined), title: Text('اعلان‌ها'), subtitle: Text('اعلان‌های دستگاهی در نسخه متصل قابل تنظیم خواهند بود.')),
      ListTile(leading: Icon(Icons.block_outlined), title: Text('حساب‌های مسدودشده')),
      ListTile(leading: Icon(Icons.info_outline), title: Text('درباره IrShoGram'), subtitle: Text('نسخه اولیه محلی؛ همگام‌سازی آنلاین هنوز فعال نیست.')),
    ]),
  );
}
