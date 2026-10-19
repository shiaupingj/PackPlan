import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/app/app_shell.dart';
import 'package:packplan/app/pack_plan_app.dart';
import 'package:packplan/widgets/content_width_limit.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const PackPlanApp());
    await tester.pumpAndSettle();
  }

  testWidgets('iPad 橫向:App 置中限寬,MediaQuery 寬度跟著改成欄寬', (tester) async {
    await pumpAt(tester, const Size(1376, 1032));

    final shell = find.byType(AppShell);
    expect(tester.getSize(shell).width, ContentWidthLimit.maxWidth);
    expect(tester.getCenter(shell).dx, 1376 / 2);
    expect(
      MediaQuery.sizeOf(tester.element(shell)).width,
      ContentWidthLimit.maxWidth,
    );
  });

  testWidgets('手機寬度不受影響', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    expect(tester.getSize(find.byType(AppShell)).width, 390);
  });

  testWidgets('切到設定頁,內容也在中間這一欄裡', (tester) async {
    await pumpAt(tester, const Size(1376, 1032));

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('匯入備份'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final column = tester.getRect(find.byType(AppShell));
    final settingsList = tester.getRect(find.byType(ListView).first);
    expect(column.contains(settingsList.center), isTrue);
    expect(settingsList.width, lessThanOrEqualTo(ContentWidthLimit.maxWidth));
  });
}
