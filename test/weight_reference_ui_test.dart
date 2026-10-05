import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/app/pack_plan_app.dart';
import 'package:packplan/data/pack_list_repository.dart';
import 'package:packplan/data/weight_reference_repository.dart';
import 'package:packplan/models/gear_weight.dart';
import 'package:packplan/models/pack_item.dart';
import 'package:packplan/services/support_mail.dart';
import 'package:packplan/services/weight_reference_source.dart';
import 'package:packplan/theme/app_colors.dart';
import 'package:packplan/theme/app_dimens.dart';

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
  String? categoryId,
}) => GearWeight(
  key: key,
  nameZh: name,
  weightGram: grams,
  weightMin: min,
  weightMax: max,
  parentKey: parentKey,
  brand: brand,
  categoryId: categoryId,
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
    final headlamp = find.byKey(const ValueKey('checklist-tile-headlamp'));
    expect(
      find.descendant(of: headlamp, matching: find.text('頭燈')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: headlamp, matching: find.text('—\u00A0g')),
      findsOneWidget,
    );
  });

  testWidgets('批次帶入參考重量後標示線上資料,且可復原', (tester) async {
    await openList(tester);

    await tester.tap(find.byKey(const ValueKey('fill-missing-weights')));
    await tester.pumpAndSettle();

    expect(find.textContaining('找到 1 項參考值'), findsOneWidget);
    expect(find.textContaining('參考範圍 60'), findsOneWidget);
    expect(find.text('查無參考資料（1）'), findsOneWidget);
    // 「資料來源：… · 更新於」那行已刪除。
    expect(find.textContaining('資料來源'), findsNothing);
    expect(find.textContaining('更新於'), findsNothing);

    // 「套用」與對話框的「取消」同樣圓角
    final applyShape =
        tester
                .widget<ButtonStyleButton>(
                  find.byKey(const ValueKey('weight-fill-apply')),
                )
                .style
                ?.shape
                ?.resolve({})
            as RoundedRectangleBorder?;
    expect(
      applyShape?.borderRadius,
      BorderRadius.circular(AppRadius.dialogButton),
    );

    await tester.tap(find.byKey(const ValueKey('weight-fill-apply')));
    await tester.pumpAndSettle();

    // 訊息有關閉鈕,且即使有「復原」也會自動消失
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.showCloseIcon, isTrue);
    expect(snackBar.persist, isFalse);
    expect(snackBar.backgroundColor, AppColors.primary);
    expect(snackBar.duration, lessThan(const Duration(seconds: 4)));

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
    expect(find.textContaining('線上參考 1.2'), findsOneWidget);
    // 線上參考值放在「帶入參考值」同一行的右邊
    final button = tester.getRect(
      find.byKey(const ValueKey('item-editor-weight-reference')),
    );
    final hint = tester.getRect(
      find.byKey(const ValueKey('item-editor-reference-hint')),
    );
    expect(hint.left, greaterThan(button.right));
    expect(hint.center.dy, closeTo(button.center.dy, 4));
    expect(
      find.byKey(const ValueKey('item-editor-reference-icon')),
      findsOneWidget,
    );

    await tapVisible(tester, find.widgetWithText(FilledButton, '儲存'));

    final pack = itemById('pack');
    expect(pack.name, 'Osprey Exos 58');
    expect(pack.weightGram, 1200);
    expect(pack.weightSource, WeightSource.online);
    expect(pack.catalogKey, 'osprey-exos-58');
  });

  testWidgets('再次開啟選單時,標示目前採用的型號', (tester) async {
    await openList(tester);

    await scrollTo(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('item-editor-weight-reference')),
    );
    // 還沒採用任何參考值
    expect(
      find.byKey(const ValueKey('weight-reference-selected')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('weight-reference-osprey-exos-58')),
    );
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('item-editor-weight-reference')),
    );

    final selected = find.byKey(const ValueKey('weight-reference-selected'));
    expect(selected, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('weight-reference-osprey-exos-58')),
        matching: selected,
      ),
      findsOneWidget,
    );
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

  testWidgets('比對不到參考值時不顯示「帶入參考值」,改名稱比對到就出現', (tester) async {
    await openList(tester);

    await scrollTo(
      tester,
      find.byKey(const ValueKey('checklist-tile-power-bank')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('checklist-tile-power-bank')),
    );
    final button = find.byKey(const ValueKey('item-editor-weight-reference'));
    expect(button, findsNothing, reason: '行動電源在線上查不到');

    await tester.enterText(
      find.byKey(const ValueKey('item-editor-name')),
      '頭燈',
    );
    await tester.pumpAndSettle();
    expect(button, findsOneWidget, reason: '名稱比對到頭燈');
  });

  testWidgets('只有型號、沒有通用值的項目仍顯示「帶入參考值」並可搜尋', (tester) async {
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
    await tester.enterText(
      find.byKey(const ValueKey('weight-reference-search')),
      'nalgene',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('weight-reference-nalgene-1l')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Nalgene 寬口瓶 1L'), findsOneWidget);
    expect(find.widgetWithText(TextField, '180'), findsOneWidget);
  });

  testWidgets('有型號清單時也能搜尋整個重量庫', (tester) async {
    await openList(tester);

    await scrollTo(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('item-editor-weight-reference')),
    );
    expect(find.text('通用值（大背包）'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('weight-reference-search')),
      'exos',
    );
    await tester.pumpAndSettle();

    expect(find.text('通用值（大背包）'), findsNothing);
    expect(find.text('Osprey · 屬於「大背包」'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('weight-reference-osprey-exos-58')),
      findsOneWidget,
    );
  });

  testWidgets('搜尋預設只找項目所在分類,可切到全部分類', (tester) async {
    references = WeightReferenceRepository(
      source: _FakeSource([
        _weight('large-backpack', '大背包', 1500, categoryId: 'backpack'),
        _weight(
          'osprey-exos-58',
          'Osprey Exos 58',
          1200,
          parentKey: 'large-backpack',
          brand: 'Osprey',
          categoryId: 'backpack',
        ),
        _weight('instant-noodles', '泡麵', 122, categoryId: 'food'),
      ]),
      cacheStore: InMemoryWeightReferenceCacheStore(),
    );
    await openList(tester);

    await scrollTo(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('item-editor-weight-reference')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('weight-reference-search')),
      '泡麵',
    );
    await tester.pumpAndSettle();

    // 大背包在「背包系統」,預設不會搜到食物
    expect(
      find.byKey(const ValueKey('weight-reference-instant-noodles')),
      findsNothing,
    );
    expect(find.text('「背包系統」找不到「泡麵」'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('weight-reference-scope-all')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('weight-reference-instant-noodles')),
      findsOneWidget,
    );

    // 切回分類:同分類的型號照樣搜得到
    await tester.tap(
      find.byKey(const ValueKey('weight-reference-scope-category')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('weight-reference-search')),
      'exos',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('weight-reference-osprey-exos-58')),
      findsOneWidget,
    );
  });

  testWidgets('帶入參考值面板右上 × 可關閉,不會帶入', (tester) async {
    await openList(tester);
    await scrollTo(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('item-editor-weight-reference')),
    );
    expect(find.text('通用值（大背包）'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('weight-reference-close')));
    await tester.pumpAndSettle();

    expect(find.text('通用值（大背包）'), findsNothing);
    expect(find.text('編輯項目'), findsOneWidget, reason: '只關面板,編輯框還在');
  });

  testWidgets('全部分類都找不到時顯示 Email 回報按鈕', (tester) async {
    final opened = <Uri>[];
    var mailAppAvailable = true;
    final original = SupportMail.launcher;
    SupportMail.launcher = (uri) async {
      opened.add(uri);
      return mailAppAvailable;
    };
    addTearDown(() => SupportMail.launcher = original);

    await openList(tester);
    await scrollTo(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('item-editor-weight-reference')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('weight-reference-search')),
      '不存在的東西',
    );
    await tester.pumpAndSettle();

    final report = find.byKey(
      const ValueKey('weight-reference-report-missing'),
    );
    expect(report, findsOneWidget);
    await tapVisible(tester, report);
    expect(opened.single.path, 'appspdoit@gmail.com');
    expect(opened.single.queryParameters['subject'], 'PackPlan 參考重量找不到：不存在的東西');
    expect(
      find.byKey(const ValueKey('weight-reference-report-failed')),
      findsNothing,
    );

    // 沒有郵件 App:顯示信箱讓使用者自己寄。
    mailAppAvailable = false;
    await tapVisible(tester, report);
    expect(find.text('無法開啟郵件 App，請寄信到 appspdoit@gmail.com'), findsOneWidget);
  });

  testWidgets('找不到時「回報找不到」在「全部分類」右邊靠右;沒有改搜全部分類與資料來源', (tester) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    references = WeightReferenceRepository(
      source: _FakeSource([
        _weight('large-backpack', '大背包', 1500, categoryId: 'backpack'),
        _weight('instant-noodles', '泡麵', 122, categoryId: 'food'),
      ]),
      cacheStore: InMemoryWeightReferenceCacheStore(),
    );
    await openList(tester);
    await scrollTo(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(tester, find.byKey(const ValueKey('checklist-tile-pack')));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('item-editor-weight-reference')),
    );
    expect(find.textContaining('資料來源'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('weight-reference-search')),
      'pa',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('weight-reference-search-all')),
      findsNothing,
    );
    expect(find.text('改搜全部分類'), findsNothing);
    expect(find.textContaining('資料來源'), findsNothing);
    final report = find.byKey(
      const ValueKey('weight-reference-report-missing'),
    );
    final allChip = find.byKey(const ValueKey('weight-reference-scope-all'));
    expect(report, findsOneWidget);
    final reportRect = tester.getRect(report);
    final chipRect = tester.getRect(allChip);
    expect(reportRect.left, greaterThan(chipRect.right), reason: '在全部分類右邊');
    expect(
      (reportRect.center.dy - chipRect.center.dy).abs(),
      lessThan(4),
      reason: '同一行',
    );
    expect(reportRect.right, greaterThan(375 - 40), reason: '靠右對齊');
    expect(tester.takeException(), isNull);

    final clear = find.byKey(const ValueKey('weight-reference-search-clear'));
    expect(
      find.descendant(of: clear, matching: find.byIcon(Icons.cancel)),
      findsOneWidget,
    );

    // 有結果時不顯示回報按鈕。
    await tester.tap(allChip);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('weight-reference-search')),
      '泡麵',
    );
    await tester.pumpAndSettle();
    expect(report, findsNothing);
  });
}
