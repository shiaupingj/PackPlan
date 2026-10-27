import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:packplan/app/pack_plan_app.dart';
import 'package:packplan/data/pack_list_repository.dart';
import 'package:packplan/models/gear_item.dart';
import 'package:packplan/models/pack_item.dart';
import 'package:packplan/services/backup_codec.dart';
import 'package:packplan/services/gear_library.dart';
import 'package:packplan/widgets/checklist_tile.dart';

GearItem _gear(
  String id,
  String name, {
  int weightGram = 500,
  WeightClass weightClass = WeightClass.packed,
  bool isContainer = false,
  String categoryId = 'sleep',
  String categoryName = '睡眠系統',
  int usageCount = 0,
}) {
  final created = DateTime.utc(2026, 10, 1);
  return GearItem(
    id: id,
    name: name,
    categoryId: categoryId,
    categoryName: categoryName,
    weightGram: weightGram,
    weightClass: weightClass,
    isContainer: isContainer,
    usageCount: usageCount,
    catalogKey: 'sleeping-bag',
    createdAt: created,
    updatedAt: created,
  );
}

const _smallPack = PackItem(
  id: 'small-pack',
  categoryId: 'backpack',
  categoryName: '背包系統',
  name: '小背包',
  weightGram: 300,
  quantity: 1,
  checked: false,
  necessity: ItemNecessity.optional,
  sortOrder: 0,
  isContainer: true,
);

void main() {
  setUpAll(
    () => PackageInfo.setMockInitialValues(
      appName: 'PackPlan',
      packageName: 'com.packplan.packplan',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    ),
  );

  group('repository', () {
    test('addGearToList 複製快照、放進預設容器並更新使用次數', () {
      final repository = InMemoryPackListRepository(
        initialGear: [_gear('g1', 'Nemo Disco 15', weightGram: 980)],
      );
      final list = repository.lists.first;

      expect(repository.addGearToList(list.id, ['g1', 'missing']), 1);

      final item = repository
          .findById(list.id)!
          .items
          .singleWhere((item) => item.gearItemId == 'g1');
      expect(item.name, 'Nemo Disco 15');
      expect(item.weightGram, 980);
      expect(item.weightSource, WeightSource.gear);
      expect(item.catalogKey, 'sleeping-bag');
      expect(item.containerItemId, isNotNull);
      final gear = repository.gear.single;
      expect(gear.usageCount, 1);
      expect(gear.lastUsedAt, isNotNull);

      // 改裝備庫不回溯既有清單。
      repository.upsertGear(gear.copyWith(weightGram: 700));
      expect(
        repository
            .findById(list.id)!
            .items
            .singleWhere((item) => item.gearItemId == 'g1')
            .weightGram,
        980,
      );
    });

    test('addGearToList 可指定容器,不是這份清單的容器時改放第一個容器', () {
      final repository = InMemoryPackListRepository(
        initialGear: [_gear('g1', '頭燈A'), _gear('g2', '頭燈B')],
      );
      final list = repository.lists.first;
      repository.upsertItem(list.id, _smallPack);
      final firstContainerId = repository
          .findById(list.id)!
          .items
          .firstWhere((item) => item.isContainer)
          .id;

      repository.addGearToList(list.id, ['g1'], containerItemId: 'small-pack');
      repository.addGearToList(list.id, ['g2'], containerItemId: 'missing');

      final items = repository.findById(list.id)!.items;
      expect(
        items.singleWhere((item) => item.gearItemId == 'g1').containerItemId,
        'small-pack',
      );
      expect(
        items.singleWhere((item) => item.gearItemId == 'g2').containerItemId,
        firstContainerId,
      );
    });

    test('穿戴裝備加入清單時不放進容器', () {
      final repository = InMemoryPackListRepository(
        initialGear: [_gear('g1', '登山鞋', weightClass: WeightClass.worn)],
      );
      final list = repository.lists.first;
      repository.addGearToList(list.id, ['g1']);

      final item = repository
          .findById(list.id)!
          .items
          .singleWhere((item) => item.gearItemId == 'g1');
      expect(item.weightClass, WeightClass.worn);
      expect(item.containerItemId, isNull);
    });

    test('saveItemToGear 建立裝備並記下對應,重複收藏不會重複建立', () {
      final repository = InMemoryPackListRepository();
      final list = repository.lists.first;

      final saved = repository.saveItemToGear(list.id, 'water-bottle');
      expect(saved, isNotNull);
      expect(saved!.name, '水壺');
      expect(saved.weightGram, 500);
      expect(
        repository
            .findById(list.id)!
            .items
            .singleWhere((item) => item.id == 'water-bottle')
            .gearItemId,
        saved.id,
      );

      expect(repository.saveItemToGear(list.id, 'water-bottle')!.id, saved.id);
      expect(repository.gear, hasLength(1));
    });

    test('刪除裝備不影響已加入的清單', () {
      final repository = InMemoryPackListRepository(
        initialGear: [_gear('g1', '睡袋A')],
      );
      final list = repository.lists.first;
      repository.addGearToList(list.id, ['g1']);
      repository.deleteGear('g1');

      expect(repository.gear, isEmpty);
      expect(
        repository.findById(list.id)!.items.any((item) => item.name == '睡袋A'),
        isTrue,
      );
    });

    test('replaceAllData 沒帶裝備(舊版備份)時保留目前的裝備', () {
      final repository = InMemoryPackListRepository(
        initialGear: [_gear('g1', '睡袋A')],
      );
      repository.replaceAllData(lists: const [], settings: repository.settings);
      expect(repository.gear, hasLength(1));

      repository.replaceAllData(
        lists: const [],
        settings: repository.settings,
        gear: const [],
      );
      expect(repository.gear, isEmpty);
    });

    test('sortGear 依最常用、重量、名稱排序', () {
      final gear = [
        _gear('a', 'B 睡袋', weightGram: 300, usageCount: 1),
        _gear('b', 'A 睡墊', weightGram: 900, usageCount: 5),
      ];
      expect(sortGear(gear, GearSort.mostUsed).first.id, 'b');
      expect(sortGear(gear, GearSort.heaviest).first.id, 'b');
      expect(sortGear(gear, GearSort.name).first.id, 'b');
    });
  });

  group('backup', () {
    test('v2 備份保留裝備庫與清單項目的裝備來源', () {
      final source = InMemoryPackListRepository(
        initialGear: [
          _gear('g1', '大背包', isContainer: true, categoryId: 'backpack'),
        ],
      );
      final list = source.lists.first;
      source.addGearToList(list.id, ['g1']);

      final backup = BackupCodec.decode(
        BackupCodec.encode(
          lists: source.lists,
          settings: source.settings,
          gear: source.gear,
        ),
      );

      final gear = backup.gear!.single;
      expect(gear.name, '大背包');
      expect(gear.isContainer, isTrue);
      expect(gear.usageCount, 1);
      expect(gear.catalogKey, 'sleeping-bag');
      final item = backup.lists
          .singleWhere((current) => current.id == list.id)
          .items
          .singleWhere((item) => item.gearItemId == 'g1');
      expect(item.weightSource, WeightSource.gear);
      expect(item.isContainer, isTrue);
    });

    test('v1 備份仍可讀取,裝備庫為 null', () {
      final source = InMemoryPackListRepository();
      final json =
          jsonDecode(
                utf8.decode(
                  BackupCodec.encode(
                    lists: source.lists,
                    settings: source.settings,
                  ),
                ),
              )
              as Map<String, Object?>;
      json
        ..['version'] = 1
        ..remove('gear');

      final backup = BackupCodec.decode(utf8.encode(jsonEncode(json)));
      expect(backup.lists, hasLength(source.lists.length));
      expect(backup.gear, isNull);
    });

    test('比目前新的備份版本拒絕讀取', () {
      final source = InMemoryPackListRepository();
      final json =
          jsonDecode(
                utf8.decode(
                  BackupCodec.encode(
                    lists: source.lists,
                    settings: source.settings,
                  ),
                ),
              )
              as Map<String, Object?>;
      json['version'] = BackupCodec.currentVersion + 1;

      expect(
        () => BackupCodec.decode(utf8.encode(jsonEncode(json))),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });

  group('UI', () {
    Future<void> openHikingList(WidgetTester tester) async {
      await tester.tap(find.text('登山計劃'));
      await tester.pumpAndSettle();
    }

    Future<void> tapAddItem(WidgetTester tester) async {
      final button = find.text('新增項目');
      // 前面捲到下方項目時按鈕已離開畫面,先捲回去。
      await tester.scrollUntilVisible(
        button,
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('4 個分頁在 320 寬(iPhone SE 第一代)不溢出', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const PackPlanApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final glass = tester.getSize(
        find.byKey(const ValueKey('floating-nav-glass')),
      );
      expect(glass.width, lessThan(320));
    });

    testWidgets('裝備分頁:空狀態可新增第一件裝備', (tester) async {
      final repository = InMemoryPackListRepository();
      await tester.pumpWidget(PackPlanApp(repository: repository));

      await tester.tap(find.text('裝備'));
      await tester.pumpAndSettle();
      expect(find.text('裝備庫是空的'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('gear-add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('gear-editor-name')),
        'Nemo Disco 15',
      );
      await tester.enterText(
        find.byKey(const ValueKey('gear-editor-weight')),
        '980',
      );
      await tester.tap(find.text('儲存'));
      await tester.pumpAndSettle();

      expect(repository.gear.single.name, 'Nemo Disco 15');
      expect(repository.gear.single.weightGram, 980);
      expect(find.text('Nemo Disco 15'), findsOneWidget);
      expect(find.text('還沒用過'), findsOneWidget);
    });

    testWidgets('新增項目:從我的裝備多選加入,已加入的顯示灰態', (tester) async {
      final repository = InMemoryPackListRepository(
        initialGear: [_gear('g1', 'Nemo Disco 15', weightGram: 980)],
      );
      await tester.pumpWidget(PackPlanApp(repository: repository));
      await openHikingList(tester);
      await tapAddItem(tester);

      expect(find.text('從我的裝備加入'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('gear-picker-g1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('加入所選 (1)'));
      await tester.pumpAndSettle();

      expect(find.text('已從我的裝備加入 1 項'), findsOneWidget);
      final tile = find.byWidgetPredicate(
        (widget) =>
            widget is ChecklistTile &&
            widget.label == 'Nemo Disco 15' &&
            widget.weightFromGear,
      );
      await tester.scrollUntilVisible(
        tile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tile, findsOneWidget);

      await tapAddItem(tester);
      expect(find.text('已加入'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('gear-picker-manual')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('item-editor-name')), findsOneWidget);
    });

    testWidgets('清單有多個容器時,可選這次要放進哪一個', (tester) async {
      final repository = InMemoryPackListRepository(
        initialGear: [_gear('g1', '頭燈A')],
      );
      final list = repository.lists.firstWhere((list) => list.title == '登山計劃');
      repository.upsertItem(list.id, _smallPack);
      await tester.pumpWidget(PackPlanApp(repository: repository));
      await openHikingList(tester);
      await tapAddItem(tester);

      await tester.tap(find.byKey(const ValueKey('gear-picker-g1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('gear-picker-container')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('小背包').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('加入所選 (1)'));
      await tester.pumpAndSettle();

      expect(
        repository
            .findById(list.id)!
            .items
            .singleWhere((item) => item.gearItemId == 'g1')
            .containerItemId,
        'small-pack',
      );
    });

    testWidgets('只有一個容器時不顯示「放進」選單', (tester) async {
      await tester.pumpWidget(
        PackPlanApp(
          repository: InMemoryPackListRepository(
            initialGear: [_gear('g1', '頭燈A')],
          ),
        ),
      );
      await openHikingList(tester);
      await tapAddItem(tester);

      expect(find.byKey(const ValueKey('gear-picker-container')), findsNothing);
    });

    testWidgets('長按項目可收藏到我的裝備', (tester) async {
      final repository = InMemoryPackListRepository();
      await tester.pumpWidget(PackPlanApp(repository: repository));
      await openHikingList(tester);

      final waterBottle = find.byKey(
        const ValueKey('checklist-tile-water-bottle'),
      );
      await tester.scrollUntilVisible(
        waterBottle,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(waterBottle);
      await tester.pumpAndSettle();
      await tester.longPress(waterBottle);
      await tester.pumpAndSettle();
      await tester.tap(find.text('收藏到我的裝備'));
      await tester.pumpAndSettle();

      expect(find.text('已收藏「水壺」到我的裝備'), findsOneWidget);
      expect(repository.gear.single.name, '水壺');

      await tester.longPress(waterBottle);
      await tester.pumpAndSettle();
      expect(find.text('已在我的裝備'), findsOneWidget);
    });
  });
}
