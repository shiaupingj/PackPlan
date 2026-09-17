import '../models/pack_item.dart';
import '../models/pack_list.dart';

enum PackWeightTier { beginner, light, smart, ul, minimalist }

class WeightSummary {
  const WeightSummary({
    required this.totalGram,
    required this.baseGram,
    required this.wornGram,
    required this.packedGram,
    required this.limitGram,
    required this.checkedCount,
    required this.itemCount,
  });

  final int totalGram;
  final int baseGram;
  final int wornGram;
  final int packedGram;
  final int limitGram;
  final int checkedCount;
  final int itemCount;

  bool get isOverLimit => limitGram > 0 && packedGram > limitGram;

  int get overByGram => isOverLimit ? packedGram - limitGram : 0;

  double get progress => itemCount == 0 ? 0 : checkedCount / itemCount;

  double get totalKg => totalGram / 1000;
}

class WeightSuggestion {
  const WeightSuggestion({
    required this.itemName,
    required this.weightGram,
    required this.reason,
  });

  final String itemName;
  final int weightGram;
  final String reason;
}

abstract final class WeightCalculator {
  static WeightSummary summarize(PackList list) {
    return WeightSummary(
      totalGram: list.totalWeightGram,
      baseGram: list.baseWeightGram,
      wornGram: list.wornWeightGram,
      packedGram: list.packedWeightGram,
      limitGram: list.weightLimitGram,
      checkedCount: list.checkedCount,
      itemCount: list.items.length,
    );
  }

  static PackWeightTier tierForWeight(int gram) {
    if (gram < 4500) return PackWeightTier.minimalist;
    if (gram < 5500) return PackWeightTier.ul;
    if (gram < 7000) return PackWeightTier.smart;
    if (gram < 9000) return PackWeightTier.light;
    return PackWeightTier.beginner;
  }

  static List<WeightSuggestion> suggestions(PackList list, {int limit = 3}) {
    final candidates =
        list.items
            .where(
              (item) =>
                  item.weightClass == WeightClass.packed &&
                  item.necessity != ItemNecessity.required,
            )
            .toList()
          ..sort((a, b) => b.totalWeightGram.compareTo(a.totalWeightGram));

    return candidates.take(limit).map((item) {
      final reason = switch (item.necessity) {
        ItemNecessity.optional => '可先確認是否真的會用到',
        ItemNecessity.luxury => '享受型裝備，適合優先刪減',
        ItemNecessity.required => '必要裝備',
      };
      return WeightSuggestion(
        itemName: item.name,
        weightGram: item.totalWeightGram,
        reason: reason,
      );
    }).toList();
  }

  static int minimumViableWeightGram(PackList list) {
    return list.items
        .where(
          (item) =>
              item.weightClass == WeightClass.packed &&
              item.necessity == ItemNecessity.required,
        )
        .fold(0, (total, item) => total + item.totalWeightGram);
  }

  static PackItem? heaviestItem(PackList list) {
    final candidates = list.items
        .where((item) => item.weightClass != WeightClass.worn)
        .toList();
    if (candidates.isEmpty) return null;
    final sorted = [...candidates]
      ..sort((a, b) => b.totalWeightGram.compareTo(a.totalWeightGram));
    return sorted.first;
  }
}
