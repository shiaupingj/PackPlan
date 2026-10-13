import 'package:flutter/material.dart';

import '../models/pack_list.dart';
import '../services/trip_formatters.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// 天氣多選 chip。建立清單 Step 2 與清單內頁「旅程設定」共用。
///
/// 選取只用顏色區分、不打勾(與 Step 3 項目選擇一致):選中橘底 ink 字,
/// 未選 surface 底 + border 細框。至少保留一個天氣,最後一個無法取消。
class WeatherChoiceChips extends StatelessWidget {
  const WeatherChoiceChips({
    super.key,
    required this.selected,
    required this.onChanged,
    this.singleRow = false,
  });

  final Set<WeatherCondition> selected;
  final ValueChanged<Set<WeatherCondition>> onChanged;

  /// 全部選項排成一行、平分寬度(對話框較窄時使用),否則自動換行。
  final bool singleRow;

  static const _spacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final chips = WeatherCondition.values.map(
      (weather) => _chip(context, weather),
    );
    if (!singleRow) {
      return Wrap(
        spacing: _spacing,
        runSpacing: _spacing,
        children: chips.toList(),
      );
    }
    return Row(
      children: [
        for (final (i, chip) in chips.indexed) ...[
          if (i > 0) const SizedBox(width: _spacing),
          Expanded(child: chip),
        ],
      ],
    );
  }

  Widget _chip(BuildContext context, WeatherCondition weather) {
    final palette = context.palette;
    final isSelected = selected.contains(weather);
    return FilterChip(
      key: ValueKey('weather-chip-${weather.name}'),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: palette.surface,
      side: BorderSide(
        color: isSelected ? AppColors.primary : palette.border,
        width: 0.8,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.ink : palette.textPrimary,
      ),
      // 一行排列時縮小左右留白,窄螢幕也放得下四個。
      padding: singleRow ? const EdgeInsets.symmetric(vertical: 4) : null,
      labelPadding: singleRow ? EdgeInsets.zero : null,
      label: singleRow
          ? Center(child: Text(TripFormatters.weather(weather), maxLines: 1))
          : Text(TripFormatters.weather(weather)),
      onSelected: (value) {
        final next = {...selected};
        if (value) {
          next.add(weather);
        } else if (next.length > 1) {
          next.remove(weather);
        }
        onChanged(next);
      },
    );
  }
}
