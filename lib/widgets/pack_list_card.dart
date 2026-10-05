import 'package:flutter/material.dart';

import '../models/user_settings.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';
import 'weight_text.dart';

/// 首頁清單卡(2 欄):標題列右上「⋯」+ 進度條，下方一行左「進度」右「總重」。
///
/// 標題與摘要都只佔一行，過長以「…」截斷，讓同一列的兩張卡等高。
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
    this.onMore,
  });

  final String title;
  final String subtitle;
  final int weightGram;
  final WeightUnit weightUnit;
  final double progress;
  final bool showWeight;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 右上「⋯」:開啟清單操作選單(與長按相同)。
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: t.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onMore != null)
                    IconButton(
                      tooltip: '清單操作',
                      onPressed: onMore,
                      visualDensity: VisualDensity.compact,
                      iconSize: 20,
                      color: context.palette.textSecondary,
                      icon: const Icon(Icons.more_horiz),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: t.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: context.palette.trackMuted,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // 半寬卡片很窄:總重放不下時等比縮小，不折行、不溢出。
                    Row(
                      children: [
                        Text(
                          '進度 ${(progress * 100).round()}%',
                          style: t.bodySmall,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (showWeight)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: WeightText(
                                  gram: weightGram,
                                  unit: weightUnit,
                                  prefix: '總重 ',
                                  style: t.bodySmall,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
