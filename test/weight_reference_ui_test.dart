import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/app/pack_plan_app.dart';
import 'package:packplan/data/pack_list_repository.dart';
import 'package:packplan/data/weight_reference_repository.dart';
import 'package:packplan/models/gear_weight.dart';
import 'package:packplan/models/pack_item.dart';
import 'package:packplan/services/weight_reference_source.dart';

class _FakeSource implements WeightReferenceSource {
  _FakeSource(this.rows);

  final List<GearWeight> rows;

  @override
  Future<DateTime?> fetchVersion() async => DateTime.utc(2026, 9, 20);

  @override
  Future<List<GearWeight>> fetchUpdatedSince(DateTime? since) async => rows;
}

GearWeight _weight(
  String key,
  String name,
  int grams, {
  int? min,
  int? max,
  String? parentKey,
  String? brand,
}) => GearWeight(
  key: key,
  nameZh: name,
  weightGram: grams,
  weightMin: min,
  weightMax: max,
  parentKey: parentKey,
  brand: brand,
  updatedAt: DateTime.utc(2026, 9, 20),
);

void main() {
  const listId = 'sample-hiking';

  late InMemoryPackListRepository repository;
  late WeightReferenceRepository references;

  PackItem itemById(String id) =>
      repository.findById(listId)!.items.singleWhere((item) => item.id == id);

  setUp(() {
    repository = InMemoryPackListRepository();
    repository.upsertItems(listId, [
      // 範本項目、尚未填重量,有對應的線上資料
      itemById('headlamp').copyWith(
        weightGram: 0,
        weightSource: WeightSource.unset,
        catalogKey: 'headlamp',
      ),
      // 尚未填重量,但線上查不到
      itemById(
        'power-bank',
      ).copyWith(weightGram: 0, weightSource: WeightSource.unset),
      itemById('pack').copyWith(catalogKey: 'large-backpack'),
      // 線上沒有通用項目,只有掛在底下的型號
      itemById('water-bottle').copyWith(catalogKey: 'water-bottle'),
    ]);
    references = WeightReferenceRepository(
      source: _FakeSource([
        _weight('headlamp', '頭燈', 90, min: 60, max: 150),
        _weight('large-backpack', '大背包', 1500),
        _weight(
          'osprey-exos-58',
          'Osprey Exos 58',
          1200,
          parentKey: 'large-backpack',
          brand: 'Osprey',
        ),
        _weight(
          'nalgene-1l',
          'Nalgene 寬口瓶 1L',
          180,
          parentKey: 'water-bottle',
          brand: 'Nalgene',
        ),
      ]),
      cacheStore: InMemoryWeightReferenceCacheStore(),
    );
  });

  Future<void> openList(WidgetTester tester) async {
    await tester.pumpWidget(
      PackPlanApp(
        repository: repository,
        weightReferenceRepository: references,
      ),
    );
    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('缺重量項目顯示「— g」與提示列', (tester) async {
    await openList(tester);

    expect(find.text('2 項尚未填重量'), findsOneWidget);
    await scrollTo(
      tester,
      find.byKey(const ValueKey('checklist-tile-headlamp')),
    );
    expect(find.textContaining('頭燈 — g', findRichText: true), findsOneWidget);
  });

  testWidgets('批次帶入參考重量後標示線上資料,且可復原', (tester) async {
    await openList(tester);

    await tester.tap(find.byKey(const ValueKey('fill-missing-weights')));
    await tester.pumpAndSettle();

    expect(find.textContaining('找到 1 項參考值'), findsOneWidget);
    expect(find.textContaining('參考範圍 60'), findsOneWidget);
    expect(find.text('查無參考資料（1）'), findsOneWidget);
    expect(find.textContaining('更新於 9/20'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('weight-fill-apply')));
    await tester.pumpAndSettle();

    final headlamp = itemById('headlamp');
    expect(headlamp.weightGram, 90);
    expect(headlamp.weightSource, WeightSource.online);
    expect(itemById('power-bank').isWeightMissing, isTrue);
    expect(find.text('1 項尚未填重量'), findsOneWidget);
    expect(find.text('含 1 項線上參考重量'), findsOneWidget);
    await scrollTo(tester, find.byKey(const ValueKey('weight-online-icon')));
    expect(find.byKey(const ValueKey('weight-online-icon')), findsOneWidget);

    await tester.tap(find.text('復原'));
    await tester.pumpAndSettle();

    expect(itemById('headlamp').isWeightMissing, isTrue);
    await tester.scrollUntilVisible(
      find.text('2 項尚未填重量'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('2 項尚未填重量'), findsOneWidget);
  });

  testWidgets('取消勾選的項目不會被帶入', (tester) async {
    await openList(tester);

    await tester.tap(find.byKey(const ValueKey('fill-missing-weights')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('weight-fill-headlamp')));
    await tester.pumpAndSettle();

    final apply = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('套用 0 項'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      ),
    );
    expect(apply.onPressed, isNull);
  });

  testWidgets('單項選品牌型號時帶入重量並把名稱改成型號名', (tester) async {
    await openList(tester);

    await scrollTo(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('item-editor-weight-reference')),
    );

    expect(find.text('通用值（大背包）'), findsOneWidget);
    expect(find.text('Osprey'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('weight-reference-osprey-exos-58')),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Osprey Exos 58'), findsOneWidget);
    expect(find.widgetWithText(TextField, '1200'), findsOneWidget);
    expect(find.textContaining('☁ 線上參考 1.2'), findsOneWidget);

    await tapVisible(tester, find.widgetWithText(FilledButton, '儲存'));

    final pack = itemById('pack');
    expect(pack.name, 'Osprey Exos 58');
    expect(pack.weightGram, 1200);
    expect(pack.weightSource, WeightSource.online);
    expect(pack.catalogKey, 'osprey-exos-58');
  });

  testWidgets('通用項目沒有線上資料時,仍可用範本 key 選型號', (tester) async {
    await openList(tester);

    await scrollTo(
      tester,
      find.byKey(const ValueKey('checklist-tile-water-bottle')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('checklist-tile-water-bottle')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('item-editor-weight-reference')),
    );

    expect(find.textContaining('通用值'), findsNothing);
    expect(find.text('Nalgene'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('weight-reference-nalgene-1l')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Nalgene 寬口瓶 1L'), findsOneWidget);
    expect(find.widgetWithText(TextField, '180'), findsOneWidget);
  });

  testWidgets('帶入後又改重量,存成自填', (tester) async {
    await openList(tester);

    await scrollTo(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('item-editor-weight-reference')),
    );
    await tester.tap(
      find.byKey(const ValueKey('weight-reference-large-backpack')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '1500'), '1450');
    await tapVisible(tester, find.widgetWithText(FilledButton, '儲存'));

    final pack = itemById('pack');
    expect(pack.name, '主背包 45L');
    expect(pack.weightGram, 1450);
    expect(pack.weightSource, WeightSource.manual);
    expect(pack.catalogKey, 'large-backpack');
  });

  testWidgets('查無參考資料時提示使用者', (tester) async {
    await openList(tester);

    await scrollTo(
      tester,
      find.byKey(const ValueKey('checklist-tile-power-bank')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('checklist-tile-power-bank')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('item-editor-weight-reference')),
    );

    expect(find.text('查無「行動電源」的參考重量'), findsOneWidget);
  });
}
