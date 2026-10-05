import 'package:flutter/foundation.dart';

import '../models/pack_item.dart';
import '../models/pack_list.dart';
import '../models/pack_template.dart';
import '../models/user_settings.dart';
import 'seed_data.dart';

class CreatePackListDraft {
  const CreatePackListDraft({
    required this.template,
    required this.days,
    required this.weatherConditions,
    this.selectedItemKeys,
    this.title,
  });

  final PackTemplate template;

  /// 使用者在 Step 4 輸入的清單名稱;空白時用 [defaultPackListTitle]。
  final String? title;
  final int days;
  final Set<WeatherCondition> weatherConditions;
  final Set<String>? selectedItemKeys;
}

/// 新清單的預設名稱(依旅程類型)。
String defaultPackListTitle(TripType type) {
  return switch (type) {
    TripType.hiking => '登山計劃',
    TripType.city => '城市旅遊',
    TripType.camping => '露營計劃',
  };
}

String packItemSelectionKey(PackItem item) => '${item.categoryId}:${item.name}';

abstract interface class PackListRepository extends Listenable {
  List<PackList> get lists;
  List<PackTemplate> get templates;
  UserSettings get settings;

  /// 最近一次寫入本機儲存是否失敗。失敗期間 UI 應提示使用者變更可能遺失。
  bool get hasSaveError;

  PackList? findById(String id);
  void updateSettings(UserSettings settings);
  void replaceAllData({
    required List<PackList> lists,
    required UserSettings settings,
  });
  void renameList(String listId, String title);
  void updateTripSettings(
    String listId, {
    required int days,
    required Set<WeatherCondition> weatherConditions,
    bool? showWeight,
  });
  bool renameCategory(String listId, String currentName, String newName);
  void reorderCategories(String listId, List<String> orderedCategoryNames);
  List<PackItem> previewItemsForDraft({
    required PackTemplate template,
    required int days,
    required Set<WeatherCondition> weatherConditions,
  });
  PackList createFromTemplate(PackTemplate template);
  PackList createFromDraft(CreatePackListDraft draft);
  PackList? duplicateList(String listId);
  void deleteList(String listId);
  void toggleItem(String listId, String itemId, bool checked);
  void upsertItem(String listId, PackItem item);

  /// 一次更新多個既有項目(例如帶入參考重量、復原),只通知一次。
  void upsertItems(String listId, List<PackItem> items);
  void deleteItem(String listId, String itemId);
  void reorderItems(String listId, List<PackItem> reorderedItems);
}

class InMemoryPackListRepository extends ChangeNotifier
    implements PackListRepository {
  InMemoryPackListRepository({
    List<PackList>? initialLists,
    UserSettings initialSettings = const UserSettings(),
  }) : _lists = initialLists == null ? SeedData.lists() : [...initialLists],
       _settings = initialSettings;

  final List<PackList> _lists;
  UserSettings _settings;

  @override
  List<PackList> get lists {
    final sorted = [..._lists]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(sorted);
  }

  @override
  List<PackTemplate> get templates => SeedData.templates;

  @override
  UserSettings get settings => _settings;

  @override
  bool get hasSaveError => false;

  @override
  void updateSettings(UserSettings settings) {
    _settings = settings;
    notifyListeners();
  }

  @override
  void replaceAllData({
    required List<PackList> lists,
    required UserSettings settings,
  }) {
    _lists
      ..clear()
      ..addAll(lists);
    _settings = settings;
    notifyListeners();
  }

  @override
  PackList? findById(String id) {
    for (final list in _lists) {
      if (list.id == id) return list;
    }
    return null;
  }

  @override
  PackList createFromTemplate(PackTemplate template) {
    return createFromDraft(
      CreatePackListDraft(
        template: template,
        days: template.tripType == TripType.city ? 5 : 3,
        weatherConditions: {WeatherCondition.sunny},
      ),
    );
  }

  @override
  PackList createFromDraft(CreatePackListDraft draft) {
    final now = DateTime.now();
    final id = 'list-${now.microsecondsSinceEpoch}';
    final nights = draft.template.tripType == TripType.city
        ? 0
        : (draft.days - 1).clamp(0, 30).toInt();
    final list = PackList(
      id: id,
      title: switch (draft.title?.trim()) {
        final title? when title.isNotEmpty => title,
        _ => defaultPackListTitle(draft.template.tripType),
      },
      tripType: draft.template.tripType,
      days: draft.days,
      nights: nights,
      weatherConditions: draft.weatherConditions,
      weightLimitGram: draft.template.tripType == TripType.city
          ? 12000
          : _settings.defaultWeightLimitGram,
      createdAt: now,
      updatedAt: now,
      items: _itemsFor(
        template: draft.template,
        days: draft.days,
        weatherConditions: draft.weatherConditions,
        idPrefix: id,
        selectedItemKeys: draft.selectedItemKeys,
      ),
    );
    _lists.insert(0, list);
    notifyListeners();
    return list;
  }

  @override
  PackList? duplicateList(String listId) {
    final source = findById(listId);
    if (source == null) return null;

    final now = DateTime.now();
    final id = 'list-${now.microsecondsSinceEpoch}';
    final idBySourceId = {
      for (final item in source.items) item.id: '$id-${item.id}',
    };
    final copy = source.copyWith(
      id: id,
      title: '${source.title} 副本',
      createdAt: now,
      updatedAt: now,
      items: source.items
          .map(
            (item) => item.copyWith(
              id: idBySourceId[item.id],
              containerItemId: item.containerItemId == null
                  ? null
                  : idBySourceId[item.containerItemId],
            ),
          )
          .toList(),
    );
    _lists.insert(0, copy);
    notifyListeners();
    return copy;
  }

  @override
  void deleteList(String listId) {
    _lists.removeWhere((list) => list.id == listId);
    notifyListeners();
  }

  @override
  void renameList(String listId, String title) {
    final listIndex = _lists.indexWhere((list) => list.id == listId);
    final trimmed = title.trim();
    if (listIndex == -1 || trimmed.isEmpty) return;

    _lists[listIndex] = _lists[listIndex].copyWith(
      title: trimmed,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  @override
  void updateTripSettings(
    String listId, {
    required int days,
    required Set<WeatherCondition> weatherConditions,
    bool? showWeight,
  }) {
    final listIndex = _lists.indexWhere((list) => list.id == listId);
    if (listIndex == -1 || weatherConditions.isEmpty) return;

    final list = _lists[listIndex];
    final nights = list.tripType == TripType.city
        ? 0
        : (days - 1).clamp(0, 30).toInt();
    final adjustedItems = _applyTripSettingsToItems(
      list.items,
      days: days,
      weatherConditions: weatherConditions,
      idPrefix: list.id,
    );
    _lists[listIndex] = list.copyWith(
      days: days,
      nights: nights,
      weatherConditions: weatherConditions,
      showWeight: showWeight ?? list.showWeight,
      items: adjustedItems,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  @override
  bool renameCategory(String listId, String currentName, String newName) {
    final listIndex = _lists.indexWhere((list) => list.id == listId);
    final trimmedName = newName.trim();
    if (listIndex == -1 || currentName == trimmedName || trimmedName.isEmpty) {
      return false;
    }

    final list = _lists[listIndex];
    if (list.items.any(
      (item) =>
          item.categoryName == trimmedName && item.categoryName != currentName,
    )) {
      return false;
    }
    if (!list.items.any((item) => item.categoryName == currentName)) {
      return false;
    }

    final items = list.items
        .map(
          (item) => item.categoryName == currentName
              ? item.copyWith(categoryName: trimmedName)
              : item,
        )
        .toList();
    _lists[listIndex] = list.copyWith(items: items, updatedAt: DateTime.now());
    notifyListeners();
    return true;
  }

  @override
  void reorderCategories(String listId, List<String> orderedCategoryNames) {
    final listIndex = _lists.indexWhere((list) => list.id == listId);
    if (listIndex == -1) return;

    final list = _lists[listIndex];
    final currentNames = <String>[];
    final sortedItems = [...list.items]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final item in sortedItems) {
      if (!currentNames.contains(item.categoryName)) {
        currentNames.add(item.categoryName);
      }
    }
    if (orderedCategoryNames.length != currentNames.length ||
        orderedCategoryNames.toSet().length != currentNames.length ||
        !orderedCategoryNames.toSet().containsAll(currentNames)) {
      return;
    }

    final items = <PackItem>[];
    for (final categoryName in orderedCategoryNames) {
      items.addAll(
        sortedItems.where((item) => item.categoryName == categoryName),
      );
    }
    _lists[listIndex] = list.copyWith(
      items: [
        for (var index = 0; index < items.length; index += 1)
          items[index].copyWith(sortOrder: index),
      ],
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  @override
  void toggleItem(String listId, String itemId, bool checked) {
    final listIndex = _lists.indexWhere((list) => list.id == listId);
    if (listIndex == -1) return;

    final list = _lists[listIndex];
    final items = list.items
        .map(
          (item) => item.id == itemId ? item.copyWith(checked: checked) : item,
        )
        .toList();

    _lists[listIndex] = list.copyWith(items: items, updatedAt: DateTime.now());
    notifyListeners();
  }

  @override
  void upsertItem(String listId, PackItem item) {
    if (_upsertItem(listId, item)) notifyListeners();
  }

  @override
  void upsertItems(String listId, List<PackItem> items) {
    var changed = false;
    for (final item in items) {
      changed = _upsertItem(listId, item) || changed;
    }
    if (changed) notifyListeners();
  }

  bool _upsertItem(String listId, PackItem item) {
    final listIndex = _lists.indexWhere((list) => list.id == listId);
    if (listIndex == -1) return false;

    final list = _lists[listIndex];
    final itemIndex = list.items.indexWhere((current) => current.id == item.id);
    final items = [...list.items];
    if (itemIndex == -1) {
      items.add(
        _normalizeItemForList(list, item).copyWith(sortOrder: items.length),
      );
    } else {
      final normalizedItem = _normalizeItemForList(list, item);
      items[itemIndex] = normalizedItem;
      if (!normalizedItem.isContainer) {
        for (var index = 0; index < items.length; index += 1) {
          if (items[index].containerItemId == normalizedItem.id) {
            items[index] = items[index].copyWith(containerItemId: null);
          }
        }
      }
    }

    _lists[listIndex] = list.copyWith(items: items, updatedAt: DateTime.now());
    return true;
  }

  @override
  void deleteItem(String listId, String itemId) {
    final listIndex = _lists.indexWhere((list) => list.id == listId);
    if (listIndex == -1) return;

    final list = _lists[listIndex];
    final itemIndex = list.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;
    final item = list.items[itemIndex];

    if (item.isContainer && _containerItems(list).length <= 1) return;

    final remainingContainers = _containerItems(
      list,
    ).where((container) => container.id != itemId).toList();
    final primaryContainer = remainingContainers
        .where(
          (container) =>
              container.categoryId == 'backpack' ||
              container.name.contains('主背包'),
        )
        .firstOrNull;
    final destinationContainerId = remainingContainers.isEmpty
        ? null
        : (primaryContainer ?? remainingContainers.first).id;
    final items = list.items
        .where((item) => item.id != itemId)
        .map(
          (current) => current.containerItemId == itemId
              ? current.copyWith(containerItemId: destinationContainerId)
              : current,
        )
        .toList();
    _lists[listIndex] = list.copyWith(items: items, updatedAt: DateTime.now());
    notifyListeners();
  }

  @override
  void reorderItems(String listId, List<PackItem> reorderedItems) {
    if (reorderedItems.isEmpty) return;

    final listIndex = _lists.indexWhere((list) => list.id == listId);
    if (listIndex == -1) return;

    final list = _lists[listIndex];
    final firstOrder = reorderedItems
        .map((item) => item.sortOrder)
        .reduce((a, b) => a < b ? a : b);
    final reorderedById = <String, PackItem>{};
    for (var index = 0; index < reorderedItems.length; index += 1) {
      final item = reorderedItems[index];
      reorderedById[item.id] = item.copyWith(sortOrder: firstOrder + index);
    }

    final items =
        list.items.map((item) => reorderedById[item.id] ?? item).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    _lists[listIndex] = list.copyWith(
      items: [
        for (var index = 0; index < items.length; index += 1)
          items[index].copyWith(sortOrder: index),
      ],
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  @override
  List<PackItem> previewItemsForDraft({
    required PackTemplate template,
    required int days,
    required Set<WeatherCondition> weatherConditions,
  }) {
    return List.unmodifiable(
      _itemsFor(
        template: template,
        days: days,
        weatherConditions: weatherConditions,
        idPrefix: 'draft-preview',
      ),
    );
  }

  List<PackItem> _itemsFor({
    required PackTemplate template,
    required int days,
    required Set<WeatherCondition> weatherConditions,
    required String idPrefix,
    Set<String>? selectedItemKeys,
  }) {
    final base = SeedData.itemsForTemplate(template);

    final items = base.map((item) {
      final sourceContainerItemId = item.containerItemId;
      final quantity = switch (item.categoryId) {
        'clothes' when item.necessity == ItemNecessity.required => days,
        'food' when item.necessity == ItemNecessity.required => days * 2,
        _ => item.quantity,
      };
      return item.copyWith(
        id: '$idPrefix-${item.id}',
        quantity: quantity,
        checked: false,
        containerItemId: sourceContainerItemId == null
            ? null
            : '$idPrefix-$sourceContainerItemId',
      );
    }).toList();

    final configuredItems = _applyTripSettingsToItems(
      items,
      days: days,
      weatherConditions: weatherConditions,
      idPrefix: idPrefix,
    );
    if (selectedItemKeys == null) return configuredItems;

    final selectedItems = configuredItems
        .where((item) => selectedItemKeys.contains(packItemSelectionKey(item)))
        .toList();
    final selectedIds = selectedItems.map((item) => item.id).toSet();
    return selectedItems.map((item) {
      final containerItemId = item.containerItemId;
      if (containerItemId == null || selectedIds.contains(containerItemId)) {
        return item;
      }
      return item.copyWith(containerItemId: null);
    }).toList();
  }

  List<PackItem> _applyTripSettingsToItems(
    List<PackItem> sourceItems, {
    required int days,
    required Set<WeatherCondition> weatherConditions,
    required String idPrefix,
  }) {
    final selectedWeatherIds = _weatherItems(
      weatherConditions,
    ).map((item) => item.id).toSet();
    final allWeatherIds = _weatherItems(
      WeatherCondition.values.toSet(),
    ).map((item) => item.id).toSet();
    final items = sourceItems
        .where((item) {
          if (!item.id.startsWith('$idPrefix-')) return true;
          final sourceId = item.id.substring(idPrefix.length + 1);
          if (!allWeatherIds.contains(sourceId)) return true;
          return selectedWeatherIds.contains(sourceId);
        })
        .map((item) {
          final quantity = switch (item.categoryId) {
            'clothes' when item.necessity == ItemNecessity.required => days,
            'food' when item.necessity == ItemNecessity.required => days * 2,
            _ => item.quantity,
          };
          return item.copyWith(quantity: quantity);
        })
        .toList();

    for (final weatherItem in _weatherItems(weatherConditions)) {
      if (_hasEquivalentWeatherItem(items, weatherItem)) continue;
      items.add(
        weatherItem.copyWith(
          id: '$idPrefix-${weatherItem.id}',
          sortOrder: items.length,
          containerItemId: _defaultContainerId(items),
        ),
      );
    }
    return items;
  }

  bool _hasEquivalentWeatherItem(List<PackItem> items, PackItem weatherItem) {
    final aliases = switch (weatherItem.id) {
      'rain-cover' => const {'背包套', '防雨衣物'},
      'wind-shell' => const {'防風外套'},
      'fleece' => const {'保暖外套', '中層背心'},
      'sun-protection' => const {'防曬油'},
      _ => const <String>{},
    };
    return items.any(
      (item) => item.name == weatherItem.name || aliases.contains(item.name),
    );
  }

  PackItem _normalizeItemForList(PackList list, PackItem item) {
    final existingItemIndex = list.items.indexWhere(
      (current) => current.id == item.id,
    );
    if (existingItemIndex != -1) {
      final existingItem = list.items[existingItemIndex];
      if (existingItem.isContainer &&
          !item.isContainer &&
          _containerItems(list).length <= 1) {
        return item.copyWith(
          weightClass: WeightClass.packed,
          isContainer: true,
          containerItemId: null,
        );
      }
    }
    if (item.weightClass != WeightClass.packed) {
      return item.copyWith(isContainer: false, containerItemId: null);
    }
    if (item.isContainer) {
      return item.copyWith(
        weightClass: WeightClass.packed,
        containerItemId: null,
      );
    }
    final containerExists = list.items.any(
      (current) => current.id == item.containerItemId && current.isContainer,
    );
    return containerExists ? item : item.copyWith(containerItemId: null);
  }

  List<PackItem> _containerItems(PackList list) {
    return list.items.where((item) => item.isContainer).toList();
  }

  String? _defaultContainerId(List<PackItem> items) {
    for (final item in items) {
      if (item.isContainer) return item.id;
    }
    return null;
  }

  List<PackItem> _weatherItems(Set<WeatherCondition> weatherConditions) {
    return [
      if (weatherConditions.contains(WeatherCondition.rainy))
        const PackItem(
          id: 'rain-cover',
          categoryId: 'weather',
          categoryName: '天氣裝備',
          name: '背包防雨套',
          weightGram: 120,
          quantity: 1,
          checked: false,
          necessity: ItemNecessity.required,
          sortOrder: 0,
        ),
      if (weatherConditions.contains(WeatherCondition.cloudy))
        const PackItem(
          id: 'wind-shell',
          categoryId: 'weather',
          categoryName: '天氣裝備',
          name: '防風外套',
          weightGram: 260,
          quantity: 1,
          checked: false,
          necessity: ItemNecessity.optional,
          sortOrder: 0,
        ),
      if (weatherConditions.contains(WeatherCondition.cold))
        const PackItem(
          id: 'fleece',
          categoryId: 'weather',
          categoryName: '天氣裝備',
          name: '保暖中層',
          weightGram: 380,
          quantity: 1,
          checked: false,
          necessity: ItemNecessity.required,
          sortOrder: 0,
        ),
      if (weatherConditions.contains(WeatherCondition.sunny))
        const PackItem(
          id: 'sun-protection',
          categoryId: 'weather',
          categoryName: '天氣裝備',
          name: '防曬用品',
          weightGram: 90,
          quantity: 1,
          checked: false,
          necessity: ItemNecessity.optional,
          sortOrder: 0,
        ),
    ];
  }
}
