import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:packplan/data/pack_list_repository.dart';
import 'package:packplan/models/pack_item.dart';
import 'package:packplan/models/pack_list.dart';
import 'package:packplan/models/user_settings.dart';
import 'package:packplan/services/backup_codec.dart';

void main() {
  test('backup round trip preserves lists, items, and settings', () {
    final source = InMemoryPackListRepository();
    final firstList = source.lists.first;
    final shirt = source
        .findById(firstList.id)!
        .items
        .singleWhere((item) => item.id == 'shirt');
    source.upsertItem(
      firstList.id,
      shirt.copyWith(weightClass: WeightClass.worn),
    );
    source.updateTripSettings(
      firstList.id,
      days: firstList.days,
      weatherConditions: firstList.weatherConditions,
      showWeight: false,
    );
    source.updateSettings(
      const UserSettings(
        weightUnit: WeightUnit.gram,
        defaultWeightLimitGram: 8500,
      ),
    );

    final bytes = BackupCodec.encode(
      lists: source.lists,
      settings: source.settings,
      exportedAt: DateTime.utc(2026, 6, 30),
    );
    final backup = BackupCodec.decode(bytes);

    expect(backup.lists.length, source.lists.length);
    expect(backup.lists.first.title, source.lists.first.title);
    expect(backup.lists.first.items.length, source.lists.first.items.length);
    expect(
      backup.lists.first.items.first.containerItemId,
      source.lists.first.items.first.containerItemId,
    );
    expect(backup.settings.weightUnit, WeightUnit.gram);
    expect(backup.settings.defaultWeightLimitGram, 8500);
    expect(backup.exportedAt, DateTime.utc(2026, 6, 30));
    expect(
      backup.lists.singleWhere((list) => list.id == firstList.id).showWeight,
      isFalse,
    );
    expect(
      backup.lists
          .singleWhere((list) => list.id == firstList.id)
          .items
          .singleWhere((item) => item.id == 'shirt')
          .weightClass,
      WeightClass.worn,
    );
  });

  test('backup round trip preserves themeMode', () {
    final source = InMemoryPackListRepository();
    source.updateSettings(const UserSettings(themeMode: ThemeMode.light));

    final backup = BackupCodec.decode(
      BackupCodec.encode(lists: source.lists, settings: source.settings),
    );

    expect(backup.settings.themeMode, ThemeMode.light);
  });

  test('legacy backups without themeMode default to system', () {
    final source = InMemoryPackListRepository();
    final bytes = BackupCodec.encode(
      lists: source.lists,
      settings: source.settings,
    );
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    (json['settings']! as Map<String, Object?>).remove('themeMode');

    final backup = BackupCodec.decode(
      Uint8List.fromList(utf8.encode(jsonEncode(json))),
    );

    expect(backup.settings.themeMode, ThemeMode.system);
  });

  test('legacy backups without showWeight default to visible', () {
    final source = InMemoryPackListRepository();
    final bytes = BackupCodec.encode(
      lists: source.lists,
      settings: source.settings,
    );
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    final lists = json['lists']! as List<Object?>;
    for (final list in lists.cast<Map<String, Object?>>()) {
      list.remove('showWeight');
      final items = list['items']! as List<Object?>;
      for (final item in items.cast<Map<String, Object?>>()) {
        item.remove('weightClass');
      }
    }

    final backup = BackupCodec.decode(
      Uint8List.fromList(utf8.encode(jsonEncode(json))),
    );

    expect(backup.lists.every((list) => list.showWeight), isTrue);
    expect(
      backup.lists
          .expand((list) => list.items)
          .every((item) => item.weightClass == WeightClass.packed),
      isTrue,
    );
  });

  test('legacy consumable weight class migrates to packed', () {
    final source = InMemoryPackListRepository();
    final bytes = BackupCodec.encode(
      lists: source.lists,
      settings: source.settings,
    );
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    final lists = json['lists']! as List<Object?>;
    final firstList = lists.first as Map<String, Object?>;
    final items = firstList['items']! as List<Object?>;
    final firstItem = items.first as Map<String, Object?>;
    firstItem['weightClass'] = 'consumable';

    final backup = BackupCodec.decode(
      Uint8List.fromList(utf8.encode(jsonEncode(json))),
    );

    expect(backup.lists.first.items.first.weightClass, WeightClass.packed);
  });

  test('backup round trip preserves weightSource and catalogKey', () {
    final source = InMemoryPackListRepository();
    final firstList = source.lists.first;
    final shirt = firstList.items.singleWhere((item) => item.id == 'shirt');
    source.upsertItem(
      firstList.id,
      shirt.copyWith(
        weightSource: WeightSource.online,
        catalogKey: 'base-layer',
      ),
    );

    final backup = BackupCodec.decode(
      BackupCodec.encode(lists: source.lists, settings: source.settings),
    );
    final decoded = backup.lists
        .singleWhere((list) => list.id == firstList.id)
        .items
        .singleWhere((item) => item.id == 'shirt');

    expect(decoded.weightSource, WeightSource.online);
    expect(decoded.catalogKey, 'base-layer');
  });

  test('legacy items without weightSource infer it from weight', () {
    final source = InMemoryPackListRepository();
    final bytes = BackupCodec.encode(
      lists: source.lists,
      settings: source.settings,
    );
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    final firstList =
        (json['lists']! as List<Object?>).first as Map<String, Object?>;
    final items = (firstList['items']! as List<Object?>)
        .cast<Map<String, Object?>>();
    for (final item in items) {
      item.remove('weightSource');
      item.remove('catalogKey');
    }
    items.first['weightGram'] = 0;

    final backup = BackupCodec.decode(
      Uint8List.fromList(utf8.encode(jsonEncode(json))),
    );
    final decodedItems = backup.lists.first.items;

    expect(decodedItems.first.weightSource, WeightSource.unset);
    expect(
      decodedItems
          .skip(1)
          .every((item) => item.weightSource == WeightSource.manual),
      isTrue,
    );
    expect(decodedItems.every((item) => item.catalogKey == null), isTrue);
  });

  test('decode rejects unknown weightSource', () {
    final source = InMemoryPackListRepository();
    final bytes = BackupCodec.encode(
      lists: source.lists,
      settings: source.settings,
    );
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    final firstList =
        (json['lists']! as List<Object?>).first as Map<String, Object?>;
    final firstItem =
        (firstList['items']! as List<Object?>).first as Map<String, Object?>;
    firstItem['weightSource'] = 'guess';

    expect(
      () =>
          BackupCodec.decode(Uint8List.fromList(utf8.encode(jsonEncode(json)))),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('repository can replace all data with decoded backup', () {
    final source = InMemoryPackListRepository();
    final target = InMemoryPackListRepository();
    final backup = BackupCodec.decode(
      BackupCodec.encode(
        lists: [source.lists.first],
        settings: const UserSettings(defaultWeightLimitGram: 9500),
      ),
    );

    target.replaceAllData(lists: backup.lists, settings: backup.settings);

    expect(target.lists, hasLength(1));
    expect(target.lists.single.id, source.lists.first.id);
    expect(target.settings.defaultWeightLimitGram, 9500);
  });

  test('decode rejects files that are not PackPlan backups', () {
    final bytes = Uint8List.fromList(
      utf8.encode(jsonEncode({'format': 'other', 'version': 1})),
    );

    expect(
      () => BackupCodec.decode(bytes),
      throwsA(
        isA<BackupFormatException>().having(
          (error) => error.message,
          'message',
          '這不是 PackPlan 備份檔',
        ),
      ),
    );
  });

  test('各範本建立的清單(含身上穿戴、天氣裝備)存檔後都讀得回來', () {
    final repository = InMemoryPackListRepository();
    for (final template in repository.templates.where((t) => !t.proOnly)) {
      for (final weather in [
        {WeatherCondition.sunny},
        WeatherCondition.values.toSet(),
      ]) {
        final keys = repository
            .previewItemsForDraft(
              template: template,
              days: 3,
              weatherConditions: weather,
            )
            .map(packItemSelectionKey)
            .toSet();
        final list = repository.createFromDraft(
          CreatePackListDraft(
            template: template,
            days: 3,
            weatherConditions: weather,
            selectedItemKeys: keys,
          ),
        );
        final worn = list.items.where(
          (item) => item.weightClass == WeightClass.worn,
        );
        expect(worn, isNotEmpty, reason: template.id);
        expect(
          worn.every((item) => item.containerItemId == null),
          isTrue,
          reason: '${template.id}:身上穿戴不能放進容器',
        );
      }
    }

    final decoded = BackupCodec.decode(
      BackupCodec.encode(
        lists: repository.lists,
        settings: repository.settings,
      ),
    );
    expect(decoded.lists.length, repository.lists.length);
  });

  test('舊資料裡放在容器內的身上穿戴,讀取時自動移出容器而不是整份拒讀', () {
    final repository = InMemoryPackListRepository();
    final list = repository.lists.first;
    final container = list.items.firstWhere((item) => item.isContainer);
    final broken = list.copyWith(
      items: [
        ...list.items,
        PackItem(
          id: 'legacy-worn',
          categoryId: 'worn',
          categoryName: '身上穿戴',
          name: '身上一套',
          weightGram: 0,
          quantity: 1,
          checked: false,
          necessity: ItemNecessity.optional,
          sortOrder: 99,
          weightClass: WeightClass.worn,
          containerItemId: container.id,
        ),
      ],
    );

    final decoded = BackupCodec.decode(
      BackupCodec.encode(lists: [broken], settings: repository.settings),
    );
    final worn = decoded.lists.single.items.singleWhere(
      (item) => item.id == 'legacy-worn',
    );
    expect(worn.containerItemId, isNull);
  });
}
