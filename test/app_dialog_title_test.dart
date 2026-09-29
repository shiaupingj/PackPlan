import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/theme/app_theme.dart';
import 'package:packplan/widgets/app_dialog_title.dart';

void main() {
  Future<void> openDialog(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<String>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                titlePadding: AppDialogTitle.padding,
                title: const AppDialogTitle('編輯項目'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop('saved'),
                    child: const Text('儲存'),
                  ),
                ],
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: mode, value: theme) in {
    'light': AppTheme.light,
    'dark': AppTheme.dark,
  }.entries) {
    testWidgets('$mode 模式對話框標題使用主要文字色', (tester) async {
      await openDialog(tester, theme);

      final paragraph = tester.renderObject<RenderParagraph>(find.text('編輯項目'));
      final color = (paragraph.text as TextSpan).style?.color;
      expect(color, isNotNull);
      expect(color, isNot(theme.dialogTheme.backgroundColor));
    });
  }

  testWidgets('點右上角 × 關閉對話框,結果為 null(同取消)', (tester) async {
    String? result = 'not closed';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<String>(
                context: context,
                builder: (_) => const AlertDialog(
                  titlePadding: AppDialogTitle.padding,
                  title: AppDialogTitle('編輯項目'),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('編輯項目'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dialog-close')));
    await tester.pumpAndSettle();

    expect(find.text('編輯項目'), findsNothing);
    expect(result, isNull);
  });
}
