import 'package:flutter/material.dart';
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
    expect(find.byWidgetPredicate((widget) => widget is Directionality && widget.textDirection == TextDirection.rtl), findsWidgets);

    await tester.tap(find.byTooltip('ایجاد'));
    await tester.pumpAndSettle();
    expect(find.text('ایجاد محتوای جدید'), findsOneWidget);
    await tester.tap(find.text('ساخت ریلز'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('جستجو').last);
    await tester.pumpAndSettle();
    expect(find.text('برای پیدا کردن افراد، نام آن‌ها را جستجو کنید.'), findsOneWidget);

    await tester.tap(find.text('دایرکت').last);
    await tester.pumpAndSettle();
    expect(find.text('پیام‌ها'), findsOneWidget);
  });
}
