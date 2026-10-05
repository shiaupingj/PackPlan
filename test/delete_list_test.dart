import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/app/pack_plan_app.dart';
import 'package:packplan/data/pack_list_repository.dart';
import 'package:packplan/widgets/pack_list_card.dart';

void main() {
  Future<InMemoryPackListRepository> pumpApp(WidgetTester tester) async {
    final repository = InMemoryPackListRepository();
    await tester.pumpWidget(PackPlanApp(repository: repository));
    await tester.pumpAndSettle();
    return repository;
  }

  Future<void> openCardMenu(WidgetTester tester, String title) async {
    final card = find.ancestor(
      of: find.text(title),
      matching: find.byType(PackListCard),
    );
    await tester.tap(
      find.descendant(of: card, matching: find.byTooltip('清單操作')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('首頁卡片右上「⋯」:取消保留,確認後刪除', (tester) async {
    final repository = await pumpApp(tester);
    final before = repository.lists.length;

    await openCardMenu(tester, '登山計劃');
    expect(find.text('清單操作'), findsWidgets);
    await tester.tap(find.text('刪除清單'));
    await tester.pumpAndSettle();
    expect(find.text('「登山計劃」刪除後無法復原。'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('登山計劃'), findsOneWidget);
    expect(repository.lists.length, before);

    await openCardMenu(tester, '登山計劃');
    await tester.tap(find.text('刪除清單'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '刪除'));
    await tester.pumpAndSettle();
    expect(find.text('登山計劃'), findsNothing);
    expect(find.text('清單已刪除'), findsOneWidget);
    expect(repository.lists.length, before - 1);
  });

  testWidgets('2 欄排列後不再支援滑動刪除', (tester) async {
    await pumpApp(tester);

    expect(find.byType(Dismissible), findsNothing);
    await tester.drag(find.text('登山計劃'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('刪除清單？'), findsNothing);
    expect(find.text('登山計劃'), findsOneWidget);
  });

  testWidgets('清單內頁「⋯」選單含分享、重新命名、刪除清單', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('分享'), findsNothing);
    expect(find.byTooltip('重新命名'), findsNothing);
    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();
    expect(find.text('分享'), findsOneWidget);
    expect(find.text('重新命名'), findsOneWidget);
    expect(find.text('刪除清單'), findsOneWidget);

    await tester.tap(find.text('重新命名'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '雪山');
    await tester.tap(find.widgetWithText(FilledButton, '儲存'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '雪山'), findsOneWidget);
  });

  testWidgets('清單內頁「⋯」刪除:確認後回首頁且清單消失', (tester) async {
    final repository = await pumpApp(tester);
    final before = repository.lists.length;
    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('刪除清單'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '登山計劃'), findsOneWidget);

    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('刪除清單'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '刪除'));
    await tester.pumpAndSettle();

    expect(find.text('打包清單'), findsOneWidget, reason: '回到首頁');
    expect(find.text('登山計劃'), findsNothing);
    expect(find.text('找不到這份清單'), findsNothing);
    expect(find.text('清單已刪除'), findsOneWidget);
    expect(repository.lists.length, before - 1);
  });
}
