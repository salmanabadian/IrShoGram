
import 'package:flutter/material.dart';

void main() {
  runApp(const IrShoGram());
}

class IrShoGram extends StatefulWidget {
  const IrShoGram({super.key});

  @override
  State<IrShoGram> createState() => _IrShoGramState();
}

class _IrShoGramState extends State<IrShoGram> {
  int themeIndex = 0;

  final List<Color> colors = [
    Colors.white,
    const Color(0xFF121212),
    const Color(0xFF241044),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = themeIndex != 0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IrShoGram',
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: colors[themeIndex],
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeIndex == 2
              ? const Color(0xFFB000FF)
              : Colors.deepPurple,
          brightness: dark ? Brightness.dark : Brightness.light,
        ),
      ),
      home: HomePage(
        themeIndex: themeIndex,
        onThemeChanged: (value) {
          setState(() => themeIndex = value);
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final int themeIndex;
  final ValueChanged<int> onThemeChanged;

  const HomePage({
    super.key,
    required this.themeIndex,
    required this.onThemeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<String> names = [
    'استوری شما',
    'علی',
    'محمد',
    'رضا',
    'سارا',
    'امیر',
    'مریم',
  ];

  void showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ایجاد محتوای جدید'),
        content: const Text('چه چیزی می‌خواهید منتشر کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('پست'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('استوری'),
          ),
        ],
      ),
    );
  }

  Widget storyItem(String name, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Colors.purple,
                  Colors.pink,
                  Colors.orange,
                ],
              ),
            ),
            child: CircleAvatar(
              radius: 29,
              backgroundColor: Colors.grey.shade700,
              child: index == 0
                  ? const Icon(Icons.add, size: 28)
                  : Text(
                      name[0],
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 5),
          Text(name, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget postCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: const Text(
              'irshogram_user',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('پیشنهاد برای شما'),
            trailing: const Icon(Icons.more_vert),
          ),
          Container(
            height: 260,
            width: double.infinity,
            color: Colors.grey.shade800,
            child: const Icon(
              Icons.image_outlined,
              size: 75,
              color: Colors.white70,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.favorite_border),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.mode_comment_outlined),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.send_outlined),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.bookmark_border),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text('خوش آمدید به ایرشوگرام'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget profilePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 42,
            child: Icon(Icons.person, size: 45),
          ),
          const SizedBox(height: 15),
          const Text(
            'پروفایل من',
            style: TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 25),
          const Text('انتخاب رنگ برنامه'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              themeButton('سفید', 0, Colors.white),
              themeButton('مشکی', 1, Colors.black),
              themeButton('بنفش نئونی', 2, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget themeButton(String title, int index, Color color) {
    return OutlinedButton(
      onPressed: () => widget.onThemeChanged(index),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 7, backgroundColor: color),
          const SizedBox(width: 5),
          Text(title),
          if (widget.themeIndex == index)
            const Icon(Icons.check, size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ListView(
        padding: const EdgeInsets.only(top: 10),
        children: [
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (int i = 0; i < names.length; i++)
                  storyItem(names[i], i),
              ],
            ),
          ),
          const Divider(),
          postCard(),
          postCard(),
        ],
      ),
      const Center(child: Text('جستجو')),
      const Center(child: Text('پیام‌های دایرکت')),
      const Center(child: Text('ویدیوهای ریلز')),
      profilePage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (selectedIndex == 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const AlertDialog(
                            title: Text('اعلان‌ها'),
                            content: Text('فعلاً اعلانی ندارید.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.favorite_border),
                    ),
                    const Spacer(),
                    const Text(
                      'IrShoGram',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: showCreateDialog,
                      icon: const Icon(Icons.add, size: 30),
                    ),
                  ],
                ),
              ),
            Expanded(child: pages[selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'خانه',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'جستجو',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send_outlined),
            label: 'دایرکت',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library_outlined),
            label: 'ریلز',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'پروفایل',
          ),
        ],
      ),
    );
  }
}
