import 'package:flutter/material.dart';

void main() => runApp(const IrShoGramApp());

class IrShoGramApp extends StatefulWidget {
  const IrShoGramApp({super.key});
  @override
  State<IrShoGramApp> createState() => _IrShoGramAppState();
}

class _IrShoGramAppState extends State<IrShoGramApp> {
  ThemeMode mode = ThemeMode.light;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'IrShoGram',
    debugShowCheckedModeBanner: false,
    themeMode: mode,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF963BC1)), scaffoldBackgroundColor: Colors.white),
    darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB45BE0), brightness: Brightness.dark)),
    home: MainShell(isDark: mode == ThemeMode.dark, onThemeChanged: (v) => setState(() => mode = v ? ThemeMode.dark : ThemeMode.light)),
  );
}

class DemoPost {
  DemoPost(this.user, this.caption, this.color, this.likes);
  final String user;
  final String caption;
  final Color color;
  int likes;
  bool liked = false;
  bool saved = false;
  final List<String> comments = ['عالیه!', 'چه عکس خوبی'];
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.isDark, required this.onThemeChanged});
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;
  final search = TextEditingController();
  final people = ['علی', 'محمد', 'رضا', 'سارا', 'امیر', 'مریم', 'ندا'];
  final posts = <DemoPost>[
    DemoPost('irshogram_team', 'به ایرشوگرام خوش آمدید؛ اینجا خانه ارتباط و اشتراک‌گذاری است.', const Color(0xFF7651A8), 248),
    DemoPost('ali.photo', 'لحظه‌های خوب را با دوستانتان به اشتراک بگذارید.', const Color(0xFF3B8290), 96),
    DemoPost('travel_daily', 'هر روز یک قاب تازه؛ هر روز یک داستان تازه.', const Color(0xFFB87942), 512),
  ];
  final reelCaptions = ['یک روز تازه، یک شروع تازه', 'لحظه‌های ساده و زیبا', 'اینجا ریلزهای ایرشوگرام است'];
  final reelColors = [const Color(0xFF593D78), const Color(0xFF245F69), const Color(0xFF8A4E37)];

  @override
  void dispose() { search.dispose(); super.dispose(); }

  void info(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  void createContent() {
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (ctx) => SafeArea(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('ایجاد محتوای جدید', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('ایجاد پست'), onTap: () { Navigator.pop(ctx); info('انتخاب عکس و انتشار پست در مرحله اتصال رسانه فعال می‌شود.'); }),
        ListTile(leading: const Icon(Icons.add_circle_outline), title: const Text('ایجاد استوری'), onTap: () { Navigator.pop(ctx); info('ساخت و بارگذاری استوری در مرحله اتصال رسانه فعال می‌شود.'); }),
        ListTile(leading: const Icon(Icons.video_call_outlined), title: const Text('ساخت ریلز'), onTap: () { Navigator.pop(ctx); info('انتخاب ویدیو و انتشار ریلز در مرحله اتصال رسانه فعال می‌شود.'); }),
      ]),
    )));
  }

  void comments(DemoPost post) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Center(child: Text('دیدگاه‌ها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          const SizedBox(height: 12),
          ...post.comments.map((c) => ListTile(dense: true, leading: const CircleAvatar(child: Icon(Icons.person, size: 18)), title: Text(c))),
          Row(children: [
            Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: 'نظر خود را بنویسید...'))),
            IconButton(icon: const Icon(Icons.send), onPressed: () { if (controller.text.trim().isNotEmpty) { setState(() => post.comments.add(controller.text.trim())); refresh(() {}); controller.clear(); } }),
          ]),
        ]),
      )),
    ).whenComplete(controller.dispose);
  }

  void story(String name) => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewer(name: name)));

  Widget storyTile(String name, int index) => GestureDetector(
    onTap: () => index == 0 ? createContent() : story(name),
    child: SizedBox(width: 76, child: Column(children: [
      Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF8B43C6), Color(0xFFE34D82), Color(0xFFFF9A3D)])),
        child: CircleAvatar(radius: 29, child: index == 0 ? const Icon(Icons.add, size: 27) : Text(name.characters.first, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)))),
      const SizedBox(height: 5),
      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
    ])),
  );

  Widget postCard(DemoPost post) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    ListTile(leading: CircleAvatar(backgroundColor: post.color, child: Text(post.user.characters.first, style: const TextStyle(color: Colors.white))),
      title: Text(post.user, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), subtitle: const Text('پیشنهاد برای شما', style: TextStyle(fontSize: 11)),
      trailing: IconButton(icon: const Icon(Icons.more_horiz), onPressed: () => info('گزینه‌های بیشتر به‌زودی اضافه می‌شود.'))),
    Container(height: 300, width: double.infinity, color: post.color, child: Stack(alignment: Alignment.center, children: [
      Icon(Icons.photo_camera_back_outlined, size: 82, color: Colors.white.withValues(alpha: .65)),
      Positioned(bottom: 14, child: Text('IrShoGram', style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 22, fontWeight: FontWeight.bold))),
    ])),
    Row(children: [
      IconButton(onPressed: () => setState(() { post.liked = !post.liked; post.likes += post.liked ? 1 : -1; }), icon: Icon(post.liked ? Icons.favorite : Icons.favorite_border, color: post.liked ? Colors.red : null)),
      IconButton(onPressed: () => comments(post), icon: const Icon(Icons.mode_comment_outlined)),
      IconButton(onPressed: () => info('اشتراک‌گذاری پس از اتصال سرویس فعال می‌شود.'), icon: const Icon(Icons.send_outlined)),
      const Spacer(),
      IconButton(onPressed: () => setState(() => post.saved = !post.saved), icon: Icon(post.saved ? Icons.bookmark : Icons.bookmark_border)),
    ]),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text(post.likes.toString() + ' پسند', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
    Padding(padding: const EdgeInsets.fromLTRB(14, 5, 14, 16), child: Text(post.user + '  ' + post.caption)),
    const Divider(height: 1),
  ]);

  Widget home() => ListView(padding: const EdgeInsets.only(bottom: 18), children: [
    SizedBox(height: 108, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), children: [
      storyTile('داستان شما', 0),
      for (int i = 0; i < people.length; i++) storyTile(people[i], i + 1),
    ])),
    const Divider(height: 1),
    for (final post in posts) postCard(post),
  ]);

  Widget searchPage() {
    final q = search.text.trim().toLowerCase();
    final results = people.where((p) => p.toLowerCase().contains(q)).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: TextField(controller: search, onChanged: (_) => setState(() {}),
        decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'جستجوی افراد', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () { search.clear(); setState(() {}); })))),
      Expanded(child: q.isEmpty ? const Center(child: Text('برای پیدا کردن افراد، نام آن‌ها را جستجو کنید.'))
        : results.isEmpty ? const Center(child: Text('نتیجه‌ای پیدا نشد.'))
        : ListView(children: results.map((p) => ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(p), subtitle: const Text('@user'), trailing: const Icon(Icons.chevron_left))).toList())),
    ]);
  }

  Widget messagesPage() => ListView(children: [
    const Padding(padding: EdgeInsets.fromLTRB(16, 14, 16, 8), child: Text('پیام‌ها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22))),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'جستجو در پیام‌ها', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)))),
    for (final p in people) ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(p), subtitle: const Text('برای شروع گفتگو لمس کنید'),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(name: p)))),
  ]);

  Widget reelsPage() => PageView.builder(scrollDirection: Axis.vertical, itemCount: reelCaptions.length, itemBuilder: (ctx, i) => Container(color: reelColors[i], child: Stack(children: [
    const Center(child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 90)),
    Positioned(left: 18, right: 18, bottom: 28, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('@irshogram', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(reelCaptions[i], style: const TextStyle(color: Colors.white, fontSize: 14)),
        const SizedBox(height: 8),
        const Text('ویدیوهای نمونه؛ پخش و بارگذاری پس از اتصال رسانه فعال می‌شود.', style: TextStyle(color: Colors.white70, fontSize: 11)),
      ])),
      Column(children: [
        IconButton(onPressed: () => info('پسندیدن ریلز پس از اتصال حساب کاربری ذخیره می‌شود.'), icon: const Icon(Icons.favorite_border, color: Colors.white, size: 30)),
        const Text('پسند', style: TextStyle(color: Colors.white, fontSize: 11)),
        const SizedBox(height: 14),
        IconButton(onPressed: () => info('دیدگاه‌های ریلز به‌زودی فعال می‌شود.'), icon: const Icon(Icons.mode_comment_outlined, color: Colors.white, size: 28)),
        const Text('دیدگاه', style: TextStyle(color: Colors.white, fontSize: 11)),
        const SizedBox(height: 14),
        const Icon(Icons.send_outlined, color: Colors.white, size: 27),
      ]),
    ])),
  ])));

  Widget profilePage() => ListView(padding: const EdgeInsets.all(16), children: [
    Row(children: [
      const CircleAvatar(radius: 39, child: Icon(Icons.person, size: 42)),
      const SizedBox(width: 28),
      const Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        ProfileStat(number: '0', label: 'پست'), ProfileStat(number: '0', label: 'دنبال‌کننده'), ProfileStat(number: '0', label: 'دنبال‌شونده'),
      ])),
    ]),
    const SizedBox(height: 14),
    const Text('کاربر ایرشوگرام', style: TextStyle(fontWeight: FontWeight.bold)),
    const Text('به صفحه من خوش آمدید.'),
    const SizedBox(height: 16),
    OutlinedButton(onPressed: () => info('ویرایش پروفایل پس از راه‌اندازی حساب فعال می‌شود.'), child: const Text('ویرایش پروفایل')),
    const Divider(height: 30),
    ListTile(leading: const Icon(Icons.person_add_alt), title: const Text('افزودن یا تغییر حساب'), subtitle: const Text('پشتیبانی چندحسابی در مرحله احراز هویت پیاده‌سازی می‌شود.'), onTap: () => info('برای چندحسابی ابتدا باید سیستم ورود و سرور کاربران راه‌اندازی شود.')),
    SwitchListTile(value: widget.isDark, onChanged: widget.onThemeChanged, secondary: const Icon(Icons.dark_mode_outlined), title: const Text('حالت تاریک')),
    ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('تنظیمات'), onTap: () => info('تنظیمات حساب و حریم خصوصی در مرحله بعد اضافه می‌شود.')),
  ]);

  @override
  Widget build(BuildContext context) {
    const titles = ['IrShoGram', 'جستجو', 'دایرکت', 'ریلز', 'پروفایل'];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(titles[tab], style: TextStyle(fontSize: tab == 0 ? 27 : 20, fontWeight: FontWeight.w800, fontStyle: tab == 0 ? FontStyle.italic : FontStyle.normal, letterSpacing: tab == 0 ? -.8 : 0)),
        centerTitle: true,
        leading: tab == 0 ? IconButton(tooltip: 'اعلان‌ها', onPressed: () => info('فعلاً اعلان جدیدی ندارید.'), icon: const Icon(Icons.favorite_border)) : null,
        actions: tab == 0 ? [IconButton(tooltip: 'ایجاد', onPressed: createContent, icon: const Icon(Icons.add, size: 30))] : null,
      ),
      body: Directionality(
        // Keep Persian page content right-to-left without changing the
        // left/right placement of the header actions or bottom navigation.
        textDirection: TextDirection.rtl,
        child: IndexedStack(index: tab, children: [home(), searchPage(), messagesPage(), reelsPage(), profilePage()]),
      ),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
        NavigationDestination(icon: Icon(Icons.search), label: 'جستجو'),
        NavigationDestination(icon: Icon(Icons.send_outlined), selectedIcon: Icon(Icons.send), label: 'دایرکت'),
        NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library), label: 'ریلز'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'پروفایل'),
      ]),
    );
  }
}

class ProfileStat extends StatelessWidget {
  const ProfileStat({super.key, required this.number, required this.label});
  final String number;
  final String label;
  @override
  Widget build(BuildContext context) => Column(children: [Text(number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), Text(label, style: const TextStyle(fontSize: 11))]);
}

class StoryViewer extends StatelessWidget {
  const StoryViewer({super.key, required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.black, body: SafeArea(child: GestureDetector(onTap: () => Navigator.pop(context), child: Stack(children: [
    Center(child: Text('استوری ' + name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
    Positioned(top: 12, left: 12, right: 12, child: Container(height: 3, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
    Positioned(top: 32, left: 12, child: Row(children: [CircleAvatar(radius: 17, child: Text(name.characters.first)), const SizedBox(width: 8), Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
    const Positioned(top: 28, right: 12, child: Icon(Icons.close, color: Colors.white)),
  ]))));
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.name});
  final String name;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final messages = <String>[];
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Row(children: [const CircleAvatar(child: Icon(Icons.person)), const SizedBox(width: 10), Text(widget.name)])),
    body: Column(children: [
      Expanded(child: messages.isEmpty ? const Center(child: Text('هنوز پیامی وجود ندارد.')) : ListView(padding: const EdgeInsets.all(12), children: messages.map((m) => Align(alignment: Alignment.centerRight, child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Text(m)))).toList())),
      SafeArea(child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: 'پیام بنویسید...', border: OutlineInputBorder()))),
        IconButton(icon: const Icon(Icons.send), onPressed: () { if (controller.text.trim().isNotEmpty) setState(() { messages.add(controller.text.trim()); controller.clear(); }); }),
      ]))),
    ]),
  );
}
