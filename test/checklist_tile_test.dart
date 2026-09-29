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
}
