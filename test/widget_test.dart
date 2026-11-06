import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:irshogram/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('IrShoGram navigation renders', (tester) async {
    await tester.pumpWidget(const IrShoGramApp());
    await tester.pumpAndSettle();
    expect(find.text('IrShoGram'), findsOneWidget);
    expect(find.text('هنوز پستی منتشر نشده است.'), findsOneWidget);
    expect(find.text('خانه'), findsOneWidget);
    expect(find.text('جستجو'), findsWidgets);
    expect(find.text('دایرکت'), findsOneWidget);
    expect(find.text('ریلز'), findsOneWidget);
    expect(find.text('پروفایل'), findsOneWidget);
    await tester.tap(find.byTooltip('ایجاد'));
    await tester.pumpAndSettle();
    expect(find.text('ایجاد محتوای جدید'), findsOneWidget);
    expect(find.text('ایجاد پست'), findsWidgets);
    expect(find.text('افزودن استوری'), findsOneWidget);
  });
}
