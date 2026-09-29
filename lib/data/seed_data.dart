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
      proOnly: false, // 暫時解鎖以便測試進階登山候選清單
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
      return _buildFromGroups(
        _basicHikeGroups,
        defaultContainerId: 'large-backpack',
      );
    }
    if (template.id == 'city-travel') {
      return _buildFromGroups(
        _cityTravelGroups,
        defaultContainerId: 'carry-on',
      );
    }
    if (template.id == 'advanced-hike') {
      // 進階登山 = 基礎登山全部項目（繼承）+ 進階/技術裝備。
      return _buildFromGroups([
        ..._basicHikeGroups,
        _advancedHikeExtras,
      ], defaultContainerId: 'large-backpack');
    }

    final seededLists = lists();
    return switch (template.tripType) {
      TripType.hiking => seededLists.first.items,
      TripType.city => seededLists.last.items,
      TripType.camping => seededLists.first.items,
    };
  }

  /// 把分類群組展開成候選 [PackItem]（重量先給 0，實際建立清單時再填）。
  /// 非容器項目預設歸屬到 [defaultContainerId] 這個容器。
  static List<PackItem> _buildFromGroups(
    List<_TemplateItemGroup> groups, {
    required String defaultContainerId,
  }) {
    final items = <PackItem>[];
    var sortOrder = 0;
    for (final group in groups) {
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
            containerItemId: spec.isContainer ? null : defaultContainerId,
            weightSource: WeightSource.unset,
            catalogKey: spec.id,
          ),
        );
        sortOrder += 1;
      }
    }
    return items;
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
        _TemplateItemSpec(id: 'small-backpack', name: '小背包', isContainer: true),
        _TemplateItemSpec(id: 'dry-bag', name: '防水袋', isContainer: true),
      ],
    ),
    _TemplateItemGroup(
      id: 'sleep',
      name: '睡眠系統',
      items: [
        _TemplateItemSpec(id: 'sleeping-bag', name: '睡袋'),
        _TemplateItemSpec(id: 'sleeping-pad', name: '睡墊'),
        _TemplateItemSpec(id: 'tent', name: '帳篷'),
      ],
    ),
    _TemplateItemGroup(
      id: 'clothes',
      name: '衣物用品',
      items: [
        _TemplateItemSpec(id: 'raincoat', name: '雨衣'),
        _TemplateItemSpec(id: 'rain-pants', name: '雨褲'),
        _TemplateItemSpec(id: 'base-layer', name: '排汗底層衣'),
        _TemplateItemSpec(id: 'warm-jacket', name: '外套'),
        _TemplateItemSpec(id: 'windbreaker', name: '防風外套'),
        _TemplateItemSpec(id: 'midlayer-vest', name: '中層背心'),
        _TemplateItemSpec(id: 'spare-clothes', name: '備用衣物'),
        _TemplateItemSpec(
          id: 'change-of-clothes',
          name: '換洗衣物',
          necessity: ItemNecessity.required,
        ),
        _TemplateItemSpec(id: 'hiking-socks', name: '襪子/備用羊毛襪'),
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
      name: '食物',
      items: [
        _TemplateItemSpec(id: 'toast', name: '吐司'),
        _TemplateItemSpec(id: 'instant-noodles', name: '泡麵'),
        _TemplateItemSpec(id: 'apple', name: '蘋果'),
        _TemplateItemSpec(id: 'pineapple-cake', name: '鳳梨穌'),
        _TemplateItemSpec(id: 'energy-drink', name: '能量飲'),
        _TemplateItemSpec(id: 'salt-candy', name: '鹽糖', quantity: 2),
        _TemplateItemSpec(id: 'chocolate', name: '巧克力'),
        _TemplateItemSpec(id: 'banana', name: '香蕉'),
        _TemplateItemSpec(id: 'instant-drink', name: '沖泡飲'),
      ],
    ),
    _TemplateItemGroup(
      id: 'tableware',
      name: '餐具',
      items: [
        _TemplateItemSpec(id: 'utensils', name: '碗筷湯匙'),
        _TemplateItemSpec(id: 'cup', name: '杯子'),
      ],
    ),
    _TemplateItemGroup(
      id: 'water-container',
      name: '裝水容器',
      items: [
        _TemplateItemSpec(
          id: 'water-bottle',
          name: '水瓶',
          necessity: ItemNecessity.required,
        ),
        _TemplateItemSpec(id: 'thermos', name: '保溫瓶'),
      ],
    ),
    _TemplateItemGroup(
      id: 'cooking',
      name: '炊事',
      items: [
        _TemplateItemSpec(id: 'stove', name: '爐頭'),
        _TemplateItemSpec(id: 'gas-canister', name: '瓦斯罐'),
        _TemplateItemSpec(id: 'cookware', name: '鍋具/鈦杯'),
        _TemplateItemSpec(id: 'windscreen', name: '擋風板'),
      ],
    ),
    _TemplateItemGroup(
      id: 'hiking-tools',
      name: '用具',
      items: [
        _TemplateItemSpec(id: 'pack-cover', name: '背包套'),
        _TemplateItemSpec(
          id: 'headlamp',
          name: '頭燈',
          necessity: ItemNecessity.required,
        ),
        _TemplateItemSpec(id: 'headlamp-batteries', name: '頭燈用電池'),
        _TemplateItemSpec(id: 'gloves', name: '手套'),
        _TemplateItemSpec(id: 'trekking-poles', name: '登山杖'),
        _TemplateItemSpec(id: 'gaiters', name: '綁腿'),
        _TemplateItemSpec(id: 'knee-pads', name: '護膝'),
        _TemplateItemSpec(
          id: 'lighter',
          name: '打火機',
          necessity: ItemNecessity.required,
        ),
      ],
    ),
    _TemplateItemGroup(
      id: 'safety',
      name: '安全導航',
      items: [
        _TemplateItemSpec(id: 'phone', name: '手機'),
        _TemplateItemSpec(id: 'whistle', name: '哨子'),
        _TemplateItemSpec(id: 'emergency-blanket', name: '緊急保暖毯'),
        _TemplateItemSpec(id: 'first-aid-kit', name: '急救包'),
        _TemplateItemSpec(id: 'sunglasses', name: '太陽眼鏡'),
      ],
    ),
    _TemplateItemGroup(
      id: 'personal',
      name: '個人物品',
      items: [
        _TemplateItemSpec(id: 'toiletries', name: '盥洗用具'),
        _TemplateItemSpec(id: 'umbrella', name: '雨傘'),
        _TemplateItemSpec(
          id: 'tissue',
          name: '衛生紙',
          necessity: ItemNecessity.required,
        ),
        _TemplateItemSpec(id: 'wet-wipes', name: '溼紙巾'),
        _TemplateItemSpec(id: 'sunscreen', name: '防曬油'),
        _TemplateItemSpec(id: 'lip-balm', name: '護唇膏'),
        _TemplateItemSpec(
          id: 'personal-medicine',
          name: '個人醫藥',
          necessity: ItemNecessity.required,
        ),
        _TemplateItemSpec(id: 'trash-bags', name: '垃圾袋'),
        _TemplateItemSpec(
          id: 'documents',
          name: '證件',
          necessity: ItemNecessity.required,
        ),
        _TemplateItemSpec(id: 'cash', name: '現金/零錢'),
        _TemplateItemSpec(id: 'power-bank', name: '行動電源'),
        _TemplateItemSpec(id: 'cat-litter-scoop', name: '貓鏟'),
      ],
    ),
  ];

  // 進階登山在基礎登山之上額外疊加的技術 / 高地裝備。
  static const _advancedHikeExtras = _TemplateItemGroup(
    id: 'advanced-gear',
    name: '進階裝備',
    items: [
      _TemplateItemSpec(id: 'helmet', name: '頭盔'),
      _TemplateItemSpec(id: 'bivy-bag', name: '露宿袋'),
      _TemplateItemSpec(id: 'crampons', name: '冰爪'),
      _TemplateItemSpec(id: 'rope', name: '繩索'),
      _TemplateItemSpec(id: 'harness', name: '吊帶'),
      _TemplateItemSpec(id: 'belay-device', name: '確保/下降器'),
      _TemplateItemSpec(id: 'gps-communicator', name: '衛星通訊器'),
      _TemplateItemSpec(id: 'alpine-gloves', name: '高地手套'),
      _TemplateItemSpec(id: 'snow-gaiters', name: '雪地綁腿'),
      _TemplateItemSpec(id: 'balaclava', name: '面罩頭巾'),
    ],
  );

  // 城市旅遊完整候選清單（比照基礎登山的廣度，改用城市旅行情境分類）。
  static const _cityTravelGroups = [
    _TemplateItemGroup(
      id: 'luggage',
      name: '行李',
      items: [
        _TemplateItemSpec(
          id: 'carry-on',
          name: '登機箱',
          necessity: ItemNecessity.required,
          isContainer: true,
        ),
        _TemplateItemSpec(
          id: 'personal-bag',
          name: '隨身包',
          necessity: ItemNecessity.required,
          isContainer: true,
        ),
        _TemplateItemSpec(
          id: 'checked-luggage',
          name: '託運行李箱',
          isContainer: true,
        ),
        _TemplateItemSpec(id: 'daypack', name: '後背包'),
      ],
    ),
    _TemplateItemGroup(
      id: 'worn',
      name: '身上穿戴',
      items: [
        _TemplateItemSpec(
          id: 'city-worn-set',
          name: '身上一套',
          weightClass: WeightClass.worn,
        ),
        _TemplateItemSpec(
          id: 'city-shoes',
          name: '鞋子',
          weightClass: WeightClass.worn,
        ),
      ],
    ),
    _TemplateItemGroup(
      id: 'clothes',
      name: '衣物',
      items: [
        _TemplateItemSpec(
          id: 'city-top',
          name: '上衣',
          necessity: ItemNecessity.required,
        ),
        _TemplateItemSpec(
          id: 'city-pants',
          name: '褲子',
          necessity: ItemNecessity.required,
        ),
        _TemplateItemSpec(id: 'city-jacket', name: '外套'),
        _TemplateItemSpec(
          id: 'underwear',
          name: '內衣褲',
          necessity: ItemNecessity.required,
        ),
        _TemplateItemSpec(id: 'socks', name: '襪子'),
        _TemplateItemSpec(id: 'pajamas', name: '睡衣'),
        _TemplateItemSpec(id: 'formal-wear', name: '正式服裝'),
        _TemplateItemSpec(id: 'accessories', name: '圍巾配件'),
      ],
    ),
    _TemplateItemGroup(
      id: 'toiletries',
      name: '盥洗保養',
      items: [
        _TemplateItemSpec(id: 'toothbrush', name: '牙刷牙膏'),
        _TemplateItemSpec(id: 'facial-cleanser', name: '洗面乳'),
        _TemplateItemSpec(id: 'skincare', name: '保養品'),
        _TemplateItemSpec(id: 'makeup', name: '化妝品'),
        _TemplateItemSpec(id: 'razor', name: '刮鬍刀'),
        _TemplateItemSpec(id: 'comb', name: '梳子'),
        _TemplateItemSpec(id: 'towel', name: '毛巾'),
        _TemplateItemSpec(id: 'eyewear', name: '隱形眼鏡/眼鏡'),
      ],
    ),
    _TemplateItemGroup(
      id: 'electronics',
      name: '3C 電子',
      items: [
        _TemplateItemSpec(id: 'phone', name: '手機'),
        _TemplateItemSpec(
          id: 'city-charger',
          name: '充電器',
          necessity: ItemNecessity.required,
        ),
        _TemplateItemSpec(id: 'city-power-bank', name: '行動電源'),
        _TemplateItemSpec(id: 'travel-adapter', name: '萬國轉接頭'),
        _TemplateItemSpec(id: 'earphones', name: '耳機'),
        _TemplateItemSpec(id: 'camera', name: '相機'),
      ],
    ),
    _TemplateItemGroup(
      id: 'documents',
      name: '證件財物',
      items: [
        _TemplateItemSpec(
          id: 'passport',
          name: '護照/證件',
          necessity: ItemNecessity.required,
        ),
        _TemplateItemSpec(
          id: 'tickets',
          name: '機票/車票',
          necessity: ItemNecessity.required,
        ),
        _TemplateItemSpec(id: 'booking-info', name: '訂房資料'),
        _TemplateItemSpec(
          id: 'cash',
          name: '現金',
          necessity: ItemNecessity.required,
        ),
        _TemplateItemSpec(id: 'credit-card', name: '信用卡'),
        _TemplateItemSpec(id: 'travel-insurance', name: '旅遊保險'),
      ],
    ),
    _TemplateItemGroup(
      id: 'personal',
      name: '個人物品',
      items: [
        _TemplateItemSpec(id: 'city-umbrella', name: '雨傘'),
        _TemplateItemSpec(id: 'city-medicine', name: '常備藥'),
        _TemplateItemSpec(id: 'mask', name: '口罩'),
        _TemplateItemSpec(id: 'city-tissue', name: '衛生紙/濕紙巾'),
        _TemplateItemSpec(id: 'shopping-bag', name: '環保購物袋'),
        _TemplateItemSpec(id: 'sunglasses', name: '太陽眼鏡'),
        _TemplateItemSpec(id: 'city-water-bottle', name: '水瓶'),
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
