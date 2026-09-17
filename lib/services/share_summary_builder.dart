import '../models/pack_list.dart';
import '../models/user_settings.dart';
import 'formatters.dart';
import 'trip_formatters.dart';
import 'weight_calculator.dart';

abstract final class ShareSummaryBuilder {
  static String text(PackList list, {WeightUnit unit = WeightUnit.kg}) {
    final summary = WeightCalculator.summarize(list);
    final suggestions = WeightCalculator.suggestions(list, limit: 2);
    final buffer = StringBuffer()
      ..writeln('PackPlan ${list.title}')
      ..writeln(TripFormatters.summary(list));

    if (list.showWeight) {
      buffer
        ..writeln(
          '背包總重 ${WeightFormatters.gram(summary.totalGram, unit: unit)}',
        )
        ..writeln('上限 ${WeightFormatters.gram(summary.limitGram, unit: unit)}');
      if (summary.wornGram > 0) {
        buffer.writeln(
          '穿戴 ${WeightFormatters.gram(summary.wornGram, unit: unit)}'
          '（不計背重）',
        );
      }
    }
    buffer.writeln('進度 ${summary.checkedCount}/${summary.itemCount} 已打包');

    if (list.showWeight && summary.isOverLimit) {
      buffer.writeln(
        '超重 ${WeightFormatters.gram(summary.overByGram, unit: unit)}',
      );
    }

    if (list.showWeight && suggestions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('超輕量化打包建議');
      for (final suggestion in suggestions) {
        buffer.writeln(
          '- ${suggestion.itemName} ${WeightFormatters.gram(suggestion.weightGram, unit: unit)}',
        );
      }
    }

    return buffer.toString().trim();
  }
}
