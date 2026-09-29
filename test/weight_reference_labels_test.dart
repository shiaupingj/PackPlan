import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/models/gear_weight.dart';
import 'package:packplan/models/user_settings.dart';
import 'package:packplan/widgets/weight_reference_sheets.dart';

GearWeight _w(String name, {String? brand, int? min, int? max}) => GearWeight(
  key: name,
  nameZh: name,
  brand: brand,
  weightGram: min ?? 100,
  weightMin: min,
  weightMax: max,
  updatedAt: DateTime.utc(2026, 9, 29),
);

void main() {
  test('modelName:去掉開頭重複的品牌名,不分大小寫', () {
    String name(String n, String? brand) =>
        WeightReferenceLabels.modelName(_w(n, brand: brand));

    expect(name('ISUKA Air 1000EX', 'ISUKA'), 'Air 1000EX');
    expect(
      name('Snow Peak 防撥水透氣輕量睡袋 1°C BDD-021', 'Snow Peak'),
      '防撥水透氣輕量睡袋 1°C BDD-021',
    );
    expect(name('Norrøna falketind down800', 'Norrøna'), 'falketind down800');
    expect(name('deuter Futura Pro 40', 'deuter'), 'Futura Pro 40');
    expect(
      name('mont-bell Down Hugger 650 #3', 'mont-bell'),
      'Down Hugger 650 #3',
    );
    // 名稱不是以品牌開頭、沒有品牌、或整個名稱就是品牌時保留原名
    expect(name('Nalgene 寬口瓶 1L', 'Camelbak'), 'Nalgene 寬口瓶 1L');
    expect(name('蛋殼睡墊', null), '蛋殼睡墊');
    expect(name('Rhino', 'Rhino'), 'Rhino');
  });

  test('range:兩端換算後相同時不顯示範圍', () {
    expect(
      WeightReferenceLabels.range(_w('a', min: 1850, max: 1890), WeightUnit.kg),
      '',
    );
    expect(
      WeightReferenceLabels.range(
        _w('a', min: 1850, max: 1890),
        WeightUnit.gram,
      ),
      isNotEmpty,
    );
    expect(
      WeightReferenceLabels.tooltip(
        _w('a', min: 1850, max: 1890),
        WeightUnit.kg,
      ),
      '線上參考值',
    );
  });
}
