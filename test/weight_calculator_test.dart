import 'package:flutter_test/flutter_test.dart';
import 'package:packplan/data/seed_data.dart';
import 'package:packplan/models/pack_item.dart';
import 'package:packplan/services/weight_calculator.dart';

void main() {
  test('summarize calculates total weight and progress', () {
    final list = SeedData.lists().first;

    final summary = WeightCalculator.summarize(list);

    expect(summary.totalGram, 4120);
    expect(summary.packedGram, 1700);
    expect(summary.checkedCount, 2);
    expect(summary.itemCount, 8);
    expect(summary.progress, 0.25);
  });

  test('suggestions prioritize optional and luxury heavy items', () {
    final list = SeedData.lists().first;

    final suggestions = WeightCalculator.suggestions(list);

    expect(suggestions.first.itemName, '備用鞋');
    expect(suggestions.first.weightGram, 800);
  });

  test('minimum viable weight only includes required items', () {
    final list = SeedData.lists().first;

    final minimumWeight = WeightCalculator.minimumViableWeightGram(list);

    expect(minimumWeight, 3020);
  });

  test('worn weight is separated from pack and base weight', () {
    final source = SeedData.lists().first;
    final list = source.copyWith(
      items: source.items.map((item) {
        if (item.id == 'shirt') {
          return item.copyWith(weightClass: WeightClass.worn);
        }
        return item;
      }).toList(),
    );

    final summary = WeightCalculator.summarize(list);

    expect(summary.totalGram, 3580);
    expect(summary.baseGram, 3580);
    expect(summary.wornGram, 540);
    expect(list.skinOutWeightGram, 4120);
  });

  test('reduction suggestions exclude worn items', () {
    final source = SeedData.lists().first;
    final list = source.copyWith(
      items: source.items.map((item) {
        if (item.id == 'backup-shoes') {
          return item.copyWith(weightClass: WeightClass.worn);
        }
        return item;
      }).toList(),
    );

    final suggestions = WeightCalculator.suggestions(list);

    expect(suggestions.any((item) => item.itemName == '備用鞋'), isFalse);
  });
}
