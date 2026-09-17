import '../models/pack_item.dart';
import '../models/pack_list.dart';
import '../models/pack_template.dart';

abstract final class SeedData {
  static const templates = [
    PackTemplate(
      id: 'basic-hike',
      name: '基礎登山',
      tripType: TripType.hiking,
      proOnly: false,
      description: '3 天內健行與入門登山適用。',
    ),
    PackTemplate(
      id: 'city-travel',
      name: '城市旅遊',
      tripType: TripType.city,
      proOnly: false,
      description: '短天數城市旅行與商務出差。',
    ),
    PackTemplate(
      id: 'ul-camping',
      name: '極簡露營',
      tripType: TripType.camping,
      proOnly: true,
      description: '以低基重為核心的露營清單。',
    ),
    PackTemplate(
      id: 'advanced-hike',
      name: '進階登山',
      tripType: TripType.hiking,
      proOnly: true,
      description: '高海拔、長距離與進階裝備配置。',
    ),
    PackTemplate(
      id: 'long-trip',
      name: '長天數旅行',
      tripType: TripType.city,
      proOnly: true,
      description: '7 天以上旅行與多場景衣物安排。',
    ),
  ];

  static List<PackList> lists() {
    final now = DateTime.now();
    return [
      PackList(
        id: 'sample-hiking',
        title: '登山計劃',
        tripType: TripType.hiking,
        days: 3,
        nights: 2,
        weatherConditions: {WeatherCondition.rainy},
        weightLimitGram: 7000,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
        items: const [
          PackItem(
            id: 'pack',
            categoryId: 'backpack',
            categoryName: '背包系統',
            name: '主背包 45L',
            weightGram: 1200,
            quantity: 1,
            checked: true,
            necessity: ItemNecessity.required,
            sortOrder: 0,
            isContainer: true,
          ),
          PackItem(
            id: 'water-bottle',
            categoryId: 'hydration',
            categoryName: '飲水系統',
            name: '水壺',
            weightGram: 500,
            quantity: 1,
            checked: true,
            necessity: ItemNecessity.required,
            sortOrder: 1,
            containerItemId: 'pack',
          ),
          PackItem(
            id: 'headlamp',
            categoryId: 'tools',
            categoryName: '工具',
            name: '頭燈',
            weightGram: 100,
            quantity: 1,
            checked: false,
            necessity: ItemNecessity.required,
            sortOrder: 2,
            containerItemId: 'pack',
          ),
          PackItem(
            id: 'power-bank',
            categoryId: 'tools',
            categoryName: '工具',
            name: '行動電源',
            weightGram: 300,
            quantity: 1,
            checked: false,
            necessity: ItemNecessity.optional,
            sortOrder: 3,
            containerItemId: 'pack',
          ),
          PackItem(
            id: 'shirt',
            categoryId: 'clothes',
            categoryName: '衣物',
            name: '排汗上衣',
            weightGram: 180,
            quantity: 3,
            checked: false,
            necessity: ItemNecessity.required,
            sortOrder: 4,
            containerItemId: 'pack',
          ),
          PackItem(
            id: 'backup-shoes',
            categoryId: 'clothes',
            categoryName: '衣物',
            name: '備用鞋',
            weightGram: 800,
            quantity: 1,
            checked: false,
            necessity: ItemNecessity.luxury,
            sortOrder: 5,
            containerItemId: 'pack',
          ),
          PackItem(
            id: 'rain-jacket',
            categoryId: 'weather',
            categoryName: '天氣裝備',
            name: '雨衣',
            weightGram: 320,
            quantity: 1,
            checked: false,
            necessity: ItemNecessity.required,
            sortOrder: 6,
            containerItemId: 'pack',
          ),
          PackItem(
            id: 'energy-bar',
            categoryId: 'food',
            categoryName: '食物',
            name: '能量棒',
            weightGram: 60,
            quantity: 6,
            checked: false,
            necessity: ItemNecessity.required,
            sortOrder: 7,
            containerItemId: 'pack',
          ),
        ],
      ),
      PackList(
        id: 'sample-city',
        title: '城市旅遊',
        tripType: TripType.city,
        days: 5,
        nights: 4,
        weatherConditions: {WeatherCondition.sunny},
        weightLimitGram: 12000,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 1)),
        items: const [
          PackItem(
            id: 'carry-on',
            categoryId: 'luggage',
            categoryName: '行李',
            name: '登機箱',
            weightGram: 2600,
            quantity: 1,
            checked: true,
            necessity: ItemNecessity.required,
            sortOrder: 0,
            isContainer: true,
          ),
          PackItem(
            id: 'city-shirt',
            categoryId: 'clothes',
            categoryName: '衣物',
            name: '上衣',
            weightGram: 180,
            quantity: 5,
            checked: false,
            necessity: ItemNecessity.required,
            sortOrder: 1,
            containerItemId: 'carry-on',
          ),
          PackItem(
            id: 'charger',
            categoryId: 'tools',
            categoryName: '工具',
            name: '充電器',
            weightGram: 120,
            quantity: 1,
            checked: false,
            necessity: ItemNecessity.required,
            sortOrder: 2,
            containerItemId: 'carry-on',
          ),
        ],
      ),
    ];
  }

  static List<PackItem> itemsForTemplate(PackTemplate template) {
    if (template.id == 'basic-hike') {
      final items = <PackItem>[];
      var sortOrder = 0;
      for (final group in _basicHikeGroups) {
        for (final spec in group.items) {
          items.add(
            PackItem(
              id: spec.id,
              categoryId: group.id,
              categoryName: group.name,
              name: spec.name,
              weightGram: 0,
              quantity: spec.quantity,
              checked: false,
              necessity: spec.necessity,
              sortOrder: sortOrder,
              weightClass: spec.weightClass,
              isContainer: spec.isContainer,
              containerItemId: spec.isContainer ? null : 'large-backpack',
            ),
          );
          sortOrder += 1;
        }
      }
      return items;
    }

    final seededLists = lists();
    return switch (template.tripType) {
      TripType.hiking => seededLists.first.items,
      TripType.city => seededLists.last.items,
      TripType.camping => seededLists.first.items,
    };
  }

  static const _basicHikeGroups = [
    _TemplateItemGroup(
      id: 'backpack',
      name: '背包系統',
      items: [
        _TemplateItemSpec(
          id: 'large-backpack',
          name: '大背包',
          necessity: ItemNecessity.required,
          isContainer: true,
        ),
        _TemplateItemSpec(id: 'pack-cover', name: '背包套'),
        _TemplateItemSpec(id: 'small-backpack', name: '小背包', isContainer: true),
      ],
    ),
    _TemplateItemGroup(
      id: 'sleep',
      name: '睡眠系統',
      items: [
        _TemplateItemSpec(id: 'sleeping-bag', name: '睡袋'),
        _TemplateItemSpec(id: 'bivy-bag', name: '露宿袋'),
        _TemplateItemSpec(id: 'sleeping-pad', name: '睡墊'),
      ],
    ),
    _TemplateItemGroup(
      id: 'clothes',
      name: '衣物用品',
      items: [
        _TemplateItemSpec(id: 'rainwear', name: '防雨衣物'),
        _TemplateItemSpec(id: 'warm-jacket', name: '保暖外套'),
        _TemplateItemSpec(id: 'windbreaker', name: '防風外套'),
        _TemplateItemSpec(id: 'midlayer-vest', name: '中層背心'),
        _TemplateItemSpec(id: 'spare-clothes', name: '備用衣物'),
        _TemplateItemSpec(
          id: 'change-of-clothes',
          name: '換洗衣物',
          necessity: ItemNecessity.required,
        ),
        _TemplateItemSpec(id: 'hat', name: '帽子'),
        _TemplateItemSpec(id: 'beanie', name: '毛帽'),
        _TemplateItemSpec(id: 'buff', name: '頭巾'),
        _TemplateItemSpec(id: 'slippers', name: '拖鞋'),
      ],
    ),
    _TemplateItemGroup(
      id: 'worn',
      name: '身上穿戴',
      items: [
        _TemplateItemSpec(
          id: 'worn-set',
          name: '身上一套',
          weightClass: WeightClass.worn,
        ),
        _TemplateItemSpec(
          id: 'hiking-shoes',
          name: '登山鞋',
          weightClass: WeightClass.worn,
        ),
      ],
    ),
    _TemplateItemGroup(
      id: 'food',
      name: '食物+水',
      items: [
        _TemplateItemSpec(id: 'toast', name: '吐司'),
        _TemplateItemSpec(id: 'instant-noodles', name: '泡麵'),
        _TemplateItemSpec(id: 'apple', name: '蘋果'),
        _TemplateItemSpec(id: 'pineapple-cake', name: '鳳梨穌'),
        _TemplateItemSpec(id: 'energy-drink', name: '能量飲'),
        _TemplateItemSpec(id: 'salt-candy', name: '塩糖', quantity: 2),
        _TemplateItemSpec(id: 'chocolate', name: '巧克力'),
        _TemplateItemSpec(id: 'banana', name: '香蕉'),
        _TemplateItemSpec(id: 'instant-drink', name: '沖泡飲'),
      ],
    ),
    _TemplateItemGroup(
      id: 'dining-hydration',
      name: '餐具+飲水',
      items: [
        _TemplateItemSpec(id: 'helmet', name: '頭盔'),
        _TemplateItemSpec(id: 'water-bottle', name: '水瓶'),
        _TemplateItemSpec(id: 'thermos', name: '保溫瓶'),
      ],
    ),
    _TemplateItemGroup(
      id: 'hiking-tools',
      name: '登山用具',
      items: [
        _TemplateItemSpec(id: 'headlamp', name: '頭燈'),
        _TemplateItemSpec(id: 'headlamp-batteries', name: '頭燈用電池'),
        _TemplateItemSpec(id: 'gloves', name: '手套'),
        _TemplateItemSpec(id: 'trekking-poles', name: '登山杖'),
        _TemplateItemSpec(id: 'gaiters', name: '綁腿'),
        _TemplateItemSpec(id: 'knee-pads', name: '護膝'),
        _TemplateItemSpec(id: 'lighter', name: '打火機'),
      ],
    ),
    _TemplateItemGroup(
      id: 'personal',
      name: '個人物品',
      items: [
        _TemplateItemSpec(id: 'toiletries', name: '盥洗用具'),
        _TemplateItemSpec(id: 'umbrella', name: '雨傘'),
        _TemplateItemSpec(id: 'tissue', name: '衛生紙'),
        _TemplateItemSpec(id: 'wet-wipes', name: '溼紙巾'),
        _TemplateItemSpec(id: 'sunscreen', name: '防曬油'),
        _TemplateItemSpec(id: 'lip-balm', name: '護唇膏'),
        _TemplateItemSpec(id: 'personal-medicine', name: '個人醫藥'),
        _TemplateItemSpec(id: 'trash-bags', name: '垃圾袋'),
        _TemplateItemSpec(id: 'documents', name: '證件'),
        _TemplateItemSpec(id: 'power-bank', name: '行動電源'),
        _TemplateItemSpec(id: 'cat-litter-scoop', name: '貓鏟'),
      ],
    ),
  ];
}

class _TemplateItemGroup {
  const _TemplateItemGroup({
    required this.id,
    required this.name,
    required this.items,
  });

  final String id;
  final String name;
  final List<_TemplateItemSpec> items;
}

class _TemplateItemSpec {
  const _TemplateItemSpec({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.necessity = ItemNecessity.optional,
    this.weightClass = WeightClass.packed,
    this.isContainer = false,
  });

  final String id;
  final String name;
  final int quantity;
  final ItemNecessity necessity;
  final WeightClass weightClass;
  final bool isContainer;
}
