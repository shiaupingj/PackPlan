import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/app/pack_plan_app.dart';
import 'package:packplan/data/pack_list_repository.dart';

void main() {
  Finder field(String label) => find.byWidgetPredicate(
    (widget) =>
        (widget is TextField && widget.decoration?.labelText == label) ||
        (widget is InputDecorator && widget.decoration.labelText == label),
  );

  Future<InMemoryPackListRepository> openNewItemEditor(
    WidgetTester tester,
  ) async {
    final repository = InMemoryPackListRepository();
    await tester.pumpWidget(PackPlanApp(repository: repository));
    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增項目'));
    await tester.pumpAndSettle();
    return repository;
  }

  double top(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder.first).dy;

  testWidgets('重量與數量、重量類型與必要性、放置位置與容器開關各在同一行', (tester) async {
    await openNewItemEditor(tester);

    expect(top(tester, field('單件重量 g')), top(tester, field('數量')));
    expect(top(tester, field('重量類型')), top(tester, field('必要性')));

    final placement = find.byKey(const ValueKey('item-editor-placement'));
    final toggle = find.byKey(const ValueKey('item-editor-container-switch'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    // 放置位置與開關同一行(開關在右側)
    expect(
      (tester.getCenter(placement).dy - tester.getCenter(toggle).dy).abs(),
      lessThan(24),
    );
    expect(
      tester.getCenter(toggle).dx,
      greaterThan(tester.getCenter(placement).dx),
    );
    // 舊版開關下方的說明文字已移到 (i)
    expect(find.text('容器本身會計入重量，其他項目可放入此處'), findsNothing);
  });

  testWidgets('長按 (i) 顯示容器說明', (tester) async {
    await openNewItemEditor(tester);

    final info = find.byKey(const ValueKey('item-editor-container-info'));
    await tester.ensureVisible(info);
    await tester.pumpAndSettle();
    await tester.longPress(info);
    await tester.pumpAndSettle();

    expect(find.text('設為背包/行李容器：容器本身會計入重量，其他項目可放入此處'), findsOneWidget);
  });

  testWidgets('打開容器開關後,放置位置改為「本身為容器」且存成容器', (tester) async {
    final repository = await openNewItemEditor(tester);
    await tester.enterText(find.byType(TextField).first, '登頂包');

    final toggle = find.byKey(const ValueKey('item-editor-container-switch'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('item-editor-placement')), findsNothing);
    expect(find.text('本身為容器'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '儲存'));
    await tester.pumpAndSettle();

    final saved = repository.lists.first.items.singleWhere(
      (item) => item.name == '登頂包',
    );
    expect(saved.isContainer, isTrue);
    expect(saved.containerItemId, isNull);
  });
}
