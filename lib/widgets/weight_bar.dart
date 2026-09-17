import 'package:flutter/material.dart';

import '../models/user_settings.dart';
import '../services/formatters.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';

enum WeightStatus { ok, near, over }

/// 依「目前重量 / 上限」自動判定狀態並上色的重量條。
/// 規則：< 85% 正常、85%~100% 接近、> 100% 超重。
class WeightBar extends StatelessWidget {
  const WeightBar({
    super.key,
    required this.currentGram,
    required this.limitGram,
    this.unit = WeightUnit.kg,
    this.height = 10,
  });

  final int currentGram;
  final int limitGram;
  final WeightUnit unit;
  final double height;

  WeightStatus get status {
    if (limitGram <= 0) return WeightStatus.ok;
    final ratio = currentGram / limitGram;
    if (ratio > 1.0) return WeightStatus.over;
    if (ratio >= 0.85) return WeightStatus.near;
    return WeightStatus.ok;
  }

  Color _color(BuildContext context) => switch (status) {
    WeightStatus.ok => AppColors.weightOk,
    WeightStatus.near => context.palette.weightNear,
    WeightStatus.over => context.palette.weightOver,
  };

  @override
  Widget build(BuildContext context) {
    final ratio = limitGram <= 0
        ? 0.0
        : (currentGram / limitGram).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Stack(
            children: [
              Container(height: height, color: AppColors.trackMuted),
              FractionallySizedBox(
                widthFactor: ratio,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: height,
                  color: _color(context),
                ),
              ),
            ],
          ),
        ),
        if (status == WeightStatus.near) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '接近重量上限，剩餘 '
            '${WeightFormatters.gram(limitGram - currentGram, unit: unit)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.palette.weightNear),
          ),
        ] else if (status == WeightStatus.over) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '⚠️ 已超重 ${WeightFormatters.gram(currentGram - limitGram, unit: unit)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.palette.weightOver),
          ),
        ],
      ],
    );
  }
}
