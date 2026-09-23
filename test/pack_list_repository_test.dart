import 'package:flutter_test/flutter_test.dart';
import 'package:packplan/data/pack_list_repository.dart';
import 'package:packplan/models/pack_item.dart';
import 'package:packplan/models/pack_list.dart';
import 'package:packplan/models/pack_template.dart';
import 'package:packplan/models/user_settings.dart';

void main() {
  test('createFromDraft adjusts quantities by days and weather', () {
    final repository = InMemoryPackListRepository();
    // 用一個會落到內建登山樣板資料的 hiking 範本，
    // 專測「天數 / 天氣調整數量」引擎，與各範本自訂候選清單解耦。
    const template = PackTemplate(
      id: 'test-hike',
      name: '測試登山',
      tripType: TripType.hiking,
      proOnly: false,
      description: '測試用',
    );

    final list = repository.createFromDraft(
      CreatePackListDraft(
        template: template,
        days: 4,
        weatherConditions: {
          WeatherCondition.cloudy,
          WeatherCondition.rainy,
          WeatherCondition.cold,
        },
      ),
    );

    expect(list.title, '登山計劃');
    expect(list.items.first.checked, isFalse);
    expect(list.items.singleWhere((item) => item.name == '排汗上衣').quantity, 4);
    expect(list.items.singleWhere((item) => item.name == '能量棒').quantity, 8);
    expect(list.items.any((item) => item.name == '背包防雨套'), isTrue);
    expect(list.items.any((item) => item.name == '防風外套'), isTrue);
    expect(list.items.any((item) => item.name == '保暖中層'), isTrue);
    expect(list.weatherConditions, contains(WeatherCondition.cloudy));
    expect(list.weatherConditions, contains(WeatherCondition.cold));
    final container = list.items.singleWhere((item) => item.isContainer);
    expect(container.name, '主背包 45L');
    expect(
      list.items.singleWhere((item) => item.name == '防風外套').containerItemId,
      container.id,
    );
  });

  test('settings change default weight limit for new outdoor lists', () {
    final repository = InMemoryPackListRepository();
    repository.updateSettings(const UserSettings(defaultWeightLimitGram: 9000));

    final list = repository.createFromDraft(
      CreatePackListDraft(
        template: repository.templates.first,
        days: 2,
        weatherConditions: {WeatherCondition.sunny},
      ),
    );

    expect(repository.settings.defaultWeightLimitGram, 9000);
    expect(list.weightLimitGram, 9000);
  });

  test('basic hiking template exposes the requested categorized checklist', () {
    final repository = InMemoryPackListRepository();
    final template = repository.templates.first;

    final items = repository.previewItemsForDraft(
      template: template,
      days: 3,
      weatherConditions: const <WeatherCondition>{},
    );

    expect(items, hasLength(62));
    expect(items.map((item) => item.categoryName).toSet(), {
      '背包系統',
      '睡眠系統',
      '衣物用品',
      '身上穿戴',
      '食物',
      '餐具',
      '裝水容器',
      '炊事',
      '用具',
      '安全導航',
      '個人物品',
    });
    expect(items.every((item) => item.weightGram == 0), isTrue);
    // 鹽糖為選配食物 → 不套天數倍率，維持固定數量 2。
    expect(items.singleWhere((item) => item.name == '鹽糖').quantity, 2);
    expect(items.any((item) => item.name.contains('總重量')), isFalse);
    expect(
      items.any(
        (item) => {
          '芒果乾',
          '肉條',
          '脆餅',
          '海螺',
          '炸花枝餅乾',
          '冬粉湯',
          '能量果凍',
          '眼鏡及眼鏡盒',
          '鏡子+梳子',
          '財物+悠遊卡',
          'Q餅',
          '飛虎',
          '福全蛋',
        }.contains(item.name),
      ),
      isFalse,
    );
    expect(items.any((item) => item.name == '證件'), isTrue);
    expect(items.any((item) => item.name == '溼紙巾'), isTrue);
    expect(items.any((item) => item.name == '頭燈+電池'), isFalse);
    expect(items.any((item) => item.name == '頭燈'), isTrue);
    expect(items.any((item) => item.name == '頭燈用電池'), isTrue);
    expect(items.any((item) => item.name == '毛帽'), isTrue);
    expect(
      items.singleWhere((item) => item.name == '登山鞋').weightClass,
      WeightClass.worn,
    );
  });

  test('draft item selection filters items and clears missing containers', () {
    final repository = InMemoryPackListRepository();
    final template = repository.templates.first;
    final preview = repository.previewItemsForDraft(
      template: template,
      days: 3,
      weatherConditions: {WeatherCondition.sunny},
    );
    final waterBottle = preview.singleWhere((item) => item.name == '水瓶');

    final list = repository.createFromDraft(
      CreatePackListDraft(
        template: template,
        days: 3,
        weatherConditions: {WeatherCondition.sunny},
        selectedItemKeys: {packItemSelectionKey(waterBottle)},
      ),
    );

    expect(list.items, hasLength(1));
    expect(list.items.single.name, '水瓶');
    expect(list.items.single.containerItemId, isNull);
  });

  test('renameList updates list title', () {
    final repository = InMemoryPackListRepository();
    final listId = repository.lists.first.id;

    repository.renameList(listId, '週末輕量包');

    expect(repository.findById(listId)!.title, '週末輕量包');
  });

  test('updateTripSettings changes days and adds weather items', () {
    final repository = InMemoryPackListRepository();
    final listId = repository.lists.first.id;

    repository.updateTripSettings(
      listId,
      days: 5,
      weatherConditions: {
        WeatherCondition.cloudy,
        WeatherCondition.rainy,
        WeatherCondition.cold,
      },
    );

    final list = repository.findById(listId)!;

    expect(list.title, '登山計劃');
    expect(list.days, 5);
    expect(list.nights, 4);
    expect(list.weatherConditions, contains(WeatherCondition.cloudy));
    expect(list.weatherConditions, contains(WeatherCondition.cold));
    expect(list.items.singleWhere((item) => item.name == '排汗上衣').quantity, 5);
    expect(list.items.any((item) => item.name == '防風外套'), isTrue);
    expect(list.items.any((item) => item.name == '保暖中層'), isTrue);
  });

  test('trip settings persist the per-list weight visibility', () {
    final repository = InMemoryPackListRepository();
    final list = repository.lists.first;

    repository.updateTripSettings(
      list.id,
      days: list.days,
      weatherConditions: list.weatherConditions,
      showWeight: false,
    );

    expect(repository.findById(list.id)!.showWeight, isFalse);
    expect(
      repository.lists
          .where((current) => current.id != list.id)
          .every((current) => current.showWeight),
      isTrue,
    );
  });

  test('duplicate and delete list update list collection', () {
    final repository = InMemoryPackListRepository();
    final sourceId = repository.lists.first.id;

    final copy = repository.duplicateList(sourceId);

    expect(copy, isNotNull);
    expect(repository.lists.first.title, contains('副本'));
    expect(repository.lists.length, 3);
    final copiedContainer = copy!.items.singleWhere((item) => item.isContainer);
    final copiedWaterBottle = copy.items.singleWhere(
      (item) => item.name == '水壺',
    );
    expect(copiedWaterBottle.categoryName, '飲水系統');
    expect(copiedWaterBottle.containerItemId, copiedContainer.id);

    repository.deleteList(copy.id);

    expect(repository.findById(copy.id), isNull);
    expect(repository.lists.length, 2);
  });

  test('upsertItem and deleteItem update list weight surface', () {
    final repository = InMemoryPackListRepository();
    final listId = repository.lists.first.id;
    final containerId = repository
        .findById(listId)!
        .items
        .singleWhere((item) => item.isContainer)
        .id;
    const item = PackItem(
      id: 'test-chair',
      categoryId: 'comfort',
      categoryName: '舒適裝備',
      name: '折疊椅',
      weightGram: 600,
      quantity: 1,
      checked: false,
      necessity: ItemNecessity.luxury,
      sortOrder: 99,
      containerItemId: 'pack',
    );

    repository.upsertItem(listId, item);

    expect(repository.findById(listId)!.totalWeightGram, 4720);
    expect(
      repository
          .findById(listId)!
          .items
          .singleWhere((item) => item.id == 'test-chair')
          .containerItemId,
      containerId,
    );

    repository.deleteItem(listId, item.id);

    expect(repository.findById(listId)!.totalWeightGram, 4120);
  });

  test('deleteItem keeps at least one container', () {
    final repository = InMemoryPackListRepository();
    final listId = repository.lists.first.id;
    final containerId = repository
        .findById(listId)!
        .items
        .singleWhere((item) => item.isContainer)
        .id;

    repository.deleteItem(listId, containerId);

    final updated = repository.findById(listId)!;
    expect(updated.items.any((item) => item.id == containerId), isTrue);
    expect(updated.items.where((item) => item.isContainer).length, 1);
  });

  test('deleting a container moves its contents to the main backpack', () {
    final repository = InMemoryPackListRepository();
    final listId = repository.lists.first.id;
    final mainBackpackId = repository
        .findById(listId)!
        .items
        .singleWhere((item) => item.isContainer)
        .id;
    const luggage = PackItem(
      id: 'side-luggage',
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
      id: 'luggage-content',
      categoryId: 'clothes',
      categoryName: '衣物',
      name: '備用外套',
      weightGram: 500,
      quantity: 1,
      checked: false,
      necessity: ItemNecessity.optional,
      sortOrder: 100,
      containerItemId: 'side-luggage',
    );
    repository.upsertItem(listId, luggage);
    repository.upsertItem(listId, content);

    repository.deleteItem(listId, luggage.id);

    final updated = repository.findById(listId)!;
    expect(updated.items.any((item) => item.id == luggage.id), isFalse);
    expect(
      updated.items
          .singleWhere((item) => item.id == content.id)
          .containerItemId,
      mainBackpackId,
    );
  });

  test('reorderItems changes item order inside a category', () {
    final repository = InMemoryPackListRepository();
    final listId = repository.lists.first.id;
    final list = repository.findById(listId)!;
    final toolItems = list.items
        .where((item) => item.categoryId == 'tools')
        .toList();

    repository.reorderItems(listId, toolItems.reversed.toList());

    final updated = repository.findById(listId)!;
    final firstToolItem = updated.items
        .where((item) => item.categoryId == 'tools')
        .reduce((a, b) => a.sortOrder < b.sortOrder ? a : b);

    expect(firstToolItem.name, '行動電源');
  });

  test('renameCategory changes its label but preserves semantic ids', () {
    final repository = InMemoryPackListRepository();
    final cityList = repository.lists.singleWhere(
      (list) => list.tripType == TripType.city,
    );

    final renamed = repository.renameCategory(cityList.id, '行李', '旅行箱');
    final updated = repository.findById(cityList.id)!;
    final luggageItems = updated.items.where(
      (item) => item.categoryId == 'luggage',
    );

    expect(renamed, isTrue);
    expect(luggageItems, isNotEmpty);
    expect(luggageItems.every((item) => item.categoryName == '旅行箱'), isTrue);
    expect(repository.renameCategory(cityList.id, '旅行箱', '衣物'), isFalse);
  });

  test('reorderCategories keeps items grouped in the requested order', () {
    final repository = InMemoryPackListRepository();
    final listId = repository.lists.first.id;
    final list = repository.findById(listId)!;
    final originalNames = <String>[];
    final originalItems = [...list.items]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final item in originalItems) {
      if (!originalNames.contains(item.categoryName)) {
        originalNames.add(item.categoryName);
      }
    }
    final requestedNames = originalNames.reversed.toList();

    repository.reorderCategories(listId, requestedNames);

    final updatedItems = [...repository.findById(listId)!.items]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final updatedNames = <String>[];
    for (final item in updatedItems) {
      if (!updatedNames.contains(item.categoryName)) {
        updatedNames.add(item.categoryName);
      }
    }
    expect(updatedNames, requestedNames);
  });

  test('worn items are removed from containers and pack total', () {
    final repository = InMemoryPackListRepository();
    final listId = repository.lists.first.id;
    final shirt = repository
        .findById(listId)!
        .items
        .singleWhere((item) => item.id == 'shirt');

    repository.upsertItem(
      listId,
      shirt.copyWith(weightClass: WeightClass.worn),
    );

    final updated = repository.findById(listId)!;
    final wornShirt = updated.items.singleWhere((item) => item.id == 'shirt');
    expect(wornShirt.weightClass, WeightClass.worn);
    expect(wornShirt.containerItemId, isNull);
    expect(updated.totalWeightGram, 3580);
    expect(updated.wornWeightGram, 540);
  });
}
