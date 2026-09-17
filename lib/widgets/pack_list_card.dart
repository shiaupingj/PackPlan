import 'package:flutter/material.dart';

import '../models/user_settings.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';
import 'weight_text.dart';

/// 首頁清單卡：標題 + 基重 + 進度條。
class PackListCard extends StatelessWidget {
  const PackListCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.weightGram,
    required this.weightUnit,
    required this.progress, // 0.0 ~ 1.0
    this.showWeight = true,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String subtitle;
  final int weightGram;
  final WeightUnit weightUnit;
  final double progress;
  final bool showWeight;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: t.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              if (showWeight) ...[
                WeightText(
                  gram: weightGram,
                  unit: weightUnit,
                  prefix: '基重 ',
                  style: t.headlineMedium?.copyWith(
                    fontSize: 15,
                    height: 1.42,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: context.palette.trackMuted,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('進度 ${(progress * 100).round()}%', style: t.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
