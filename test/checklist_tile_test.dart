import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/theme/app_theme.dart';
import 'package:packplan/widgets/checklist_tile.dart';

void main() {
  testWidgets('名稱過長時只顯示一行並以 … 截斷,重量與 ☁ 仍完整顯示', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SizedBox(
            width: 280,
            child: ChecklistTile(
              label: '虎牌 迷你型旋蓋式保溫保冷杯 MOA-A012 超長名稱測試',
              weightGram: 73,
              weightLabel: '73 g',
              weightTooltip: '線上參考值',
              checked: false,
            ),
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(
      find.byKey(const ValueKey('checklist-tile-label')),
    );
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);

    final tile = tester.getRect(find.byType(ChecklistTile));
    final weight = tester.getRect(find.text('73 g'));
    final cloud = tester.getRect(
      find.byKey(const ValueKey('weight-online-icon')),
    );
    // 重量與 ☁ 在同一行、都在列的範圍內,沒有被擠出去
    expect(weight.right, lessThanOrEqualTo(tile.right));
    expect(cloud.right, lessThanOrEqualTo(tile.right));
    expect(
      (weight.center.dy -
              tester
                  .getCenter(find.byKey(const ValueKey('checklist-tile-label')))
                  .dy)
          .abs(),
      lessThan(4),
    );
  });

  testWidgets('有備註時名稱列最後顯示 (i),點了才顯示備註、不會開啟編輯', (tester) async {
    var edits = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: ChecklistTile(
              label: '虎牌 迷你型旋蓋式保溫保冷杯 MOA-A012 超長名稱測試',
              weightGram: 73,
              weightLabel: '73 g',
              note: '雨套收在頂袋',
              checked: false,
              onEdit: () => edits++,
            ),
          ),
        ),
      ),
    );

    final info = find.byKey(const ValueKey('checklist-tile-note'));
    expect(info, findsOneWidget);
    expect(find.text('雨套收在頂袋'), findsNothing);
    // 名稱過長被截斷時,(i) 仍在列的範圍內
    expect(
      tester.getRect(info).right,
      lessThanOrEqualTo(tester.getRect(find.byType(ChecklistTile)).right),
    );

    await tester.tap(info);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('雨套收在頂袋'), findsOneWidget);
    expect(edits, 0);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('沒有備註時不顯示 (i)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ChecklistTile(label: '水壺', weightGram: 500, checked: false),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('checklist-tile-note')), findsNothing);
  });
}
