import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packplan/theme/app_colors.dart';
import 'package:packplan/widgets/app_snack_bar.dart';

void main() {
  Future<void> show(WidgetTester tester, SnackBar snackBar) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  ScaffoldMessenger.of(context).showSnackBar(snackBar),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pump();
  }

  testWidgets('成功訊息:橘底黑字加打勾', (tester) async {
    await show(tester, appSnackBar('已備份到 iCloud'));

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, AppColors.orange300);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('已備份到 iCloud')).style?.color,
      AppColors.ink,
    );
  });

  testWidgets('錯誤訊息:紅底白字加驚嘆號', (tester) async {
    await show(
      tester,
      appSnackBar('無法刪除 iCloud 備份，請稍後再試', tone: AppSnackTone.error),
    );

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, AppColors.weightOver);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('無法刪除 iCloud 備份，請稍後再試')).style?.color,
      Colors.white,
    );
  });
}
