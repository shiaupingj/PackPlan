import '../models/user_settings.dart';

abstract final class WeightFormatters {
  static const _nbsp = '\u00A0';

  static String gram(int gram, {WeightUnit unit = WeightUnit.kg}) {
    if (unit == WeightUnit.gram) return '$gram${_nbsp}g';
    // kg 固定 2 位小數(1980 g → 1.98 kg),型號間幾十克的差距才看得出來。
    if (gram >= 1000) return '${(gram / 1000).toStringAsFixed(2)}${_nbsp}kg';
    return '$gram${_nbsp}g';
  }

  static String signedGram(int gram, {WeightUnit unit = WeightUnit.kg}) {
    final prefix = gram > 0 ? '+' : '';
    return '$prefix${WeightFormatters.gram(gram, unit: unit)}';
  }
}
