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
  });

  final Set<WeatherCondition> selected;
  final ValueChanged<Set<WeatherCondition>> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WeatherCondition.values.map((weather) {
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
          label: Text(TripFormatters.weather(weather)),
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
      }).toList(),
    );
  }
}
