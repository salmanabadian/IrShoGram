import 'package:flutter_test/flutter_test.dart';
import 'package:irshogram/main.dart';

void main() {
  testWidgets('IrShoGram home screen and navigation render', (tester) async {
    await tester.pumpWidget(const IrShoGramApp());

    expect(find.text('irshogram_team'), findsOneWidget);
    expect(find.text('خانه'), findsOneWidget);
    expect(find.text('جستجو'), findsWidgets);
    expect(find.text('دایرکت'), findsWidgets);
    expect(find.text('ریلز'), findsOneWidget);
    expect(find.text('پروفایل'), findsOneWidget);

    await tester.tap(find.text('جستجو').last);
    await tester.pumpAndSettle();
    expect(find.text('برای پیدا کردن افراد، نام آن‌ها را جستجو کنید.'), findsOneWidget);

    await tester.tap(find.text('دایرکت').last);
    await tester.pumpAndSettle();
    expect(find.text('پیام‌ها'), findsOneWidget);
  });
}
