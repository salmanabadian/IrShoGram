import 'package:material_ui/material_ui.dart';

class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استوری‌ها'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'به بخش استوری ایرشوگرام خوش آمدید',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
