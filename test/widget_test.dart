import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/app/pack_plan_app.dart';
import 'package:packplan/data/pack_list_repository.dart';
import 'package:packplan/models/pack_item.dart';

void main() {
  const nbsp = '\u00A0';
  const categoryDropdownKey = ValueKey('item-editor-category-dropdown');

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('App shell renders pack list tab by default', (tester) async {
    await tester.pumpWidget(const PackPlanApp());

    expect(find.text('打包清單'), findsOneWidget);
    expect(find.text('登山計劃'), findsOneWidget);
    expect(find.text('城市旅遊'), findsOneWidget);
    expect(find.text('建立新清單'), findsOneWidget);
    expect(find.text('主頁'), findsOneWidget);
    expect(find.text('範本'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
  });

  testWidgets('Home info button explains long-press list actions', (
    tester,
  ) async {
    await tester.pumpWidget(const PackPlanApp());

    final helpButton = find.byKey(const ValueKey('home-help-button'));
    expect(helpButton, findsOneWidget);

    await tester.tap(helpButton);
    await tester.pumpAndSettle();

    expect(find.text('操作說明'), findsOneWidget);
    expect(find.text('長按首頁中的任一清單卡片，即可開啟清單操作選單。'), findsOneWidget);
    expect(find.text('重新命名'), findsOneWidget);
    expect(find.text('複製清單'), findsOneWidget);
    expect(find.text('刪除清單'), findsOneWidget);
    expect(find.text('重量等級規則'), findsNothing);

    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('範本'));
    await tester.pumpAndSettle();

    expect(helpButton, findsNothing);
  });

  testWidgets('Bottom navigation switches between Phase 0 tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const PackPlanApp());

    await tester.tap(find.text('範本'));
    await tester.pumpAndSettle();

    expect(find.text('基礎登山'), findsOneWidget);
    expect(find.text('城市旅遊'), findsOneWidget);
    expect(find.text('極簡露營'), findsOneWidget);
    expect(find.text('進階登山'), findsOneWidget);
    expect(find.text('長天數旅行'), findsOneWidget);

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    expect(find.text('升級至 Pro 版'), findsOneWidget);
    expect(find.text('NT\$ 150 一次性買斷'), findsOneWidget);
    expect(find.text('偏好設定'), findsOneWidget);
    expect(find.text('單位設定'), findsOneWidget);
    expect(find.text('預設重量上限'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('資料管理'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('匯出備份'), findsOneWidget);
    expect(find.text('匯入備份'), findsOneWidget);
  });

  testWidgets('Create flow selects items and generates a list in four steps', (
    tester,
  ) async {
    await tester.pumpWidget(const PackPlanApp());

    await tester.tap(find.text('建立新清單'));
    await tester.pumpAndSettle();

    expect(find.text('Step 1 / 4'), findsOneWidget);

    await tapVisible(tester, find.text('基礎登山'));
    await tapVisible(tester, find.text('下一步'));

    expect(find.text('Step 2 / 4'), findsOneWidget);

    await tapVisible(tester, find.text('雨天'));
    final wornSwitch = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('include-worn-items-switch')),
    );
    expect(wornSwitch.value, isFalse);
    await tapVisible(tester, find.text('下一步'));

    expect(find.text('Step 3 / 4'), findsOneWidget);
    expect(find.text('選擇項目'), findsOneWidget);
    expect(find.text('背包系統'), findsOneWidget);
    expect(find.text('衣物用品'), findsOneWidget);
    expect(find.text('用具'), findsOneWidget);
    expect(find.text('大背包'), findsOneWidget);
    expect(find.text('身上穿戴'), findsNothing);
    expect(find.text('身上一套'), findsNothing);
    expect(find.text('登山鞋'), findsNothing);

    final selectedTileSize = tester.getSize(
      find.byKey(const ValueKey('draft-item-backpack:大背包')),
    );
    final unselectedTileSize = tester.getSize(
      find.byKey(const ValueKey('draft-item-backpack:小背包')),
    );
    expect(selectedTileSize, unselectedTileSize);

    await tapVisible(tester, find.text('證件'));
    await tapVisible(tester, find.text('下一步'));

    expect(find.text('Step 4 / 4'), findsOneWidget);
    expect(find.text('已選 42 個項目'), findsOneWidget);

    await tapVisible(tester, find.text('生成清單'));

    expect(find.text('登山計劃'), findsOneWidget);
    expect(find.text('超輕量化打包'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('雨衣 —${nbsp}g'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('雨衣 —${nbsp}g'), findsOneWidget);
    expect(find.textContaining('證件'), findsNothing);
  });

  testWidgets('Create flow can include a separate worn-items category', (
    tester,
  ) async {
    await tester.pumpWidget(const PackPlanApp());

    await tester.tap(find.text('建立新清單'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('基礎登山'));
    await tapVisible(tester, find.text('下一步'));

    await tester.tap(find.byKey(const ValueKey('include-worn-items-switch')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('下一步'));

    expect(find.text('身上穿戴'), findsOneWidget);
    expect(find.text('身上一套'), findsOneWidget);
    expect(find.text('登山鞋'), findsOneWidget);
  });

  testWidgets('Profile settings update weight unit across the app', (
    tester,
  ) async {
    await tester.pumpWidget(const PackPlanApp());

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('g'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('主頁'));
    await tester.pumpAndSettle();

    expect(find.text('基重 4120${nbsp}g'), findsOneWidget);
  });

  testWidgets('Appearance control switches theme mode to light', (
    tester,
  ) async {
    await tester.pumpWidget(const PackPlanApp());

    // 預設跟隨系統。
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('淺色'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('淺色'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });

  testWidgets('Profile shows privacy policy and terms entries', (tester) async {
    await tester.pumpWidget(const PackPlanApp());

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    final terms = find.text('使用條款');
    await tester.scrollUntilVisible(terms, 200);
    await tester.pumpAndSettle();

    expect(find.text('隱私權政策'), findsOneWidget);
    expect(terms, findsOneWidget);
  });

  testWidgets('Long pressing an item opens delete action', (tester) async {
    await tester.pumpWidget(const PackPlanApp());

    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();

    final waterBottleTile = find.byKey(
      const ValueKey('checklist-tile-water-bottle'),
    );
    await tester.scrollUntilVisible(
      waterBottleTile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(waterBottleTile);
    await tester.pumpAndSettle();
    await tester.longPress(waterBottleTile);
    await tester.pumpAndSettle();

    expect(find.text('刪除項目'), findsOneWidget);

    await tester.tap(find.text('刪除項目'));
    await tester.pumpAndSettle();
    expect(find.text('刪除項目？'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '確定刪除'));
    await tester.pumpAndSettle();

    expect(find.text('水壺 500${nbsp}g'), findsNothing);
  });

  testWidgets('Deleting loaded luggage confirms and moves contents', (
    tester,
  ) async {
    final repository = InMemoryPackListRepository();
    final listId = repository.lists.first.id;
    final mainBackpackId = repository
        .findById(listId)!
        .items
        .singleWhere((item) => item.isContainer)
        .id;
    const luggage = PackItem(
      id: 'test-luggage',
      categoryId: 'luggage',
      categoryName: '行李',
      name: '登機箱',
      weightGram: 1800,
      quantity: 1,
      checked: false,
      necessity: ItemNecessity.optional,
      sortOrder: 99,
      isContainer: true,
    );
    const content = PackItem(
      id: 'test-luggage-content',
      categoryId: 'clothes',
      categoryName: '衣物',
      name: '備用外套',
      weightGram: 500,
      quantity: 1,
      checked: false,
      necessity: ItemNecessity.optional,
      sortOrder: 100,
      containerItemId: 'test-luggage',
    );
    repository.upsertItem(listId, luggage);
    repository.upsertItem(listId, content);
    await tester.pumpWidget(PackPlanApp(repository: repository));

    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();
    final luggageTile = find.byKey(
      const ValueKey('checklist-tile-test-luggage'),
    );
    await tester.scrollUntilVisible(
      luggageTile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(luggageTile);
    await tester.pumpAndSettle();
    await tester.longPress(luggageTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('刪除項目'));
    await tester.pumpAndSettle();

    expect(find.text('行李內仍有項目'), findsOneWidget);
    expect(
      find.text(
        '「登機箱」內有 1 個項目，確定要刪除嗎？'
        '刪除後，這些項目會移到「主背包 45L」。',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, '確定刪除'));
    await tester.pumpAndSettle();

    expect(
      repository.findById(listId)!.items.any((item) => item.id == luggage.id),
      isFalse,
    );
    expect(
      repository
          .findById(listId)!
          .items
          .singleWhere((item) => item.id == content.id)
          .containerItemId,
      mainBackpackId,
    );
  });

  testWidgets('Backpack category hints item can become a container', (
    tester,
  ) async {
    await tester.pumpWidget(const PackPlanApp());

    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('新增項目'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '登頂包');
    await tester.tap(find.byKey(categoryDropdownKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('背包系統').last);
    await tester.pumpAndSettle();

    expect(find.text('此分類可作為放置位置，其他項目可以放入這裡。'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '儲存'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('登頂包 100${nbsp}g'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('登頂包 100${nbsp}g'), findsOneWidget);
  });

  testWidgets('Category add button pre-fills category', (tester) async {
    await tester.pumpWidget(const PackPlanApp());

    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byTooltip('新增工具項目'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('新增工具項目'));
    await tester.pumpAndSettle();

    expect(find.text('新增項目'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(categoryDropdownKey),
        matching: find.text('工具'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Category dropdown can add a custom category inline', (
    tester,
  ) async {
    await tester.pumpWidget(const PackPlanApp());

    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('新增項目'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(categoryDropdownKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('＋ 新增分類').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == '新增分類名稱',
      ),
      '舒適裝備',
    );
    await tester.tap(find.widgetWithText(FilledButton, '加入分類'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(categoryDropdownKey),
        matching: find.text('舒適裝備'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Container summary opens a contents dialog', (tester) async {
    await tester.pumpWidget(const PackPlanApp());

    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看 主背包 45L 內容物'));
    await tester.pumpAndSettle();

    expect(find.text('主背包 45L 內容物'), findsOneWidget);
    expect(find.text('內容物 7 項 · 2.9${nbsp}kg'), findsOneWidget);
    expect(find.text('能量棒 x6'), findsOneWidget);
  });

  testWidgets('Share action opens the native system share channel', (
    tester,
  ) async {
    const channel = MethodChannel('com.packplan.packplan/system_share');
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedCall = call;
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await tester.pumpWidget(const PackPlanApp());
    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();

    expect(find.textContaining('最重項目 主背包 45L'), findsOneWidget);

    await tester.tap(find.byTooltip('分享'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('使用系統分享'));
    await tester.pumpAndSettle();

    expect(receivedCall?.method, 'shareText');
    expect(
      (receivedCall?.arguments as Map<Object?, Object?>)['text'],
      contains('PackPlan 登山計劃'),
    );
  });

  testWidgets('Trip settings can hide weight throughout the current list', (
    tester,
  ) async {
    final repository = InMemoryPackListRepository();
    final listId = repository.lists.first.id;
    await tester.pumpWidget(PackPlanApp(repository: repository));

    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();
    expect(find.text('已打包重量'), findsOneWidget);

    await tester.tap(find.byTooltip('旅程設定'));
    await tester.pumpAndSettle();
    expect(find.text('顯示重量'), findsOneWidget);

    await tester.tap(find.widgetWithText(SwitchListTile, '顯示重量'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '儲存'));
    await tester.pumpAndSettle();

    expect(repository.findById(listId)!.showWeight, isFalse);
    expect(find.text('已打包重量'), findsNothing);
    expect(find.textContaining('最重項目'), findsNothing);
  });

  testWidgets(
    'Category title can be renamed without changing its semantic id',
    (tester) async {
      final repository = InMemoryPackListRepository();
      final listId = repository.lists.first.id;
      await tester.pumpWidget(PackPlanApp(repository: repository));

      await tester.tap(find.text('登山計劃'));
      await tester.pumpAndSettle();
      final renameTools = find.byTooltip('重新命名工具分類');
      await tester.scrollUntilVisible(
        renameTools,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(renameTools);
      await tester.pumpAndSettle();

      final nameField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == '分類名稱',
      );
      await tester.enterText(nameField, '實用工具');
      await tester.tap(find.widgetWithText(FilledButton, '儲存'));
      await tester.pumpAndSettle();

      final tools = repository
          .findById(listId)!
          .items
          .where((item) => item.categoryId == 'tools');
      expect(tools.every((item) => item.categoryName == '實用工具'), isTrue);
      expect(find.text('實用工具'), findsOneWidget);
    },
  );

  testWidgets('Category order dialog saves a new category sequence', (
    tester,
  ) async {
    final repository = InMemoryPackListRepository();
    final cityList = repository.lists.singleWhere(
      (list) => list.tripType.name == 'city',
    );
    await tester.pumpWidget(PackPlanApp(repository: repository));

    await tester.tap(find.text('城市旅遊'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('分類排序'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('分類排序'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('category-order-handle-行李')),
      const Offset(0, 150),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '儲存排序'));
    await tester.pumpAndSettle();

    final sortedItems = [...repository.findById(cityList.id)!.items]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    expect(sortedItems.first.categoryName, isNot('行李'));
  });

  testWidgets('Item row edits while only its circle toggles completion', (
    tester,
  ) async {
    final repository = InMemoryPackListRepository();
    final listId = repository.lists.first.id;
    final wasChecked = repository
        .findById(listId)!
        .items
        .singleWhere((item) => item.id == 'water-bottle')
        .checked;
    await tester.pumpWidget(PackPlanApp(repository: repository));

    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();
    final itemTile = find.byKey(const ValueKey('checklist-tile-water-bottle'));
    await tester.scrollUntilVisible(
      itemTile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(itemTile);
    await tester.pumpAndSettle();
    await tester.tap(itemTile);
    await tester.pumpAndSettle();

    expect(find.text('編輯項目'), findsOneWidget);
    expect(
      repository
          .findById(listId)!
          .items
          .singleWhere((item) => item.id == 'water-bottle')
          .checked,
      wasChecked,
    );

    final weightField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == '單件重量 g',
    );
    final quantityField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == '數量',
    );
    await tester.enterText(weightField, '0');
    await tester.enterText(quantityField, '0');
    await tester.tap(find.widgetWithText(FilledButton, '儲存'));
    await tester.pumpAndSettle();

    final savedItem = repository
        .findById(listId)!
        .items
        .singleWhere((item) => item.id == 'water-bottle');
    expect(savedItem.weightGram, 0);
    expect(savedItem.quantity, 0);

    await tester.ensureVisible(itemTile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: itemTile,
        matching: find.byTooltip(wasChecked ? '取消完成' : '標記完成'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      repository
          .findById(listId)!
          .items
          .singleWhere((item) => item.id == 'water-bottle')
          .checked,
      !wasChecked,
    );
  });

  testWidgets('Item editor can mark clothing as worn and exclude pack weight', (
    tester,
  ) async {
    final repository = InMemoryPackListRepository();
    final listId = repository.lists.first.id;
    await tester.pumpWidget(PackPlanApp(repository: repository));

    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();
    final shirtTile = find.byKey(const ValueKey('checklist-tile-shirt'));
    await tester.scrollUntilVisible(
      shirtTile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(shirtTile);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('計入背重'));
    await tapVisible(tester, find.text('不計入背重').last);
    await tapVisible(tester, find.widgetWithText(FilledButton, '儲存'));

    final shirt = repository
        .findById(listId)!
        .items
        .singleWhere((item) => item.id == 'shirt');
    expect(shirt.weightClass, WeightClass.worn);
    expect(shirt.containerItemId, isNull);
    expect(find.text('穿戴'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('背包總重'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('背包總重 3.6'), findsOneWidget);
    expect(find.textContaining('穿戴 540'), findsWidgets);
  });
}
