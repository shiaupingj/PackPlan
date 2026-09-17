import '../models/user_settings.dart';

abstract final class WeightFormatters {
  static const _nbsp = '\u00A0';

  static String gram(int gram, {WeightUnit unit = WeightUnit.kg}) {
    if (unit == WeightUnit.gram) return '$gram${_nbsp}g';
    if (gram >= 1000) return '${(gram / 1000).toStringAsFixed(1)}${_nbsp}kg';
    return '$gram${_nbsp}g';
  }

  static String signedGram(int gram, {WeightUnit unit = WeightUnit.kg}) {
    final prefix = gram > 0 ? '+' : '';
    return '$prefix${WeightFormatters.gram(gram, unit: unit)}';
  }
}
