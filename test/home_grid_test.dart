import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/app/pack_plan_app.dart';
import 'package:packplan/data/pack_list_repository.dart';
import 'package:packplan/widgets/pack_list_card.dart';

void main() {
  /// iPhone SE 寬度,最窄的情況。
  void useNarrowPhone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(320, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('首頁卡片 2 欄並排,摘要不含天氣', (tester) async {
    useNarrowPhone(tester);
    await tester.pumpWidget(
      PackPlanApp(repository: InMemoryPackListRepository()),
    );
    await tester.pumpAndSettle();

    final cards = find.byType(PackListCard);
    expect(cards, findsAtLeastNWidgets(2));
    final first = tester.getRect(cards.at(0));
    final second = tester.getRect(cards.at(1));
    expect(second.top, first.top, reason: '同一列');
    expect(second.left, greaterThan(first.right));
    expect(find.textContaining('雨天'), findsNothing);
    expect(find.text('登山 · 3天2夜'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('名稱過長單行截斷,不撐高卡片也不溢出', (tester) async {
    useNarrowPhone(tester);
    final repository = InMemoryPackListRepository();
    repository.renameList(repository.lists.first.id, '超級無敵長的三天兩夜雪山主峰東峰縱走行程清單');
    await tester.pumpWidget(PackPlanApp(repository: repository));
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(find.text('超級無敵長的三天兩夜雪山主峰東峰縱走行程清單'));
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    final cards = find.byType(PackListCard);
    expect(
      tester.getSize(cards.at(0)).height,
      tester.getSize(cards.at(1)).height,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('旅程設定可以修改清單名稱', (tester) async {
    final repository = InMemoryPackListRepository();
    await tester.pumpWidget(PackPlanApp(repository: repository));
    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('旅程設定'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('trip-settings-title')),
      '雪山東峰',
    );
    await tester.tap(find.widgetWithText(FilledButton, '儲存'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '雪山東峰'), findsOneWidget);
    expect(repository.lists.first.title, '雪山東峰');
  });

  testWidgets('浮動導覽列是半透明毛玻璃', (tester) async {
    await tester.pumpWidget(
      PackPlanApp(repository: InMemoryPackListRepository()),
    );
    await tester.pumpAndSettle();

    final glass = find.byKey(const ValueKey('floating-nav-glass'));
    expect(
      find.ancestor(of: glass, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    final decoration =
        tester.widget<DecoratedBox>(glass).decoration as ShapeDecoration;
    expect(decoration.color!.a, lessThan(1));
    expect(decoration.shadows, isNull, reason: '陰影只畫在外圍,不疊在玻璃底下');
  });
}
